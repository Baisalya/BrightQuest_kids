import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/brightquest_scope.dart';
import '../../core/services/bright_audio_service.dart';
import 'parent_section_scaffold.dart';

class ParentAudioSettingsScreen extends StatelessWidget {
  const ParentAudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BrightQuestScope.of(context);
    final audio = BrightAudioService.instance;

    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        final appAudioActive = audio.appAudioEnabled;
        return ParentSectionScaffold(
          title: 'Audio & narration',
          subtitle:
              'Control device-wide music, game sounds and the learning narrator from one place. Child-level audio permission stays separate.',
          icon: Icons.volume_up_rounded,
          children: [
            ParentSectionCard(
              key: const Key('app_wide_audio_controls'),
              title: 'App-wide audio',
              subtitle:
                  'Applies to Home, Nursery, Rewards and every game on this device.',
              icon: Icons.surround_sound_rounded,
              trailing: Switch(
                key: const Key('app_audio_master'),
                value: audio.appAudioEnabled,
                onChanged: audio.setAppAudioEnabled,
              ),
              child: Text(
                appAudioActive
                    ? 'On. Individual music, sound-effect and narrator channels can be adjusted below.'
                    : 'Muted. Background music, game sounds and narration are disabled across the complete app.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            ParentSectionCard(
              title: 'Learner audio permission',
              subtitle:
                  'Profile-level permission for ${controller.activeProfileName}. Device-wide controls below still take priority.',
              icon: Icons.person_rounded,
              trailing: Switch(
                key: const Key('profile_audio_permission'),
                value: controller.soundEnabled,
                onChanged: (value) {
                  controller.setSoundEnabled(value);
                  unawaited(audio.setSessionEnabled(value));
                },
              ),
              child: Text(
                controller.soundEnabled
                    ? 'This learner may hear enabled audio channels.'
                    : 'Audio is disabled for this learner even when app-wide audio is on.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            _AudioExpansionCard(
              icon: Icons.music_note_rounded,
              title: 'Background music',
              status: audio.musicEnabled ? 'On' : 'Muted',
              initiallyExpanded: true,
              trailing: Switch(
                key: const Key('app_bgm_mute'),
                value: audio.musicEnabled,
                onChanged: appAudioActive ? audio.setMusicEnabled : null,
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'Home keeps its explorer music; each gameplay area and Nursery use their own multi-section BGM identity.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ),
                ListTile(
                  key: const Key('app_bgm_volume'),
                  title: Text(
                    'BGM music volume ${(audio.musicVolume * 100).round()}%',
                  ),
                  subtitle: Slider(
                    value: audio.musicVolume,
                    min: 0,
                    max: 0.55,
                    onChanged: appAudioActive && audio.musicEnabled
                        ? audio.setMusicVolume
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AudioExpansionCard(
              icon: Icons.sports_esports_rounded,
              title: 'Game sound effects',
              status: audio.sfxEnabled ? 'On' : 'Muted',
              trailing: Switch(
                key: const Key('app_sfx_mute'),
                value: audio.sfxEnabled,
                onChanged: appAudioActive ? audio.setSfxEnabled : null,
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'Game-specific taps, option choices, actions and answer feedback are separate from the gentler Nursery sound profile.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ),
                ListTile(
                  key: const Key('app_sfx_volume'),
                  title: Text(
                    'Game sound effects volume ${(audio.sfxVolume * 100).round()}%',
                  ),
                  subtitle: Slider(
                    value: audio.sfxVolume,
                    min: 0,
                    max: 1,
                    onChanged: appAudioActive && audio.sfxEnabled
                        ? audio.setSfxVolume
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AudioExpansionCard(
              icon: Icons.record_voice_over_rounded,
              title: 'Narrator & read aloud',
              status: !audio.voiceAvailable
                  ? 'Unavailable'
                  : audio.voiceEnabled
                      ? 'On'
                      : 'Muted',
              trailing: Switch(
                key: const Key('app_narrator_mute'),
                value: audio.voiceAvailable && audio.voiceEnabled,
                onChanged: appAudioActive && audio.voiceAvailable
                    ? audio.setVoiceEnabled
                    : null,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    audio.voiceAvailable
                        ? 'Smart read speaks questions, choices and answer feedback. Manual read-aloud remains available when narration is enabled.'
                        : 'Install a Windows speech voice to enable narration.',
                    style: const TextStyle(color: Colors.black54, height: 1.4),
                  ),
                ),
                if (audio.availableVoices.isNotEmpty)
                  ListTile(
                    title: const Text('Narration voice'),
                    subtitle: DropdownButton<String>(
                      key: const Key('guide_voice_selector'),
                      isExpanded: true,
                      value: audio.selectedVoiceId,
                      hint: const Text('Choose a voice'),
                      items: [
                        for (final voice in audio.availableVoices)
                          DropdownMenuItem<String>(
                            value: voice.id,
                            child: Text(
                              voice.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: appAudioActive && audio.voiceEnabled
                          ? (value) {
                              if (value != null) {
                                unawaited(audio.setVoice(value));
                              }
                            }
                          : null,
                    ),
                    trailing: audio.selectedVoice?.isFemale == true
                        ? const Tooltip(
                            message: 'Female voice selected by default',
                            child: Icon(
                              Icons.woman_2_rounded,
                              color: Color(0xFFF0549B),
                            ),
                          )
                        : null,
                  ),
                SwitchListTile(
                  title: const Text('Automatic learning narration'),
                  subtitle: const Text(
                    'Reads lesson steps automatically and keeps game introductions spoken. Read-aloud buttons remain manual.',
                  ),
                  value: audio.autoNarrationEnabled,
                  onChanged: appAudioActive &&
                          audio.voiceAvailable &&
                          audio.voiceEnabled
                      ? audio.setAutoNarrationEnabled
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Cheerful voice feedback'),
                  subtitle: const Text(
                    'Short praise and encouragement after answers.',
                  ),
                  value: audio.voiceFeedbackEnabled,
                  onChanged: appAudioActive &&
                          audio.voiceAvailable &&
                          audio.voiceEnabled
                      ? audio.setVoiceFeedbackEnabled
                      : null,
                ),
                ListTile(
                  key: const Key('app_narrator_volume'),
                  title: Text(
                    'Speech narration volume ${(audio.voiceVolume * 100).round()}%',
                  ),
                  subtitle: Slider(
                    value: audio.voiceVolume,
                    min: 0,
                    max: 1,
                    onChanged: appAudioActive &&
                            audio.voiceAvailable &&
                            audio.voiceEnabled
                        ? audio.setVoiceVolume
                        : null,
                  ),
                  trailing: IconButton(
                    tooltip: 'Test guide voice',
                    onPressed: appAudioActive &&
                            controller.soundEnabled &&
                            audio.voiceAvailable &&
                            audio.voiceEnabled
                        ? audio.testVoice
                        : null,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Guide speed ${(audio.voiceRate * 100).round()}%',
                  ),
                  subtitle: Slider(
                    value: audio.voiceRate,
                    min: 0.30,
                    max: 0.62,
                    divisions: 8,
                    onChanged: appAudioActive &&
                            audio.voiceAvailable &&
                            audio.voiceEnabled
                        ? audio.setVoiceRate
                        : null,
                  ),
                ),
                ListTile(
                  title: Text(
                    audio.voicePitchAvailable
                        ? 'Guide tone ${(audio.voicePitch * 100).round()}%'
                        : 'Guide tone (Android only)',
                  ),
                  subtitle: Slider(
                    value: audio.voicePitch,
                    min: 0.80,
                    max: 1.30,
                    divisions: 10,
                    onChanged: appAudioActive &&
                            audio.voiceAvailable &&
                            audio.voiceEnabled &&
                            audio.voicePitchAvailable
                        ? audio.setVoicePitch
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AudioExpansionCard extends StatelessWidget {
  const _AudioExpansionCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.trailing,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String status;
  final Widget trailing;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: const Color(0xFF415F8F)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(status),
          trailing: trailing,
          children: children,
        ),
      );
}
