import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:mobile_tix/core/theme/app_colors.dart';
import 'package:mobile_tix/core/utils/i18n_helper.dart';

/// Camera Viewfinder card based on Screen 5 (`5._scan_check_in/code.html`).
///
/// Features:
/// - Real hardware camera feed via `mobile_scanner` on Android/iOS
/// - Torch/Flashlight toggle and camera switch controls
/// - Anti-duplicate scan cooldown debounce (2 seconds)
/// - 4 curved corner reticles in Deep Red (`#CF4647`)
/// - Sweeping laser animation
/// - Tappable preview fallback for simulation and test environments
class ScannerViewfinder extends StatefulWidget {
  const ScannerViewfinder({
    super.key,
    required this.height,
    required this.onSimulate,
    this.onScanned,
    this.disabled = false,
    this.processing = false,
    this.isActive = true,
  });

  final double height;
  final VoidCallback onSimulate;
  final ValueChanged<String>? onScanned;
  final bool disabled;
  final bool processing;
  final bool isActive;

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  MobileScannerController? _scannerController;
  bool _torchEnabled = false;
  DateTime? _lastScannedAt;
  String? _lastScannedCode;

  bool get _canUseCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive && !widget.disabled) {
      _sweep.repeat(reverse: true);
    }
    if (_canUseCamera && widget.isActive) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void didUpdateWidget(ScannerViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.disabled != widget.disabled) {
      if (widget.isActive && !widget.disabled) {
        _startCamera();
      } else {
        _stopCamera();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_canUseCamera || _scannerController == null) return;
    if (state == AppLifecycleState.resumed &&
        widget.isActive &&
        !widget.disabled) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  void _startCamera() {
    if (!_canUseCamera) return;
    if (_scannerController == null) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      if (mounted) setState(() {});
    } else {
      try {
        _scannerController?.start();
      } catch (_) {}
    }
    if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }
  }

  void _stopCamera() {
    if (!_canUseCamera || _scannerController == null) return;
    try {
      _scannerController?.stop();
    } catch (_) {}
    if (_sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweep.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!widget.isActive || widget.disabled || widget.processing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        final now = DateTime.now();
        if (_lastScannedCode == code && _lastScannedAt != null) {
          if (now.difference(_lastScannedAt!) < const Duration(seconds: 2)) {
            return;
          }
        }
        _lastScannedAt = now;
        _lastScannedCode = code;
        widget.onScanned?.call(code);
        break;
      }
    }
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    try {
      await _scannerController!.toggleTorch();
      setState(() => _torchEnabled = !_torchEnabled);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_scannerController == null) return;
    try {
      await _scannerController!.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = (widget.height * 0.58).clamp(180.0, 240.0);

    return GestureDetector(
      onTap: widget.disabled ? null : widget.onSimulate,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Live Camera Feed (Android/iOS)
            if (_canUseCamera && _scannerController != null && widget.isActive)
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController!,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.noCamera,
                              size: 32,
                              color: context.colors.inkMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.trSafe(
                                'scanner.cameraUnavailable',
                                'Kamera tidak tersedia atau izin ditolak',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 2. Dark Vignette overlay to keep reticle contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Center Reticle with 4 Corners
            SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Top-Left Corner
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: _ReticleCorner(top: true, left: true),
                  ),
                  // Top-Right Corner
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: _ReticleCorner(top: true, left: false),
                  ),
                  // Bottom-Left Corner
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    child: _ReticleCorner(top: false, left: true),
                  ),
                  // Bottom-Right Corner
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: _ReticleCorner(top: false, left: false),
                  ),

                  // Center QR Focus Crosshair Icon
                  Center(
                    child: widget.processing
                        ? SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: context.colors.primary,
                            ),
                          )
                        : Icon(
                            AppIcons.qrScanner,
                            size: 36,
                            color: context.colors.primary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                  ),

                  // Sweeping laser line
                  if (!widget.disabled)
                    Positioned(
                      top: 0,
                      left: 12,
                      right: 12,
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              16 + (_sweep.value * (frameSize - 36)),
                            ),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    context.colors.primary.withValues(
                                      alpha: 0.0,
                                    ),
                                    context.colors.primary,
                                    context.colors.primary.withValues(
                                      alpha: 0.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 4. Torch and Flip controls on top corners (when camera is available)
            if (_canUseCamera && _scannerController != null)
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _torchEnabled ? AppIcons.flash : AppIcons.flashOff,
                        color: _torchEnabled
                            ? context.colors.secondary
                            : Colors.white,
                        size: 22,
                      ),
                      onPressed: _toggleTorch,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                      ),
                      tooltip: context.trSafe('scanner.toggleFlash', 'Lampu Kilat'),
                    ),
                    IconButton(
                      icon: const Icon(
                        AppIcons.replay,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _switchCamera,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                      ),
                      tooltip: context.trSafe('scanner.switchCamera', 'Ganti Kamera'),
                    ),
                  ],
                ),
              ),

            // 5. Helper Instruction Text Under Viewfinder
            Positioned(
              bottom: 18,
              child: Text(
                widget.processing
                    ? context.trSafe('scanner.verifying', 'Verifying ticket…')
                    : context.trSafe('scanner.scanHint', 'Scan QR ticket'),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReticleCorner extends StatelessWidget {
  const _ReticleCorner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const stroke = 2.5;
    const radius = Radius.circular(12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: context.colors.primary, width: stroke)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: context.colors.primary, width: stroke)
              : BorderSide.none,
          left: left
              ? BorderSide(color: context.colors.primary, width: stroke)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: context.colors.primary, width: stroke)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (top && left) ? radius : Radius.zero,
          topRight: (top && !left) ? radius : Radius.zero,
          bottomLeft: (!top && left) ? radius : Radius.zero,
          bottomRight: (!top && !left) ? radius : Radius.zero,
        ),
      ),
    );
  }
}
