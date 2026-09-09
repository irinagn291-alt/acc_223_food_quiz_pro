import SwiftUI
import AVFoundation
import PhotosUI

private enum ScannerState {
    case idle
    case scanning
    case processing
}

struct ScannerView: View {
    @State private var scannerState: ScannerState = .idle
    @State private var isCameraRunning = false
    @State private var scannedProduct: Product?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDetail = false
    @State private var lastScannedCode: String?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                if scannerState == .scanning || scannerState == .processing {
                    BarcodeScannerRepresentable(isRunning: $isCameraRunning) { code in
                        handleBarcodeDetected(code)
                    }
                    .ignoresSafeArea(edges: .top)
                }

                scanOverlay
            }
            .background(Color(.systemBackground))
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDetail) {
                if let product = scannedProduct {
                    ProductDetailView(product: product)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await scanPhoto(item) }
            }
            .onChange(of: showDetail) { _, isShowing in
                if !isShowing {
                    resetScanner()
                }
            }
            .onDisappear {
                if scannerState == .scanning {
                    scannerState = .idle
                }
                stopCamera()
            }
        }
    }

    private var scanOverlay: some View {
        VStack(spacing: 16) {
            if scannerState == .idle {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 120, height: 120)

                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 52))
                            .foregroundStyle(.tint)
                    }

                    Text("Ready to scan")
                        .font(.title3.weight(.semibold))

                    Text("Tap Start Scanning or choose a photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            } else {
                Spacer()

                if scannerState == .scanning {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 260, height: 140)
                        .overlay {
                            Text("Point at a barcode")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.black.opacity(0.5), in: Capsule())
                                .offset(y: 80)
                        }
                }

                Spacer()
            }

            if isLoading {
                ProgressView("Looking up product...")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            if let error = errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Button("Dismiss") {
                        errorMessage = nil
                        resetScanner()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            VStack(spacing: 12) {
                if scannerState == .idle {
                    Button {
                        startScanning()
                    } label: {
                        Label("Start Scanning", systemImage: "barcode.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                } else if scannerState == .processing && !isLoading {
                    Button {
                        startScanning()
                    } label: {
                        Label("Scan Again", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                }

                galleryButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private var galleryButton: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("Choose from Gallery", systemImage: "photo.on.rectangle.angled")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
    }

    private func startScanning() {
        errorMessage = nil
        lastScannedCode = nil
        scannerState = .scanning
        isCameraRunning = true
    }

    private func stopCamera() {
        isCameraRunning = false
    }

    private func resetScanner() {
        stopCamera()
        scannerState = .idle
        lastScannedCode = nil
        errorMessage = nil
    }

    private func handleBarcodeDetected(_ code: String) {
        guard scannerState == .scanning,
              !isLoading,
              code != lastScannedCode else { return }

        lastScannedCode = code
        scannerState = .processing
        stopCamera()
        HapticService.selection()
        Task { await handleScan(code) }
    }

    private func scanPhoto(_ item: PhotosPickerItem) async {
        stopCamera()
        scannerState = .processing
        isLoading = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load the selected photo"
                HapticService.error()
                isLoading = false
                scannerState = .idle
                selectedPhoto = nil
                return
            }

            guard let code = await BarcodeDetector.detect(in: image) else {
                errorMessage = "No barcode found in this photo"
                HapticService.error()
                isLoading = false
                scannerState = .idle
                selectedPhoto = nil
                return
            }

            lastScannedCode = code
            HapticService.selection()
            await handleScan(code)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.error()
            isLoading = false
            scannerState = .idle
        }

        selectedPhoto = nil
    }

    private func handleScan(_ barcode: String) async {
        isLoading = true
        errorMessage = nil
        do {
            scannedProduct = try await OpenFoodFactsService.shared.fetchProduct(barcode: barcode)
            HapticService.success()
            showDetail = true
        } catch {
            HapticService.error()
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var isRunning: Bool
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> BarcodeScannerVC {
        let vc = BarcodeScannerVC()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerVC, context: Context) {
        context.coordinator.parent = self
        uiViewController.setRunning(isRunning)
    }

    @MainActor
    class Coordinator: NSObject, BarcodeScannerDelegate {
        var parent: BarcodeScannerRepresentable

        init(parent: BarcodeScannerRepresentable) {
            self.parent = parent
        }

        func didScanBarcode(_ code: String) {
            parent.onScan(code)
        }
    }
}

@MainActor
protocol BarcodeScannerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
}

class BarcodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: (any BarcodeScannerDelegate)?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var shouldRun = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func setRunning(_ running: Bool) {
        shouldRun = running
        if running {
            configureIfNeeded()
            startSession()
        } else {
            stopSession()
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    private func startSession() {
        guard shouldRun, isConfigured, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }
        Task { @MainActor [weak self] in
            self?.delegate?.didScanBarcode(code)
        }
    }
}
