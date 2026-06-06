import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_scaffold.dart';
import 'home/home_screen.dart';
import 'demands/demands_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/conversations_screen.dart';
import 'nearby/nearby_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ConversationsScreen(),
    const NearbyScreen(),
    const DemandsScreen(),
    const ProfileScreen(),
  ];

  static const List<NavDestination> _destinations = [
    NavDestination(
      icon: Icons.home_rounded,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavDestination(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    NavDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Nearby',
    ),
    NavDestination(
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
      label: 'Demandes',
    ),
    NavDestination(
      icon: Icons.person_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: _destinations,
      body: Stack(
        children: [
          _screens[_currentIndex],
          // Impersonation banner
          if (authProvider.isImpersonating)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Impersonating ${authProvider.user?.displayName ?? "user"}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => authProvider.stopImpersonation(),
                      child: const Text(
                        'Exit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QRScannerSheet(),
    );
  }
}


class QRScannerSheet extends StatefulWidget {
  const QRScannerSheet({super.key});

  @override
  State<QRScannerSheet> createState() => _QRScannerSheetState();
}

class _QRScannerSheetState extends State<QRScannerSheet> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _lastScannedCode;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    // Show result dialog
    _showResultDialog(code);
  }

  void _showResultDialog(String code) {
    final bool isUrl = Uri.tryParse(code)?.hasScheme ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('QR Code Scanned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Scan Again'),
          ),
          if (isUrl)
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final uri = Uri.parse(code);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (mounted) {
                  navigator.pop();
                  navigator.pop();
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Link'),
            ),
          if (!isUrl)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Flash toggle
                    if (_controller != null)
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller!,
                        builder: (context, state, child) {
                          return IconButton(
                            onPressed: () => _controller?.toggleTorch(),
                            icon: Icon(
                              state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                              color: state.torchState == TorchState.on ? Colors.amber : Colors.white,
                            ),
                          );
                        },
                      ),
                    // Camera switch
                    IconButton(
                      onPressed: () => _controller?.switchCamera(),
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    ),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Scanner view
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (_hasError)
                    _buildErrorView()
                  else if (_controller != null)
                    MobileScanner(
                      controller: _controller!,
                      onDetect: _handleBarcode,
                      errorBuilder: (context, error, child) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _hasError = true;
                              _errorMessage = _getErrorMessage(error);
                            });
                          }
                        });
                        return _buildErrorView();
                      },
                    ),
                  // Scan overlay
                  if (!_hasError)
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Corner decorations
                            Positioned(
                              top: 0,
                              left: 0,
                              child: _buildCorner(true, true),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _buildCorner(true, false),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: _buildCorner(false, true),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: _buildCorner(false, false),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Instructions
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _hasError 
                  ? 'Please grant camera permission to scan QR codes'
                  : 'Point your camera at a QR code',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera permission required',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _controller?.dispose();
                _initializeScanner();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied.\nPlease enable it in settings.';
      case MobileScannerErrorCode.unsupported:
        return 'Camera not supported on this device.';
      default:
        return 'Failed to initialize camera.\nPlease try again.';
    }
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(8) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(8) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}

class MyVCardsScreen extends StatelessWidget {
  const MyVCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My vCards')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Your vCards will appear here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerPlaceholder extends StatelessWidget {
  const QRScannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('QR Scanner')),
    );
  }
}
