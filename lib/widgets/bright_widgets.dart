import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brightquest_scope.dart';
import '../core/accessibility/learning_audio_director.dart';
import '../core/content/achievement_catalog.dart';
import '../core/curriculum/curriculum_models.dart';
import '../core/curriculum/world_mission_catalog.dart';
import '../core/curriculum/world_mission_models.dart';
import '../core/models/game_models.dart';
import '../core/models/progress_models.dart';
import '../core/presentation/game_feel_director.dart';
import '../core/rewards/adventure_reward_engine.dart';
import '../core/rewards/adventure_reward_models.dart';
import '../core/services/bright_audio_service.dart';
import '../core/theme/app_theme.dart';
import 'bright_adaptive.dart';
import 'bright_design_system.dart';
import 'bright_illustrations.dart';
import 'bright_motion.dart';
import 'learning_accessibility_widgets.dart';
import 'world_mission_widgets.dart';

class BrightHeader extends StatelessWidget {
  const BrightHeader({
    super.key,
    this.showBack = false,
    this.title,
    this.trailing,
  });

  final bool showBack;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final showLogo = title == null || width >= 760;

    Widget identity() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? 'Hi, ${controller.activeProfileName}! 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.navy,
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title == null
                      ? 'Class ${controller.selectedClass}  ▾'
                      : 'Learn • Play • Grow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        );

    Widget stats({required bool compactStats}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatChip(
              icon: Icons.monetization_on_rounded,
              value: '${controller.coins}',
              color: const Color(0xFFF3A900),
              compact: compactStats,
            ),
            const SizedBox(width: 6),
            _StatChip(
              icon: Icons.star_rounded,
              value: '${controller.stars}',
              color: const Color(0xFFFFC928),
              compact: compactStats,
            ),
          ],
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B98F1), Color(0xFF55C9FF), Color(0xFF8EE2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Color(0x240C3356), blurRadius: 24, offset: Offset(0, 9))
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
              left: -18,
              bottom: -25,
              child: Icon(Icons.cloud_rounded,
                  size: 92, color: Color(0x66FFFFFF))),
          const Positioned(
              right: -18,
              bottom: -30,
              child: Icon(Icons.cloud_rounded,
                  size: 105, color: Color(0x66FFFFFF))),
          const Positioned(
              right: 86,
              top: 17,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 18, color: Color(0xFFFFDA3D))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 13 : 20,
                10,
                compact ? 13 : 20,
                compact ? 12 : 14,
              ),
              child: LayoutBuilder(
                builder: (context, headerConstraints) {
                  final useStackedHeader = headerConstraints.maxWidth < 420;
                  if (useStackedHeader) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (showBack)
                              _RoundAction(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).maybePop(),
                              )
                            else
                              _ProfileBadge(
                                  avatar: controller.activeProfileAvatar),
                            const SizedBox(width: 10),
                            Expanded(child: identity()),
                            if (trailing != null) ...[
                              const SizedBox(width: 8),
                              Flexible(child: trailing!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            if (showLogo)
                              SizedBox(
                                width: headerConstraints.maxWidth
                                    .clamp(96.0, 132.0)
                                    .toDouble(),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: BrightQuestLogo(compact: true),
                                ),
                              ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: stats(compactStats: true),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      if (showBack)
                        _RoundAction(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        )
                      else
                        _ProfileBadge(avatar: controller.activeProfileAvatar),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: identity(),
                      ),
                      if (showLogo) ...[
                        const SizedBox(width: 8),
                        const Expanded(
                            child:
                                Center(child: BrightQuestLogo(compact: true))),
                      ] else
                        const Spacer(),
                      if (trailing != null) ...[
                        Flexible(child: trailing!),
                        const SizedBox(width: 6),
                      ],
                      stats(compactStats: compact),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.avatar});
  final String avatar;

  @override
  Widget build(BuildContext context) => Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFE37D), Color(0xFFFFB74D)]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x28000000), blurRadius: 11, offset: Offset(0, 4))
          ],
        ),
        child: Text(avatar, style: const TextStyle(fontSize: 28)),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
              width: 44, height: 44, child: Icon(icon, color: AppTheme.navy)),
        ),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon,
      required this.value,
      required this.color,
      required this.compact});
  final IconData icon;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x16000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 17 : 19, color: color),
            const SizedBox(width: 4),
            BrightValuePop(
              value: value,
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 11 : 12)),
            ),
          ],
        ),
      );
}

class AdventureCard extends StatefulWidget {
  const AdventureCard({
    required this.game,
    required this.progress,
    required this.onTap,
    this.badgeText,
    super.key,
  });

  final AdventureGame game;
  final double progress;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  State<AdventureCard> createState() => _AdventureCardState();
}

class _AdventureCardState extends State<AdventureCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: BrightPressableScale(
        hoverScale: 1.018,
        child: Semantics(
          container: true,
          excludeSemantics: true,
          button: true,
          label: '${game.title}. ${game.subtitle}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('adventure_card_${game.id}'),
              borderRadius: BorderRadius.circular(27),
              onTap: () {
                unawaited(BrightAudioService.instance.playSfx(BrightSfx.tap));
                widget.onTap();
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color:
                            game.color.withValues(alpha: hovered ? .30 : .20),
                        blurRadius: hovered ? 24 : 18,
                        offset: const Offset(0, 9)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BrightGameScene(gameId: game.id),
                            const Positioned.fill(child: BrightGlint()),
                            const BrightSparkles(),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 118),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .94),
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 7)
                                    ]),
                                child: Text(
                                    widget.badgeText ?? 'Level ${game.level}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: game.color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            game.color,
                            Color.lerp(game.color, Colors.black, .10)!
                          ])),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(game.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.play_circle_fill_rounded,
                                      color: Colors.white, size: 23),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(game.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: .91),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFFD42A), size: 17),
                                  const SizedBox(width: 4),
                                  Text('Level ${game.level}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: BrightAnimatedProgress(
                                        value: widget.progress,
                                        minHeight: 7,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: .26),
                                        color: const Color(0xFF9CFF62),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
    this.voicePrompt,
    this.voiceChoices = const <Object>[],
    this.learningLevel,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Widget child;
  final String? voicePrompt;
  final Iterable<Object> voiceChoices;
  final LearningLevel? learningLevel;

  @override
  Widget build(BuildContext context) {
    final sceneId = _gameIdFromTitle(title);
    final narrationCue = voicePrompt == null
        ? null
        : const LearningAudioDirector().forGamePrompt(
            gameId: sceneId,
            prompt: voicePrompt!,
            choices: voiceChoices,
          );
    final missionPlan = learningLevel == null
        ? null
        : WorldMissionCatalog.planForLevel(learningLevel!);
    final layout = BrightLayout.of(context);
    final compactHeight = layout.shortViewport;
    return Scaffold(
      body: BrightPageBackground(
        primary: Color.lerp(color, Colors.white, 0.90)!,
        secondary: const Color(0xFFFFFBEC),
        child: Column(
          children: [
            BrightHeader(
              showBack: true,
              title: 'BrightQuest Kids',
              trailing: voicePrompt == null
                  ? null
                  : IconButton(
                      key: const Key('game_read_aloud_button'),
                      tooltip: 'Read aloud',
                      onPressed: () {
                        final controller = BrightQuestScope.of(context);
                        if (!controller.soundEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Audio is turned off for this explorer.',
                              ),
                            ),
                          );
                          return;
                        }
                        unawaited(
                          BrightAudioService.instance.speakPrompt(
                            voicePrompt!,
                            choices: voiceChoices,
                          ),
                        );
                      },
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
            ),
            if (missionPlan != null)
              BrightResponsive(
                maxWidth: 1220,
                padding: EdgeInsets.fromLTRB(
                  layout.gutter,
                  compactHeight ? 5 : 9,
                  layout.gutter,
                  0,
                ),
                builder: (context, breakpoint) => WorldMissionRibbon(
                  plan: missionPlan,
                  compact:
                      compactHeight || breakpoint == BrightBreakpoint.compact,
                ),
              ),
            BrightResponsive(
              maxWidth: 1220,
              padding: EdgeInsets.fromLTRB(
                layout.gutter,
                compactHeight ? 8 : 13,
                layout.gutter,
                compactHeight ? 4 : 7,
              ),
              builder: (context, breakpoint) {
                final compact = breakpoint == BrightBreakpoint.compact;
                final bannerHeight = compactHeight
                    ? 92.0
                    : compact
                        ? 112.0
                        : 128.0;
                return BrightReveal(
                  duration: const Duration(milliseconds: 390),
                  beginScale: 0.985,
                  offset: const Offset(0, -0.025),
                  child: Container(
                    width: double.infinity,
                    height: bannerHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          Color.lerp(color, Colors.black, 0.18)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: -34,
                          top: -10,
                          width: compact ? 190 : 280,
                          child: Opacity(
                            opacity: .34,
                            child: BrightGameScene(
                              gameId: sceneId,
                              compact: compact,
                            ),
                          ),
                        ),
                        Positioned(
                          left: compact ? 12 : 18,
                          top: compactHeight ? 11 : (compact ? 17 : 20),
                          child: _GameMedallion(
                            color: color,
                            emoji: _titleEmoji(title),
                            compact: compact || compactHeight,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            compactHeight
                                ? 78
                                : compact
                                    ? 82
                                    : 104,
                            compactHeight ? 12 : (compact ? 17 : 21),
                            compact ? 68 : 150,
                            compactHeight ? 10 : (compact ? 13 : 18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compactHeight
                                      ? 21
                                      : compact
                                          ? 23
                                          : 30,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x33000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: compact ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .94),
                                  fontSize: compactHeight
                                      ? 10.5
                                      : compact
                                          ? 11
                                          : 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compactHeight)
                          Positioned(
                            right: compact ? 10 : 16,
                            bottom: compact ? 10 : 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .90),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _titleEmoji(title),
                                style: TextStyle(fontSize: compact ? 22 : 27),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (narrationCue != null)
              BrightResponsive(
                maxWidth: 1220,
                padding: EdgeInsets.fromLTRB(
                  layout.gutter,
                  0,
                  layout.gutter,
                  compactHeight ? 3 : 6,
                ),
                builder: (context, breakpoint) => LearningNarrationBar(
                  key: ValueKey<String>('game_audio:${narrationCue.id}'),
                  cue: narrationCue,
                  compact: true,
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.isPhone ? 0 : 6,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameMedallion extends StatelessWidget {
  const _GameMedallion(
      {required this.color, required this.emoji, required this.compact});
  final Color color;
  final String emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: compact ? 58 : 70,
        height: compact ? 58 : 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, Color.lerp(Colors.white, color, .12)!]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))
          ],
        ),
        child: Text(emoji, style: TextStyle(fontSize: compact ? 30 : 38)),
      );
}

String _gameIdFromTitle(String title) {
  final value = title.toLowerCase();
  if (value.contains('math')) return 'math_market';
  if (value.contains('fraction')) return 'fraction_pizza';
  if (value.contains('science')) return 'science_lab';
  if (value.contains('story')) return 'story_builder';
  if (value.contains('grammar')) return 'grammar_puzzle';
  if (value.contains('map')) return 'map_quest';
  if (value.contains('coding')) return 'coding_maze';
  if (value.contains('recycling')) return 'recycling_challenge';
  if (value.contains('reward')) return 'rewards_room';
  return 'rewards_room';
}

String _titleEmoji(String title) {
  final value = title.toLowerCase();
  if (value.contains('math')) return '🛒';
  if (value.contains('fraction')) return '🍕';
  if (value.contains('science')) return '🧪';
  if (value.contains('story')) return '📖';
  if (value.contains('grammar')) return '🧩';
  if (value.contains('map')) return '🧭';
  if (value.contains('coding')) return '🤖';
  if (value.contains('recycling')) return '♻️';
  if (value.contains('reward')) return '🏆';
  return '⭐';
}

class SuccessBanner extends StatelessWidget {
  const SuccessBanner({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => _FeedbackBanner(
        text: text,
        icon: Icons.star_rounded,
        foreground: const Color(0xFF21773B),
        background: const Color(0xFFE7F8E8),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => _FeedbackBanner(
        text: text,
        icon: Icons.favorite_rounded,
        foreground: const Color(0xFF9D4040),
        background: const Color(0xFFFFECEC),
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => _FeedbackBanner(
        text: text,
        icon: icon,
        foreground: const Color(0xFF8A5D00),
        background: const Color(0xFFFFF5D3),
      );
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner(
      {required this.text,
      required this.icon,
      required this.foreground,
      required this.background});
  final String text;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => BrightReveal(
        duration: const Duration(milliseconds: 300),
        beginScale: 0.94,
        offset: const Offset(0, 0.02),
        curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: foreground.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: foreground, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text,
                      style: TextStyle(
                          color: foreground, fontWeight: FontWeight.w800))),
            ],
          ),
        ),
      );
}

class GameProgressStrip extends StatelessWidget {
  const GameProgressStrip(
      {required this.current,
      required this.total,
      required this.score,
      super.key});

  final int current;
  final int total;
  final int score;

  @override
  Widget build(BuildContext context) {
    final value = total <= 0 ? 0.0 : (current / total).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF8F5FF), Color(0xFFEAF5FF)]),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x17163A55), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFFFD63A), Color(0xFFFFAD20)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Step $current of $total',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.navy))),
                    Text('${(value * 100).round()}% Complete',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.purpleDeep,
                            fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: BrightAnimatedProgress(
                    value: value,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFD7DDE8),
                    color: const Color(0xFF72CE36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 7)
                ]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFB91C), size: 18),
                const SizedBox(width: 3),
                BrightValuePop(
                  value: score,
                  child: Text('$score',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppTheme.navy)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameSceneBanner extends StatelessWidget {
  const GameSceneBanner(
      {required this.gameId, required this.caption, this.accent, super.key});

  final String gameId;
  final String caption;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1D173B55), blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BrightGameScene(gameId: gameId),
            const BrightGlint(),
            const BrightSparkles(),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: (accent ?? AppTheme.purple)
                                .withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.auto_awesome_rounded,
                            size: 17, color: accent ?? AppTheme.purple)),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w900,
                                fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class MissionSummaryCard extends StatelessWidget {
  const MissionSummaryCard({
    required this.score,
    required this.maxScore,
    required this.reward,
    required this.onReplay,
    this.learningLevel,
    super.key,
  });

  final int score;
  final int maxScore;
  final MissionReward? reward;
  final VoidCallback onReplay;
  final LearningLevel? learningLevel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = BrightQuestScope.of(context).reducedMotionEnabled;
    final content = learningLevel == null
        ? _GenericMissionSummary(
            score: score,
            maxScore: maxScore,
            reward: reward,
            onReplay: onReplay,
          )
        : _AdventureMissionSummary(
            moment: AdventureRewardEngine.summarize(
              level: learningLevel!,
              reward: reward,
              score: score,
              maxScore: maxScore,
            ),
            reward: reward,
            onReplay: onReplay,
          );

    if (reduceMotion) return content;
    return BrightReveal(
      duration: const Duration(milliseconds: 420),
      beginScale: 0.92,
      offset: const Offset(0, 0.025),
      curve: Curves.easeOutBack,
      child: content,
    );
  }
}

class _AdventureMissionSummary extends StatelessWidget {
  const _AdventureMissionSummary({
    required this.moment,
    required this.reward,
    required this.onReplay,
  });

  final AdventureRewardMoment moment;
  final MissionReward? reward;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final plan = moment.missionPlan;
    final palette = paletteForSubject(plan.identity.subject);
    final feel = GameFeelDirector.forReward(moment);
    final trophy = switch (moment.tier) {
      AdventureRewardTier.worldComplete => '🏆',
      AdventureRewardTier.bossClear => '👑',
      AdventureRewardTier.firstClear => '🚩',
      AdventureRewardTier.starUpgrade => '⭐',
      AdventureRewardTier.clear => '✨',
      AdventureRewardTier.retry => '💪',
    };
    final cleared = moment.cleared;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cleared
              ? [
                  Color.lerp(const Color(0xFFFFF0A8), palette.secondary, .12)!,
                  Color.lerp(const Color(0xFFE2F7FF), palette.secondary, .18)!,
                  const Color(0xFFF3E9FF),
                ]
              : const [Color(0xFFFFF1E6), Color(0xFFF5F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: palette.deep.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (cleared)
                  Center(
                    child: BrightCelebrationBurst(
                      color: palette.primary,
                      particleCount: moment.worldComplete
                          ? 24
                          : moment.bossClear
                              ? 20
                              : 16,
                    ),
                  ),
                const Positioned(left: 5, top: 12, child: BrightSparkles()),
                Positioned(
                  left: 12,
                  bottom: -5,
                  child: SizedBox(
                    width: 100,
                    child: BrightMomentReaction(
                      trigger:
                          'reward:${moment.tier.name}:${moment.levelStars}',
                      kind: feel.kind,
                      child: BrightLionMascot(
                        size: 94,
                        mood: feel.mood,
                        animated: false,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: BrightMomentReaction(
                    trigger: 'trophy:${moment.tier.name}:${moment.levelStars}',
                    kind: feel.kind,
                    child: BrightValuePop(
                      value:
                          moment.levelStars + (moment.worldComplete ? 10 : 0),
                      child: Text(trophy, style: const TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
                if (cleared)
                  Positioned(
                    right: 20,
                    top: 7,
                    child: Text(
                      moment.worldComplete ? '✨🏆✨' : '⭐✨',
                      style: const TextStyle(fontSize: 25),
                    ),
                  ),
              ],
            ),
          ),
          BrightPill(
            icon: plan.isBoss
                ? Icons.workspace_premium_rounded
                : Icons.flag_rounded,
            label: '${plan.zoneTitle} • ${plan.phaseLabel}',
            color: palette.deep,
            background: plan.isBoss
                ? const Color(0xFFFFEDAF)
                : palette.primary.withValues(alpha: .10),
          ),
          const SizedBox(height: 10),
          Text(
            moment.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            moment.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.inkMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              BrightPill(
                icon: Icons.score_rounded,
                label: 'Score ${moment.score} / ${moment.maxScore}',
                color: AppTheme.purple,
              ),
              if (moment.zoneComplete)
                const BrightPill(
                  icon: Icons.workspace_premium_rounded,
                  label: 'ZONE CLEARED',
                  color: Color(0xFF8A6000),
                  background: Color(0xFFFFEDAF),
                ),
              if (moment.worldComplete)
                const BrightPill(
                  icon: Icons.emoji_events_rounded,
                  label: 'WORLD CLEARED',
                  color: Color(0xFF177342),
                  background: Color(0xFFE2F7E5),
                ),
            ],
          ),
          const SizedBox(height: 13),
          if (cleared)
            BrightValuePop(
              value: moment.levelStars,
              child: Text(
                '${List<String>.filled(moment.levelStars, '⭐').join()}'
                '${List<String>.filled(3 - moment.levelStars, '☆').join()}',
                style: const TextStyle(fontSize: 34),
              ),
            )
          else
            Text(
              'Reach this mission’s pass target to clear the checkpoint.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (cleared) ...[
            const SizedBox(height: 12),
            _RewardLootRow(moment: moment),
          ],
          if (moment.nextMissionPlan != null) ...[
            const SizedBox(height: 13),
            BrightMomentReaction(
              trigger: 'unlock:${moment.nextMissionPlan!.levelId}',
              kind: feel.kind,
              child: _AdventureUnlockCard(
                currentPlan: plan,
                nextPlan: moment.nextMissionPlan!,
                palette: palette,
              ),
            ),
          ] else if (moment.worldComplete) ...[
            const SizedBox(height: 13),
            BrightMomentReaction(
              trigger: 'world:${plan.identity.worldTitle}',
              kind: feel.kind,
              child: _WorldCompleteCard(plan: plan, palette: palette),
            ),
          ],
          if (reward != null && reward!.newAchievementIds.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...reward!.newAchievementIds.map((id) {
              final achievement = achievementById(id);
              if (achievement == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFD86B)),
                ),
                child: Text(
                  '${achievement.emoji} Achievement unlocked: ${achievement.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.navy,
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            label: Text(
              cleared
                  ? plan.isBoss
                      ? 'Challenge Boss Again'
                      : 'Replay Mission'
                  : 'Try Again',
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardLootRow extends StatelessWidget {
  const _RewardLootRow({required this.moment});

  final AdventureRewardMoment moment;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 9,
        runSpacing: 9,
        children: [
          _RewardLootToken(
            emoji: '🪙',
            value: '+${moment.coinsAwarded}',
            label: 'coins',
          ),
          _RewardLootToken(
            emoji: '⚡',
            value: '+${moment.xpAwarded}',
            label: 'XP',
          ),
          _RewardLootToken(
            emoji: '⭐',
            value: moment.levelStarsAwarded > 0
                ? '+${moment.levelStarsAwarded}'
                : '${moment.levelStars}/3',
            label: moment.levelStarsAwarded > 0 ? 'new stars' : 'mission stars',
          ),
        ],
      );
}

class _RewardLootToken extends StatelessWidget {
  const _RewardLootToken({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100C3356),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      );
}

class _AdventureUnlockCard extends StatelessWidget {
  const _AdventureUnlockCard({
    required this.currentPlan,
    required this.nextPlan,
    required this.palette,
  });

  final WorldMissionPlan currentPlan;
  final WorldMissionPlan nextPlan;
  final BrightWorldPalette palette;

  @override
  Widget build(BuildContext context) {
    final changedZone = currentPlan.zoneTitle != nextPlan.zoneTitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5FAEA), Color(0xFFF2FFF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB7E8C1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Text(nextPlan.stageEmoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  changedZone ? 'NEW ZONE UNLOCKED' : 'NEXT QUEST UNLOCKED',
                  style: const TextStyle(
                    color: Color(0xFF218739),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${nextPlan.zoneTitle} • ${nextPlan.phaseLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nextPlan.stageTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.lock_open_rounded, color: palette.deep),
        ],
      ),
    );
  }
}

class _WorldCompleteCard extends StatelessWidget {
  const _WorldCompleteCard({required this.plan, required this.palette});

  final WorldMissionPlan plan;
  final BrightWorldPalette palette;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF0B5),
              palette.secondary.withValues(alpha: .34),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9BC42)),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.identity.worldTitle.toUpperCase()} COMPLETE',
                    style: const TextStyle(
                      color: Color(0xFF8A6000),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Every mission is cleared. Missing stars are now your replay challenge!',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GenericMissionSummary extends StatelessWidget {
  const _GenericMissionSummary({
    required this.score,
    required this.maxScore,
    required this.reward,
    required this.onReplay,
  });

  final int score;
  final int maxScore;
  final MissionReward? reward;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore <= 0 ? 0.0 : score / maxScore;
    final cleared = ratio >= .6;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cleared
              ? const [Color(0xFFFFF0A8), Color(0xFFE2F7FF), Color(0xFFF3E9FF)]
              : const [Color(0xFFFFF1E6), Color(0xFFF5F8FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Text(cleared ? '🏆' : '💪', style: const TextStyle(fontSize: 58)),
          const SizedBox(height: 6),
          Text(
            cleared ? 'Mission complete!' : 'Almost there!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          BrightPill(
            icon: Icons.score_rounded,
            label: 'Score $score / $maxScore',
            color: AppTheme.purple,
          ),
          if (reward != null) ...[
            const SizedBox(height: 12),
            Text(
              reward!.firstCompletion
                  ? 'First-clear bonus: +${reward!.coinsAwarded} coins, +${reward!.xpAwarded} XP, +${reward!.starsAwarded} stars'
                  : cleared
                      ? 'Replay reward: +${reward!.coinsAwarded} coins, +${reward!.xpAwarded} XP'
                      : 'Practice run saved. Reach 60% to clear the mission.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.inkMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (reward!.newAchievementIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...reward!.newAchievementIds.map((id) {
                final achievement = achievementById(id);
                if (achievement == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '${achievement.emoji} Achievement unlocked: ${achievement.title}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                    ),
                  ),
                );
              }),
            ],
          ],
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            label: Text(cleared ? 'Play Again' : 'Try Again'),
          ),
        ],
      ),
    );
  }
}
