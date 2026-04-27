import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/crypto/totp_store.dart';
import '../utils/services/qr_decoder_service.dart';

class AddAccountScreen extends StatefulWidget {
  final String? initialUrl;

  const AddAccountScreen({super.key, this.initialUrl});

  @override
  State<AddAccountScreen> createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  MobileScannerController? scannerController;
  bool torchEnabled = false;

  final platformCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final secretCtrl = TextEditingController();

  bool fromQr = false;
  bool scanned = false;
  bool isScanningImage = false;
  bool cameraPermissionDenied = false;
  String? error;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    if (Platform.isAndroid || Platform.isIOS) {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkCameraPermission();
      });
    }

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      populateFromOtpAuth(widget.initialUrl!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && tabController.index != 1) {
          tabController.animateTo(1);
        }
      });
    }
  }

  Future<void> checkCameraPermission({bool requestIfDenied = true}) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    var status = await Permission.camera.status;
    if (requestIfDenied && status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      cameraPermissionDenied =
          status.isDenied || status.isPermanentlyDenied || status.isRestricted;
    });
  }

  Future<void> openCameraSettings() async {
    final opened = await openAppSettings();
    if (!opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enable camera permission in settings, then tap Retry'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    scannerController?.dispose();
    tabController.dispose();
    platformCtrl.dispose();
    usernameCtrl.dispose();
    secretCtrl.dispose();
    super.dispose();
  }

  String buildTotpUrl({
    required String platform,
    required String username,
    required String secret,
  }) {
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$platform:$username',
      queryParameters: {
        'secret': secret,
        'issuer': platform,
        'digits': '6',
        'period': '30',
      },
    ).toString();
  }

  bool isValidBase32(String input) {
    final cleaned = input.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
    return cleaned.isNotEmpty && RegExp(r'^[A-Z2-7]+$').hasMatch(cleaned);
  }

  void populateFromOtpAuth(String url) {
    final uri = Uri.parse(url);
    final rawPath = uri.path;
    final label = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    final decodedLabel = Uri.decodeComponent(label).trim();

    String platform = '';
    String username = '';
    if (decodedLabel.contains(':')) {
      final separator = decodedLabel.indexOf(':');
      platform = decodedLabel.substring(0, separator).trim();
      username = decodedLabel.substring(separator + 1).trim();
    } else {
      username = decodedLabel;
    }

    final issuer = (uri.queryParameters['issuer'] ?? '').trim();
    if (issuer.isNotEmpty) {
      platform = issuer;
    }

    final secret = uri.queryParameters['secret'] ?? '';
    platformCtrl.text = platform;
    usernameCtrl.text = username;
    secretCtrl.text = secret.toUpperCase();
    fromQr = true;
  }

  void onDetect(BarcodeCapture capture) async {
    if (scanned) return;
    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null || !value.startsWith('otpauth://')) return;
    scanned = true;
    await scannerController?.stop();

    if (!mounted) return;
    populateFromOtpAuth(value);
    tabController.animateTo(1);
    setState(() {});
  }

  Future<void> toggleTorch() async {
    final controller = scannerController;
    if (controller == null) return;

    try {
      await controller.toggleTorch();
      if (!mounted) return;
      setState(() {
        torchEnabled = !torchEnabled;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashlight is not available on this device'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> scanQrFromImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 70,
      );

      if (image == null) return;
      setState(() => isScanningImage = true);

      String? value;
      if (Platform.isAndroid || Platform.isIOS) {
        final inputImage = InputImage.fromFilePath(image.path);
        final barcodeScanner = BarcodeScanner();
        try {
          final barcodes = await barcodeScanner
              .processImage(inputImage)
              .timeout(const Duration(seconds: 3));

          if (barcodes.isNotEmpty) {
            value = barcodes.first.rawValue;
          }
        } catch (_) {}

        await barcodeScanner.close();
      } else {
        try {
          value = await QRDecoder.decodeFromFile(
            image.path,
          ).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
      setState(() => isScanningImage = false);

      if (value == null || !value.startsWith('otpauth://')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to read QR code',
              style: TextStyle(color: Colors.red),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!mounted) return;
      populateFromOtpAuth(value);
      tabController.animateTo(1);
      setState(() {});
    } catch (_) {
      setState(() => isScanningImage = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error scanning image',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Future<void> saveManual() async {
    final platform = platformCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final secret = secretCtrl.text.replaceAll(' ', '').toUpperCase();

    if (platform.isEmpty) {
      setState(() => error = 'Platform cannot be empty');
      return;
    }

    if (username.isEmpty) {
      setState(() => error = 'Username cannot be empty');
      return;
    }

    if (secret.isEmpty) {
      setState(() => error = 'Secret key cannot be empty');
      return;
    }

    if (!isValidBase32(secret)) {
      setState(() => error = 'Invalid secret key format');
      return;
    }

    setState(() => error = null);

    final url = buildTotpUrl(
      platform: platform,
      username: username,
      secret: secret,
    );

    final added = await TotpStore.add(platform, url);

    if (!added) {
      setState(() => error = 'Account already exists');
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            cameraPermissionDenied
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 72),
                          const SizedBox(height: 12),
                          const Text(
                            'Camera permission is disabled',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enable camera access in settings to scan QR codes.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: openCameraSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                checkCameraPermission(requestIfDenied: false),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: scanQrFromImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Browse from Device'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 320,
                                child: Stack(
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 320,
                                        maxHeight: 320,
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: MobileScanner(
                                            controller: scannerController,
                                            onDetect: onDetect,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Material(
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: IconButton(
                                          tooltip: torchEnabled
                                              ? 'Turn flashlight off'
                                              : 'Turn flashlight on',
                                          onPressed: toggleTorch,
                                          icon: Icon(
                                            torchEnabled
                                                ? Icons.flash_off
                                                : Icons.flash_on,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Align the QR code inside the square',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: scanQrFromImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Browse from Device'),
                              ),
                            ],
                          ),
                          if (isScanningImage)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'Use your phone to scan the QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: scanQrFromImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Browse from Device'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: platformCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (fromQr) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ℹ️  The username and secret key are locked to prevent accidental changes. You can only copy them and modify the platform name if needed.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  readOnly: fromQr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
                  readOnly: fromQr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Secret key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: saveManual,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
