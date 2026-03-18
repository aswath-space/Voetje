import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carbon_tracker/config/theme.dart';

/// The "send me some love" page.
/// Multiple donation/tip options — no pressure, no paywalls.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // SECURITY: These are payment/donation links. Changes to this file require
  // maintainer review via CODEOWNERS. Do not accept PRs that modify these URLs
  // without verifying they point to the correct accounts.
  static const _links = {
    'buy_me_coffee': 'https://buymeacoffee.com/aswathsubramanian',
    'paypal': 'https://www.paypal.com/donate/?hosted_button_id=8H9B7NVCKG7JJ',
    'github_repo': 'https://github.com/aswath-space/voetje',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support This Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Heart icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Voetje is free.\nForever.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'No ads, no subscriptions, no data harvesting. '
                'Just a tool to help you understand and reduce '
                'your carbon footprint.\n\n'
                'If you find it useful, you can show your appreciation '
                'in any of these ways:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
            ),
            const SizedBox(height: 28),

            // Donation options
            _SupportOption(
              icon: Icons.local_cafe,
              iconColor: const Color(0xFFFF813F),
              title: 'Buy Me a Coffee',
              subtitle: 'One-time tip or monthly support',
              url: _links['buy_me_coffee']!,
            ),
            _SupportOption(
              icon: Icons.payment,
              iconColor: const Color(0xFF003087),
              title: 'PayPal',
              subtitle: 'One-time donation via PayPal',
              url: _links['paypal']!,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Non-monetary support
            Text(
              'Other Ways to Help',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _SupportOption(
              icon: Icons.star_outline,
              iconColor: AppColors.accent,
              title: 'Star on GitHub',
              subtitle: 'Help others discover this project',
              url: _links['github_repo']!,
            ),
            const _SupportOption(
              icon: Icons.share,
              iconColor: AppColors.primary,
              title: 'Tell a Friend',
              subtitle: 'Word of mouth is the best marketing',
              url: '', // handled with share
              isShare: true,
            ),
            _SupportOption(
              icon: Icons.bug_report_outlined,
              iconColor: Colors.purple,
              title: 'Report Issues',
              subtitle: 'Found a bug? Let me know on GitHub',
              url: '${_links['github_repo']}/issues',
            ),

            const SizedBox(height: 32),
            Text(
              'Thank you for caring about our planet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String url;
  final bool isShare;

  const _SupportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.url,
    this.isShare = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          isShare ? Icons.share : Icons.open_in_new,
          size: 18,
          color: Colors.grey,
        ),
        onTap: () async {
          if (isShare) {
            await SharePlus.instance.share(ShareParams(
              text: 'I use Voetje to track my carbon footprint — free, private, no ads. '
                  'Check it out: https://github.com/aswath-space/voetje',
            ));
            return;
          }
          if (url.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link not yet configured.')),
              );
            }
            return;
          }
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
