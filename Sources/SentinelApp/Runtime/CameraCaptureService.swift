#if os(macOS)
import Foundation
import AVFoundation
import AppKit
import CoreGraphics
import SentinelCore

struct CapturedFrame: Sendable {
    let data: Data
    let width: Int
    let height: Int
}

enum CameraCaptureError: LocalizedError {
    case permissionDenied
    case noCamera
    case cannotAddInput
    case cannotAddOutput
    case captureAlreadyInProgress
    case captureFailed
    case imageDecodeFailed
    case imageEncodeFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Camera permission is not granted."
        case .noCamera: return "No camera is available."
        case .cannotAddInput: return "Sentinel could not open the camera input."
        case .cannotAddOutput: return "Sentinel could not configure photo capture."
        case .captureAlreadyInProgress: return "A camera capture is already in progress."
        case .captureFailed: return "The camera did not return a photo."
        case .imageDecodeFailed: return "The captured image could not be decoded."
        case .imageEncodeFailed: return "The captured image could not be compressed."
        }
    }
}

final class CameraCaptureService: NSObject, AVCapturePhotoCaptureDelegate {
    private let sessionQueue = DispatchQueue(label: "dev.sentinel.camera.capture", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraDevice: AVCaptureDevice?
    private var continuation: CheckedContinuation<Data, Error>?
    private var captureAttempt = 0
    private var warmupStartedAt: TimeInterval = 0

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func captureJPEG(quality: CaptureImageQuality) async throws -> CapturedFrame {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            throw CameraCaptureError.permissionDenied
        }
        let raw = try await captureRawPhoto()
        return try Self.compress(raw, quality: quality)
    }

    private func captureRawPhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraCaptureError.captureFailed)
                    return
                }
                guard self.continuation == nil else {
                    continuation.resume(throwing: CameraCaptureError.captureAlreadyInProgress)
                    return
                }

                do {
                    try self.configureSessionIfNeeded()
                    guard let session = self.session,
                          let output = self.photoOutput,
                          let device = self.cameraDevice else {
                        throw CameraCaptureError.captureFailed
                    }

                    self.continuation = continuation
                    self.captureAttempt = 0
                    if !session.isRunning {
                        session.startRunning()
                    }
                    self.warmupStartedAt = ProcessInfo.processInfo.systemUptime
                    self.scheduleReadinessCheck(output: output, device: device, after: CameraWarmupPolicy.minimumWarmupSeconds)
                } catch {
                    self.finishCapture(with: .failure(error))
                }
            }
        }
    }

    private func configureSessionIfNeeded() throws {
        if session != nil, photoOutput != nil, cameraDevice != nil { return }
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraCaptureError.noCamera
        }

        try configureAutomaticImageAdjustments(on: device)

        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCapturePhotoOutput()
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraCaptureError.cannotAddInput
        }
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw CameraCaptureError.cannotAddOutput
        }
        session.addOutput(output)
        session.commitConfiguration()

        self.session = session
        self.photoOutput = output
        self.cameraDevice = device
    }

    private func configureAutomaticImageAdjustments(on device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }

    private func scheduleReadinessCheck(
        output: AVCapturePhotoOutput,
        device: AVCaptureDevice,
        after delay: TimeInterval
    ) {
        sessionQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.captureWhenExposureSettles(output: output, device: device)
        }
    }

    private func captureWhenExposureSettles(output: AVCapturePhotoOutput, device: AVCaptureDevice) {
        guard continuation != nil else { return }
        let elapsed = ProcessInfo.processInfo.systemUptime - warmupStartedAt
        let stillAdjusting = device.isAdjustingExposure || device.isAdjustingWhiteBalance

        if stillAdjusting && elapsed < CameraWarmupPolicy.maximumWarmupSeconds {
            scheduleReadinessCheck(output: output, device: device, after: CameraWarmupPolicy.exposurePollSeconds)
            return
        }

        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if let error {
                self.finishCapture(with: .failure(error))
                return
            }
            guard let data else {
                self.finishCapture(with: .failure(CameraCaptureError.captureFailed))
                return
            }

            let averageLuma = Self.averageLuma(of: data) ?? 1
            if CameraWarmupPolicy.shouldRetryProbablyBlackFrame(
                attempt: self.captureAttempt,
                averageLuma: averageLuma
            ) {
                self.captureAttempt += 1
                self.sessionQueue.asyncAfter(deadline: .now() + CameraWarmupPolicy.retryDelaySeconds) { [weak self] in
                    guard let self, self.continuation != nil else { return }
                    let retrySettings = AVCapturePhotoSettings()
                    output.capturePhoto(with: retrySettings, delegate: self)
                }
                return
            }

            self.finishCapture(with: .success(data))
        }
    }

    private func finishCapture(with result: Result<Data, Error>) {
        session?.stopRunning()
        guard let continuation else { return }
        self.continuation = nil
        captureAttempt = 0

        switch result {
        case .success(let data):
            continuation.resume(returning: data)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    private static func averageLuma(of data: Data) -> Double? {
        guard let image = NSImage(data: data) else { return nil }
        var sourceRect = NSRect(origin: .zero, size: image.size)
        guard let source = image.cgImage(forProposedRect: &sourceRect, context: nil, hints: nil) else {
            return nil
        }

        let sampleWidth = 32
        let sampleHeight = 18
        let bytesPerPixel = 4
        let bytesPerRow = sampleWidth * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        return pixels.withUnsafeMutableBytes { rawBuffer -> Double? in
            guard let baseAddress = rawBuffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: sampleWidth,
                    height: sampleHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return nil
            }

            context.interpolationQuality = .low
            context.draw(source, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))
            let bytes = rawBuffer.bindMemory(to: UInt8.self)
            var lumaTotal = 0.0
            var pixelCount = 0

            for index in stride(from: 0, to: bytes.count, by: bytesPerPixel) {
                let red = Double(bytes[index]) / 255.0
                let green = Double(bytes[index + 1]) / 255.0
                let blue = Double(bytes[index + 2]) / 255.0
                lumaTotal += 0.2126 * red + 0.7152 * green + 0.0722 * blue
                pixelCount += 1
            }

            guard pixelCount > 0 else { return nil }
            return lumaTotal / Double(pixelCount)
        }
    }

    private static func compress(_ data: Data, quality: CaptureImageQuality) throws -> CapturedFrame {
        guard let image = NSImage(data: data) else {
            throw CameraCaptureError.imageDecodeFailed
        }
        var sourceRect = NSRect(origin: .zero, size: image.size)
        guard let source = image.cgImage(forProposedRect: &sourceRect, context: nil, hints: nil) else {
            throw CameraCaptureError.imageDecodeFailed
        }

        let profile: (maxWidth: Int, maxHeight: Int, compression: CGFloat)
        switch quality {
        case .efficient: profile = (720, 405, 0.42)
        case .standard: profile = (960, 540, 0.58)
        case .high: profile = (1280, 720, 0.72)
        }

        let widthScale = CGFloat(profile.maxWidth) / CGFloat(source.width)
        let heightScale = CGFloat(profile.maxHeight) / CGFloat(source.height)
        let scale = min(1, widthScale, heightScale)
        let width = max(1, Int((CGFloat(source.width) * scale).rounded()))
        let height = max(1, Int((CGFloat(source.height) * scale).rounded()))

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw CameraCaptureError.imageEncodeFailed
        }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage() else {
            throw CameraCaptureError.imageEncodeFailed
        }

        let rep = NSBitmapImageRep(cgImage: scaled)
        guard let jpeg = rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: profile.compression]
        ) else {
            throw CameraCaptureError.imageEncodeFailed
        }
        return CapturedFrame(data: jpeg, width: width, height: height)
    }
}
#endif
