import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import 'parent_section_scaffold.dart';

class ParentHealthyPlayScreen extends StatelessWidget {
  const ParentHealthyPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);

    return ParentSectionScaffold(
      title: 'Healthy play',
      subtitle:
          'Keep learning sessions balanced with a daily limit, a realistic goal and parent-controlled reminders.',
      icon: Icons.health_and_safety_rounded,
      children: [
        ParentSectionCard(
          title: 'Daily time limit',
          subtitle: controller.timeLimitEnabled
              ? 'Games pause after ${controller.dailyTimeLimitMinutes} minutes of active learning-game time.'
              : 'Off. Learning games are not time-blocked.',
          icon: Icons.timer_rounded,
          trailing: Switch(
            key: const Key('parent_daily_time_limit_switch'),
            value: controller.timeLimitEnabled,
            onChanged: controller.setTimeLimitEnabled,
          ),
          child: controller.timeLimitEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${controller.studyMinutesToday.floor()} min used today',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        Text(
                          '${controller.dailyTimeLimitMinutes} min limit',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Slider(
                      key: const Key('parent_daily_time_limit_slider'),
                      value: controller.dailyTimeLimitMinutes.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      label: '${controller.dailyTimeLimitMinutes} min',
                      onChanged: (value) =>
                          controller.setDailyTimeLimitMinutes(value.round()),
                    ),
                  ],
                )
              : const Text(
                  'Turn the limit on when you want BrightQuest to stop active game time automatically for the day.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
        ),
        const SizedBox(height: 14),
        ParentSectionCard(
          title: 'Daily learning goal',
          subtitle:
              'A positive target for learning time. This does not lock the app.',
          icon: Icons.flag_circle_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${controller.dailyMinutesGoal} min',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Slider(
                key: const Key('parent_daily_goal_slider'),
                value: controller.dailyMinutesGoal.toDouble(),
                min: 10,
                max: 60,
                divisions: 10,
                label: '${controller.dailyMinutesGoal} min',
                onChanged: (value) =>
                    controller.setDailyMinutesGoal(value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ParentSectionCard(
          title: 'Learning reminders',
          subtitle:
              'The preference is saved locally. OS notification scheduling is not enabled yet.',
          icon: Icons.notifications_active_rounded,
          trailing: Switch(
            key: const Key('parent_learning_reminders_switch'),
            value: controller.remindersEnabled,
            onChanged: controller.setRemindersEnabled,
          ),
          child: const Text(
            'This control is kept separate from time limits so reminders can be managed without changing play restrictions.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ),
      ],
    );
  }
}
