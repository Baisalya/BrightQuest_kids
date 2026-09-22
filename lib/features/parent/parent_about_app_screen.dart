import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/app_distribution_info.dart';
import '../../core/services/external_link_service.dart';
import '../../widgets/bright_illustrations.dart';
import '../../widgets/whats_new_dialog.dart';
import 'parent_section_scaffold.dart';

class ParentAboutAppScreen extends StatelessWidget {
  const ParentAboutAppScreen({super.key});

  static const _links = ExternalLinkService();

  @override
  Widget build(BuildContext context) => ParentSectionScaffold(
        title: 'About us & updates',
        subtitle:
            'Developer details, official links, support, version information and verified Store status.',
        icon: Icons.info_outline,
        children: [
          const _AppIdentityCard(),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'BrightQuest online',
            subtitle:
                'Official app website, safe download status, privacy policy and parent support.',
            icon: Icons.public_rounded,
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                FilledButton.icon(
                  key: const Key('about_official_website'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.website,
                    'BrightQuest Kids website',
                  ),
                  icon: const Icon(Icons.language_rounded),
                  label: const Text('App website'),
                ),
                OutlinedButton.icon(
                  key: const Key('about_downloads_page'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.downloadsPage,
                    'official downloads page',
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Downloads'),
                ),
                OutlinedButton.icon(
                  key: const Key('about_privacy_policy'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.privacyPolicy,
                    'privacy policy',
                  ),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Privacy'),
                ),
                OutlinedButton.icon(
                  key: const Key('about_support_page'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.supportPage,
                    'support page',
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Support'),
                ),
                OutlinedButton.icon(
                  key: const Key('about_terms_page'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.termsPage,
                    'terms of use',
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'Developer',
            subtitle:
                '${AppDistributionInfo.developerName} (${AppDistributionInfo.developerAlias})',
            icon: Icons.code,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppDistributionInfo.developerRole,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                const Text(
                  AppDistributionInfo.developerSummary,
                  style: TextStyle(color: Colors.black87, height: 1.45),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppDistributionInfo.developerFocus,
                  style: TextStyle(
                    color: Color(0xFF415F8F),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('about_more_developer_details'),
                    onPressed: () => _showDeveloperDetails(context),
                    icon: const Icon(Icons.badge),
                    label: const Text('More developer details'),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    FilledButton.icon(
                      key: const Key('about_baisalya_website'),
                      onPressed: () => _open(
                        context,
                        AppDistributionInfo.developerWebsite,
                        'Baisalya.com',
                      ),
                      icon: const Icon(Icons.language),
                      label: const Text('Baisalya.com'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('about_github'),
                      onPressed: () => _open(
                        context,
                        AppDistributionInfo.github,
                        'GitHub profile',
                      ),
                      icon: const Icon(Icons.code),
                      label: const Text('GitHub'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('about_linkedin'),
                      onPressed: () => _open(
                        context,
                        AppDistributionInfo.linkedin,
                        'LinkedIn profile',
                      ),
                      icon: const Icon(Icons.work_outline),
                      label: const Text('LinkedIn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'Support independent development',
            subtitle:
                'Creator support is optional and always opens outside the child learning experience.',
            icon: Icons.local_cafe,
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                FilledButton.icon(
                  key: const Key('about_buy_me_a_coffee'),
                  onPressed: () => _open(
                    context,
                    AppDistributionInfo.buyMeACoffee,
                    'Buy Me a Coffee',
                  ),
                  icon: const Icon(Icons.local_cafe),
                  label: const Text('Buy me a coffee'),
                ),
                OutlinedButton.icon(
                  key: const Key('about_contact_developer'),
                  onPressed: () => _email(context),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact developer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'Version & updates',
            subtitle:
                'See what changed in this build and check the verified release destination.',
            icon: Icons.system_update,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _VersionRow(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('about_whats_new'),
                      onPressed: () => _showWhatsNew(context),
                      icon: const Icon(Icons.new_releases),
                      label: const Text("What's new"),
                    ),
                    FilledButton.icon(
                      key: const Key('about_check_updates'),
                      onPressed: () => _showUpdateDialog(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check for updates'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentSectionCard(
            title: 'Rate & Store availability',
            subtitle:
                'Store actions stay disabled until a verified BrightQuest Kids listing actually exists.',
            icon: Icons.star_outline,
            child: Column(
              children: [
                const _StoreStatusRow(
                  icon: Icons.phone_android,
                  label: 'Google Play',
                  published: AppDistributionInfo.googlePlayPublished,
                ),
                const Divider(height: 20),
                const _StoreStatusRow(
                  icon: Icons.desktop_windows,
                  label: 'Microsoft Store',
                  published: AppDistributionInfo.microsoftStorePublished,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('about_rate_app'),
                    onPressed: () => _showRatingDialog(context),
                    icon: const Icon(Icons.star),
                    label: const Text('Rate BrightQuest Kids'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.family_restroom,
                      color: Color(0xFF415F8F)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'External websites, creator support and Store actions live only in the parent area so children are not sent to purchase, social or web destinations by normal gameplay.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _open(
    BuildContext context,
    String url,
    String label,
  ) async {
    final opened = await _links.open(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $label on this device.')),
      );
    }
  }

  Future<void> _email(BuildContext context) async {
    final opened = await _links.email(
      address: AppDistributionInfo.email,
      subject: 'BrightQuest Kids',
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app is available.')),
      );
    }
  }

  Future<void> _showDeveloperDetails(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Developer details'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '${AppDistributionInfo.developerName} (${AppDistributionInfo.developerAlias})',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(AppDistributionInfo.developerRole),
                  const SizedBox(height: 16),
                  const Text(
                    'Education',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  for (final item in AppDistributionInfo.education)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $item'),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Software portfolio',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(AppDistributionInfo.products.join(' • ')),
                  const SizedBox(height: 14),
                  const Text(
                    'Product approach',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Practical first, local where it matters, and release-minded: product structure, recovery, validation and platform behavior are treated as part of the software rather than cleanup after coding.',
                    style: TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  Future<void> _showWhatsNew(BuildContext context) async {
    await showBrightQuestWhatsNewDialog(context, automatic: false);
  }

  Future<void> _showUpdateDialog(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final platformName = Platform.isWindows ? 'Microsoft Store' : 'Google Play';
          final published = Platform.isWindows
              ? AppDistributionInfo.microsoftStorePublished
              : AppDistributionInfo.googlePlayPublished;
          final storeUrl = Platform.isWindows
              ? AppDistributionInfo.microsoftStoreUrl
              : AppDistributionInfo.googlePlayUrl;
          return AlertDialog(
            title: const Text('Check for updates'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                published && storeUrl != null
                    ? 'BrightQuest Kids ${AppDistributionInfo.version} is installed. Open $platformName to check the latest published release.'
                    : 'BrightQuest Kids ${AppDistributionInfo.version} is installed. There is no verified public $platformName listing for this app yet, so no Store update is claimed. Use the official Downloads page for verified release news.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
              if (published && storeUrl != null)
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _open(context, storeUrl, platformName);
                  },
                  child: Text('Open $platformName'),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _open(
                      context,
                      AppDistributionInfo.downloadsPage,
                      'official downloads page',
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Downloads'),
                ),
            ],
          );
        },
      );

  Future<void> _showRatingDialog(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Rate BrightQuest Kids'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: const Text(
              'A rating should go to a verified Store listing. BrightQuest Kids is not yet published on Google Play or Microsoft Store, so rating links are intentionally unavailable in this build. They can be enabled from one central distribution file after the real Store IDs exist.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _open(
                  context,
                  AppDistributionInfo.downloadsPage,
                  'official downloads page',
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Downloads'),
            ),
          ],
        ),
      );
}

class _AppIdentityCard extends StatelessWidget {
  const _AppIdentityCard();

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrightQuestAppIcon(size: 56),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDistributionInfo.appName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Offline-first educational adventure for Nursery and Classes 3–5.',
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Version ${AppDistributionInfo.version}',
                      style: TextStyle(
                        color: Color(0xFF415F8F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Icon(Icons.apps, color: Color(0xFF415F8F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Installed version',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            AppDistributionInfo.version,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      );
}

class _StoreStatusRow extends StatelessWidget {
  const _StoreStatusRow({
    required this.icon,
    required this.label,
    required this.published,
  });

  final IconData icon;
  final String label;
  final bool published;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: const Color(0xFF415F8F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: published
                  ? const Color(0xFFE4F5EA)
                  : const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              published ? 'Published' : 'Not published yet',
              style: TextStyle(
                color: published
                    ? const Color(0xFF2B7A52)
                    : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}
