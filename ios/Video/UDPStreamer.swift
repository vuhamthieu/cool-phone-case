import Foundation
import Network
import VideoToolbox

class UDPStreamer: ObservableObject {
    
    private var connection: NWConnection?
    private let targetIP = "192.168.4.1"
    private let targetPort: UInt16 = 5001
    
    @Published var isStreaming = false
    
    init() {}
    
    func start() {
        let host = NWEndpoint.Host(targetIP)
        let port = NWEndpoint.Port(integerLiteral: targetPort)
        
        // Setup UDP Connection
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("UDP Streamer: Connected to \(self.targetIP):\(self.targetPort)")
                DispatchQueue.main.async { self.isStreaming = true }
            case .failed(let error):
                print("UDP Streamer Failed: \(error)")
                self.stop()
            case .cancelled:
                print("UDP Streamer: Connection cancelled")
                DispatchQueue.main.async { self.isStreaming = false }
            default:
                break
            }
        }
        
        connection?.start(queue: .global(qos: .userInteractive))
    }
    
    func stop() {
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async { self.isStreaming = false }
    }
    
    /// Processes a live YUV camera frame, downscales to 128x64 1-bit,
    /// applies Floyd-Steinberg dithering, and sends it via UDP.
    func streamFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isStreaming, let conn = connection else { return }
        
        // 1. Lock pixel buffer base address
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        // 2. Fetch the grayscale (Luminance) Plane 0
        guard let yBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        
        let srcWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let srcHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        let targetWidth = 128
        let targetHeight = 64
        
        // 3. Crop to center 2:1 aspect ratio and downsample
        var rawPixels = [Int16](repeating: 0, count: targetWidth * targetHeight)
        
        // Calculate crop bounds
        let cropWidth: Int
        let cropHeight: Int
        
        if srcWidth / 2 > srcHeight {
            cropWidth = srcHeight * 2
            cropHeight = srcHeight
        } else {
            cropWidth = srcWidth
            cropHeight = srcWidth / 2
        }
        
        let cropStartX = (srcWidth - cropWidth) / 2
        let cropStartY = (srcHeight - cropHeight) / 2
        
        // Downsample Y channel using nearest neighbor
        let yData = yBaseAddress.assumingMemoryBound(to: UInt8.self)
        for y in 0..<targetHeight {
            let srcY = cropStartY + (y * cropHeight) / targetHeight
            let rowOffset = srcY * bytesPerRow
            for x in 0..<targetWidth {
                let srcX = cropStartX + (x * cropWidth) / targetWidth
                let pixelVal = yData[rowOffset + srcX]
                rawPixels[y * targetWidth + x] = Int16(pixelVal)
            }
        }
        
        // 4. Floyd-Steinberg 1-Bit Dithering (XBM LSB-First byte packing)
        // 128x64 resolution = 8192 bits = 1024 bytes
        var ditheredFrame = [UInt8](repeating: 0, count: 1024)
        
        for y in 0..<targetHeight {
            for x in 0..<targetWidth {
                let index = y * targetWidth + x
                let oldPixel = rawPixels[index]
                
                // Thresholding at middle gray (128)
                let newPixel: Int16 = oldPixel < 128 ? 0 : 255
                
                // Pack into XBM format byte arrays (1 bit per pixel, horizontal, LSB first)
                if newPixel == 255 {
                    let byteIndex = y * 16 + (x / 8) // 16 bytes per row (128 / 8)
                    let bitIndex = x % 8
                    ditheredFrame[byteIndex] |= (1 << bitIndex)
                }
                
                // Calculate error
                let error = oldPixel - newPixel
                
                // Diffuse error to neighboring pixels in 128x64 buffer
                if x + 1 < targetWidth {
                    rawPixels[index + 1] += error * 7 / 16
                }
                if y + 1 < targetHeight {
                    let nextRowOffset = (y + 1) * targetWidth
                    if x > 0 {
                        rawPixels[nextRowOffset + x - 1] += error * 3 / 16
                    }
                    rawPixels[nextRowOffset + x] += error * 5 / 16
                    if x + 1 < targetWidth {
                        rawPixels[nextRowOffset + x + 1] += error * 1 / 16
                    }
                }
            }
        }
        
        // 5. Send packet over UDP
        let packetData = Data(ditheredFrame)
        conn.send(content: packetData, completion: .contentProcessed({ error in
            if let error = error {
                print("UDP stream send error: \(error)")
            }
        }))
    }
}
