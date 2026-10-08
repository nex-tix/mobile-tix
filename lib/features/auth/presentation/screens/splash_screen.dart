import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';

/// Splash Screen reflecting `newDesign` Gate Validator brand.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _opacity = 0);
      Future<void>.delayed(AppSpacing.base, widget.onDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: AppSpacing.base,
        curve: Curves.easeInOut,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 148,
                      height: 148,
                      alignment: Alignment.center,
                      child: Image.asset(
                        AppConfig.logoAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('auth.appTitle'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF8F6F6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('splash.subtitle'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: Color(0xFFA3B1B7),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    context.tr(
                      'splash.version',
                      namedArgs: {
                        'version': AppConfig.version,
                        'build': 'Demo UI',
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7E86),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
