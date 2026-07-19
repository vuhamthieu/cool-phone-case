// ios/Views/CameraStreamView.swift
import SwiftUI
import AVFoundation

struct CameraStreamView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var udpStreamer = UDPStreamer()
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Wi-Fi Connection Guidelines
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.white)
                        .font(.title3)
                    Text("WI-FI SETUP REQUIRED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Text("To stream video, connect your iPhone to the phone case AP:")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• SSID: MochiCase_AP")
                    Text("• PASSWORD: mochicase123")
                    Text("• CASE IP: 192.168.4.1 (PORT 5001)")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.white.opacity(0.08))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(14)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
            
            // Viewfinder and Stream Status
            VStack(spacing: 12) {
                HStack {
                    Text("LIVE VIEWFINDER (2:1 CROP)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(udpStreamer.isStreaming ? Color.white : Color.red)
                            .frame(width: 8, height: 8)
                        Text(udpStreamer.isStreaming ? "STREAMING" : "STOPPED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(udpStreamer.isStreaming ? .white : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .overlay(
                        Rectangle()
                            .stroke(udpStreamer.isStreaming ? Color.white : Color.red, lineWidth: 1)
                    )
                }
                
                if cameraManager.permissionGranted {
                    // Show live camera preview cropped to 2:1 aspect ratio (standard 128x64 shape)
                    CameraPreview(session: cameraManager.captureSession)
                        .aspectRatio(2.0, contentMode: .fit)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .shadow(radius: 10)
                } else {
                    // Fallback
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("CAMERA PERMISSION REQUIRED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.04))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Text("Use the Capacitive Touch Sensor on the phone case to cycle camera filters: Normal, Inverted, and Viewfinder Overlay.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
        }
        .onAppear {
            // Bind camera output buffer to the UDP streamer callback
            cameraManager.onFrameCaptured = { pixelBuffer in
                udpStreamer.streamFrame(pixelBuffer)
            }
            
            // Start services
            udpStreamer.start()
            cameraManager.start()
        }
        .onDisappear {
            // Tear down services
            cameraManager.stop()
            udpStreamer.stop()
        }
    }
}

// UIKit wrapper to render the live AVCaptureVideoPreviewLayer in SwiftUI
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .videoGravityResizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
