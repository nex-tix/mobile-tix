import 'package:flutter/material.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:mobile_tix/core/theme/app_colors.dart';
import 'package:mobile_tix/core/utils/i18n_helper.dart';

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
          color: context.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.outline, width: 1.2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.surfaceAlt,
              context.colors.surfaceAlt.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.scrim.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
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
                              child: Icon(
                                AppIcons.qrScanner,
                                size: 36,
                                color: context.colors.primary,
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

            // Helper Instruction Text Under Viewfinder
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
                  color: context.colors.ink,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: context.colors.scrim, blurRadius: 4)],
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
    const stroke = 4.0;
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
