// lib/screens/splash_nudge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/data/nudge_messages.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/home_screen.dart';
import 'package:carbon_tracker/screens/onboarding_screen.dart';
import 'package:carbon_tracker/services/nudge_message_picker.dart';

class SplashNudgeScreen extends StatefulWidget {
  const SplashNudgeScreen({super.key});

  @override
  State<SplashNudgeScreen> createState() => _SplashNudgeScreenState();
}

class _SplashNudgeScreenState extends State<SplashNudgeScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2500);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _duration,
  );

  NudgeMessage? _message;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start countdown as soon as the provider is initialized.
    // didChangeDependencies is called on every dependency change, so guard with _message.
    if (_message != null) return;
    final provider = context.read<EmissionProvider>();
    if (!provider.initialized) return;

    _message = NudgeMessagePicker.pick(provider);
    // Start progress bar after the current frame to avoid setState-in-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progress.forward().whenComplete(() {
        final p = context.read<EmissionProvider>();
        _navigate(p);
      });
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _navigate(EmissionProvider provider) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => provider.isFirstLaunch
            ? const OnboardingScreen()
            : const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch here ensures didChangeDependencies fires when provider changes.
    final provider = context.watch<EmissionProvider>();
    final msg = _message;

    return Scaffold(
      backgroundColor: VoetjeColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigate(provider),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/voetje_icon.png',
                            height: 64),
                        const SizedBox(height: 12),
                        Text(
                          'Voetje',
                          style: VoetjeTypography.pageTitle().copyWith(
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        if (msg != null) ...[
                          Text(
                            msg.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            msg.text,
                            style: VoetjeTypography.caption().copyWith(
                                  fontSize: 13,
                                  color: VoetjeColors.textSecondary,
                                  height: 1.6,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ] else
                          // Placeholder keeps layout stable while loading
                          const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ),

              // Progress bar — fades in once initialized
              AnimatedOpacity(
                opacity: provider.initialized ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          // Track
                          Container(
                            height: 3,
                            width: double.infinity,
                            color: VoetjeColors.progressTrack,
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              height: 3,
                              color: VoetjeColors.primaryMedium,
                            ),
                          ),
                        ],
                      ),
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
