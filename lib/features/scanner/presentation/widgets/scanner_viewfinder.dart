import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';


/// Camera Viewfinder card based on Screen 5 (`5._scan_check_in/code.html`).
///
/// Features:
/// - Dark camera feed vignette styling
/// - 4 curved corner reticles in Deep Red (`#CF4647`)
/// - Central QR crosshair focus icon
/// - "Scan QR ticket" caption
/// - Tappable preview to simulate scan
class ScannerViewfinder extends StatefulWidget {
  const ScannerViewfinder({
    super.key,
    required this.height,
    required this.onSimulate,
    this.disabled = false,
    this.processing = false,
  });

  final double height;
  final VoidCallback onSimulate;
  final bool disabled;
  final bool processing;

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameSize = (widget.height * 0.58).clamp(180.0, 240.0);

    return GestureDetector(
      onTap: widget.disabled ? null : widget.onSimulate,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF182023),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF334147), width: 1.2),
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Color(0xFF212B2F),
              Color(0xFF141A1D),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Reticle with 4 Corners
            SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Top-Left Corner
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: _ReticleCorner(
                      top: true,
                      left: true,
                    ),
                  ),
                  // Top-Right Corner
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: _ReticleCorner(
                      top: true,
                      left: false,
                    ),
                  ),
                  // Bottom-Left Corner
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    child: _ReticleCorner(
                      top: false,
                      left: true,
                    ),
                  ),
                  // Bottom-Right Corner
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: _ReticleCorner(
                      top: false,
                      left: false,
                    ),
                  ),

                  // Center QR Focus Crosshair Icon
                  Center(
                    child: widget.processing
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFFCF4647),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.6 + (_sweep.value * 0.4),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                AppIcons.qrScanner,
                                size: 36,
                                color: Color(0xFFCF4647),
                              ),
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
                            offset: Offset(0, 16 + (_sweep.value * (frameSize - 36))),
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x00CF4647),
                                    Color(0xFFCF4647),
                                    Color(0x00CF4647),
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

            // Helper Instruction Text Under Viewfinder
            Positioned(
              bottom: 18,
              child: Text(
                widget.processing ? 'Memverifikasi tiket…' : 'Scan QR ticket',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8F6F6),
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black,
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
  const _ReticleCorner({
    required this.top,
    required this.left,
  });

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const stroke = 4.0;
    const radius = Radius.circular(12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFFCF4647), width: stroke) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFFCF4647), width: stroke) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFFCF4647), width: stroke) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFFCF4647), width: stroke) : BorderSide.none,
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
