import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/home_screen.dart';
import 'package:carbon_tracker/widgets/voetje_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    const _OnboardingPage(
      icon: Icons.eco,
      title: 'Track Your Footprint',
      description:
          'Log your daily transport to understand your personal carbon emissions. '
          'Knowledge is the first step towards change.',
    ),
    const _OnboardingPage(
      icon: Icons.shield_outlined,
      title: 'Your Data, Your Device',
      description:
          'Everything stays on your phone. No accounts, no servers, no tracking. '
          'Export backups to your own cloud whenever you want.',
    ),
    const _OnboardingPage(
      icon: Icons.favorite_outline,
      title: 'Free Forever',
      description:
          'No ads, no subscriptions, no data harvesting. '
          'Built by someone who cares about the planet. '
          'Tips are welcome but never required.',
    ),
    _CategorySelectionPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.backgroundOf(context),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress bars
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      VoetjeSpacing.screenEdge, 16,
                      VoetjeSpacing.screenEdge, 0),
                  child: Row(
                    children: List.generate(_pages.length, (i) {
                      final isFilled = i <= _currentPage;
                      return Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(right: i < _pages.length - 1 ? 6 : 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 3,
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? VoetjeColors.primaryMediumOf(context)
                                  : VoetjeColors.progressTrackOf(context),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _pages[i],
                  ),
                ),

                // Navigation buttons — hidden on the last page
                if (!_isLastPage) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: VoetjeSpacing.screenEdge),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Text(
                              'Back',
                              style: VoetjeTypography.caption().copyWith(
                                    color: VoetjeColors.textMutedOf(context),
                                  ),
                            ),
                          )
                        else
                          const SizedBox(width: 80),
                        const Spacer(),
                        _PillButton(
                          label: 'Next',
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
              ],
            ),

            // Skip button — top right
            if (!_isLastPage)
              Positioned(
                top: 8,
                right: VoetjeSpacing.screenEdge,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: VoetjeTypography.caption().copyWith(
                          fontSize: 12,
                          color: VoetjeColors.textMutedOf(context),
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    await context.read<EmissionProvider>().completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}

// ─── Pill button ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: VoetjeButton(label: label, onPressed: onPressed),
    );
  }
}

// ─── Info page ────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: VoetjeSpacing.screenEdge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Frosted circle illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: VoetjeColors.surfaceOf(context).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(60),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: VoetjeIconSize.xlargeIcon, color: VoetjeColors.primaryMediumOf(context)),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            style: VoetjeTypography.pageQuestion(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 13,
                  color: VoetjeColors.textSecondaryOf(context),
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Category selection page ──────────────────────────────────────────────────

class _CategorySelectionPage extends StatefulWidget {
  @override
  State<_CategorySelectionPage> createState() =>
      _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<_CategorySelectionPage> {
  bool _food = true;
  bool _energy = true;
  bool _shopping = true;
  bool _waste = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: VoetjeSpacing.screenEdge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            'What do you want to track?',
            style: VoetjeTypography.pageQuestion(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can always change this in Settings.',
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 13,
                  color: VoetjeColors.textSecondaryOf(context),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _categoryRow(
            emoji: '\u{1F697}',
            name: 'Transport',
            description: 'Always on',
            iconColor: VoetjeColors.transport,
            iconBg: VoetjeColors.transportBg,
            value: true,
            enabled: false,
            onChanged: null,
          ),
          _categoryRow(
            emoji: '\u{1F37D}\uFE0F',
            name: 'Food & Diet',
            description: 'Log meals, see food footprint',
            iconColor: VoetjeColors.food,
            iconBg: VoetjeColors.foodBg,
            value: _food,
            enabled: true,
            onChanged: (v) => setState(() => _food = v),
          ),
          _categoryRow(
            emoji: '\u{1F3E0}',
            name: 'Home Energy',
            description: 'Track electricity & gas bills',
            iconColor: VoetjeColors.energy,
            iconBg: VoetjeColors.energyBg,
            value: _energy,
            enabled: true,
            onChanged: (v) => setState(() => _energy = v),
          ),
          _categoryRow(
            emoji: '\u{1F6CD}\uFE0F',
            name: 'Shopping',
            description: 'See the CO\u2082 in what you buy',
            iconColor: VoetjeColors.shopping,
            iconBg: VoetjeColors.shoppingBg,
            value: _shopping,
            enabled: true,
            onChanged: (v) => setState(() => _shopping = v),
          ),
          _categoryRow(
            emoji: '\u267B\uFE0F',
            name: 'Waste & Recycling',
            description: 'Weekly bin & recycling tracking',
            iconColor: VoetjeColors.waste,
            iconBg: VoetjeColors.wasteBg,
            value: _waste,
            enabled: true,
            onChanged: (v) => setState(() => _waste = v),
          ),
          const SizedBox(height: 28),
          VoetjeButton(label: 'Get Started', onPressed: _getStarted),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _categoryRow({
    required String emoji,
    required String name,
    required String description,
    required Color iconColor,
    required Color iconBg,
    required bool value,
    required bool enabled,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(VoetjeRadius.card),
          border: Border.all(color: VoetjeColors.borderOf(context), width: 1),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius:
                    BorderRadius.circular(VoetjeRadius.iconContainer),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: VoetjeTypography.caption().copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: VoetjeColors.textPrimaryOf(context),
                          )),
                  Text(
                    description,
                    style: VoetjeTypography.caption().copyWith(
                          fontSize: 11,
                          color: VoetjeColors.textMutedOf(context),
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getStarted() async {
    final provider = context.read<EmissionProvider>();
    await provider.completeOnboardingWithCategories(
      food: _food,
      energy: _energy,
      shopping: _shopping,
      waste: _waste,
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
