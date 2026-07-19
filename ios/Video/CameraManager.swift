import Foundation
import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @Published var permissionGranted = false
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let bufferQueue = DispatchQueue(label: "camera.buffer.queue", qos: .userInteractive)
    
    var onFrameCaptured: ((CVPixelBuffer) -> Void)?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission Checking
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            self.setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.permissionGranted = true
                        self.setupSession()
                    }
                }
            }
        default:
            self.permissionGranted = false
        }
    }
    
    // MARK: - Session Configuration
    
    private func setupSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            
            // Set preset for fast frame capture (640x480 is plenty since we downsample to 128x64)
            self.captureSession.sessionPreset = .vga640x480
            
            // Choose default back camera
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                print("Camera Error: Back camera not available.")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Add input
            if self.captureSession.canAddInput(videoDeviceInput) {
                self.captureSession.addInput(videoDeviceInput)
            }
            
            // Add output
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                
                // Configure output settings for YUV Bi-Planar format (Luminance Y plane is index 0)
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.bufferQueue)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    // MARK: - API Control
    
    func start() {
        sessionQueue.async {
            guard self.permissionGranted else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Camera Capture Session Started")
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("Camera Capture Session Stopped")
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Invoke callback
        onFrameCaptured?(pixelBuffer)
    }
}
