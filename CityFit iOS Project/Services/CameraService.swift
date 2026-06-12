import Foundation
import AVFoundation
import UIKit

/// AVFoundation camera session streaming frames for live Vision detection.
/// The camera is unavailable on the Simulator — `isAvailable` gates the UI.
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var isAuthorized = false

    #if targetEnvironment(simulator)
    let isAvailable = false
    #else
    let isAvailable = true
    #endif

    /// Called on every ~3rd frame with the camera pixel buffer.
    var frameHandler: ((CVPixelBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "cityfit.camera.session")
    private var latestFrame: CVPixelBuffer?
    private var frameCounter = 0

    func start() {
        guard isAvailable else { return }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async { self?.isAuthorized = granted }
            guard granted, let self else { return }
            self.sessionQueue.async {
                self.configureSession()
                self.session.startRunning()
            }
        }
    }

    func stop() {
        guard isAvailable else { return }
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    /// JPEG base64 of the most recent frame — sent to Groq Vision on "Snap".
    func snapBase64() -> String? {
        guard let frame = latestFrame else { return nil }
        let ciImage = CIImage(cvPixelBuffer: frame).oriented(.right)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let image = UIImage(cgImage: cgImage)
        return image.jpegData(compressionQuality: 0.6)?.base64EncodedString()
    }

    private func configureSession() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // small frames are plenty for classification

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestFrame = pixelBuffer
        frameCounter += 1
        if frameCounter % 3 == 0 { // throttle Vision work
            frameHandler?(pixelBuffer)
        }
    }
}
