import 'package:flutter/material.dart';

import '../../widgets/bright_widgets.dart';

class ParentSectionScaffold extends StatelessWidget {
  const ParentSectionScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.maxWidth = 980,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          BrightHeader(title: title, showBack: true),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF6F8FB),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionContextBanner(
                            icon: icon,
                            subtitle: subtitle,
                          ),
                          const SizedBox(height: 14),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class ParentSectionCard extends StatelessWidget {
  const ParentSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0F8),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xFF415F8F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class ParentManagementTile extends StatelessWidget {
  const ParentManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 118),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0F8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: const Color(0xFF415F8F)),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      status!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF415F8F),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _SectionContextBanner extends StatelessWidget {
  const _SectionContextBanner({
    required this.icon,
    required this.subtitle,
  });

  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF415F8F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF4C5870),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
}
