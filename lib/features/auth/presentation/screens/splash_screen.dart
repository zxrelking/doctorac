import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_logo.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _routeNext();
  }

  Future<void> _routeNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final isSignedIn = ref.read(authRepositoryProvider).isSignedIn;
    context.go(isSignedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle top-right & top-left mint ambient glow matching Figma
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mintGlow.withValues(alpha: 0.75),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: const Center(
                      child: DoctoracLogo(
                        iconSize: 94,
                        fontSize: 32,
                        axis: Axis.vertical,
                        spacing: 14,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _fade,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Text(
                      'كل رعايتك الصحية في مكان واحد',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
