$ErrorActionPreference = "Stop"

$RepoRoot = (Get-Location).Path
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Normalize-Lf([string]$Text) {
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Read-Normalized([string]$RelativePath) {
    $Path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $Path)) {
        throw "Missing required file: $RelativePath"
    }
    return Normalize-Lf ([System.IO.File]::ReadAllText($Path))
}

function Replace-Required(
    [string]$Text,
    [string]$Old,
    [string]$New,
    [string]$Label
) {
    $OldValue = (Normalize-Lf $Old).TrimEnd()
    $NewValue = (Normalize-Lf $New).TrimEnd()

    if ($Text.Contains($NewValue)) {
        Write-Host "Already applied: $Label"
        return $Text
    }
    if (-not $Text.Contains($OldValue)) {
        throw "Cannot apply '$Label': expected source block was not found."
    }
    Write-Host "Prepared: $Label"
    return $Text.Replace($OldValue, $NewValue)
}

$ProgressPath = "lib\core\models\progress_models.dart"
$ControllerPath = "lib\core\state\game_controller.dart"
$WidgetsPath = "lib\widgets\bright_widgets.dart"
$RouterPath = "lib\features\games\game_router.dart"
$ParentPath = "lib\features\parent\parent_dashboard_screen.dart"
$NurseryHomePath = "lib\features\nursery\nursery_home_screen.dart"

$ProgressText = Read-Normalized $ProgressPath
$ControllerText = Read-Normalized $ControllerPath
$WidgetsText = Read-Normalized $WidgetsPath
$RouterText = Read-Normalized $RouterPath
$ParentText = Read-Normalized $ParentPath
$NurseryHomeText = Read-Normalized $NurseryHomePath

# ---------------------------------------------------------------------------
# 1) Persisted learner stage on ChildProfileSnapshot.
# ---------------------------------------------------------------------------

$OldBlock = @'
import '../nursery/nursery_learning_models.dart';
'@
$NewBlock = @'
import '../nursery/nursery_learning_models.dart';
import 'learner_stage.dart';
'@
$ProgressText = Replace-Required $ProgressText $OldBlock $NewBlock "progress_models import LearnerStage"

$OldBlock = @'
    this.avatarEmoji = '🧒',
    this.selectedClass = 4,
'@
$NewBlock = @'
    this.avatarEmoji = '🧒',
    this.learnerStage = LearnerStage.school,
    this.selectedClass = 4,
'@
$ProgressText = Replace-Required $ProgressText $OldBlock $NewBlock "ChildProfileSnapshot constructor learnerStage"

$OldBlock = @'
  String id;
  String name;
  String avatarEmoji;
  int selectedClass;
'@
$NewBlock = @'
  String id;
  String name;
  String avatarEmoji;
  LearnerStage learnerStage;
  int selectedClass;
'@
$ProgressText = Replace-Required $ProgressText $OldBlock $NewBlock "ChildProfileSnapshot learnerStage field"

$OldBlock = @'
        'avatarEmoji': avatarEmoji,
        'selectedClass': selectedClass,
'@
$NewBlock = @'
        'avatarEmoji': avatarEmoji,
        'learnerStage': learnerStage.name,
        'selectedClass': selectedClass,
'@
$ProgressText = Replace-Required $ProgressText $OldBlock $NewBlock "ChildProfileSnapshot learnerStage serialization"

$OldBlock = @'
      avatarEmoji: json['avatarEmoji'] as String? ?? '🧒',
      selectedClass: (json['selectedClass'] as num?)?.toInt() ?? 4,
'@
$NewBlock = @'
      avatarEmoji: json['avatarEmoji'] as String? ?? '🧒',
      learnerStage: learnerStageFromStorage(json['learnerStage']),
      selectedClass: (json['selectedClass'] as num?)?.toInt() ?? 4,
'@
$ProgressText = Replace-Required $ProgressText $OldBlock $NewBlock "ChildProfileSnapshot learnerStage migration"

# ---------------------------------------------------------------------------
# 2) GameController owns the active learner stage without changing class IDs.
# ---------------------------------------------------------------------------

$OldBlock = @'
import '../models/game_models.dart';
import '../models/progress_models.dart';
'@
$NewBlock = @'
import '../models/game_models.dart';
import '../models/learner_stage.dart';
import '../models/progress_models.dart';
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "GameController LearnerStage import"

$OldBlock = @'
  int get streak => _profile.streak;
  int get selectedClass => _profile.selectedClass;
  int get xp => _profile.xp;
'@
$NewBlock = @'
  int get streak => _profile.streak;
  int get selectedClass => _profile.selectedClass;
  LearnerStage get learnerStage => _profile.learnerStage;
  bool get isNurseryLearner => learnerStage == LearnerStage.nursery;
  int get xp => _profile.xp;
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "GameController learnerStage getters"

$OldBlock = @'
  void setClass(int value) {
    if (value < 3 || value > 5 || value == _profile.selectedClass) return;
    _foregroundSessionKeys.remove(activeProfileId);
    _profile.selectedClass = value;
    _changed();
  }

  void setSoundEnabled(bool value) {
'@
$NewBlock = @'
  void setClass(int value) {
    if (value < 3 || value > 5 || value == _profile.selectedClass) return;
    _foregroundSessionKeys.remove(activeProfileId);
    _profile.selectedClass = value;
    _changed();
  }

  void setLearnerStage(LearnerStage value) {
    if (_profile.learnerStage == value) return;
    _foregroundSessionKeys.remove(activeProfileId);
    _profile.learnerStage = value;
    if (value == LearnerStage.nursery) {
      _profile.nurseryLearning = _nurseryProgress.refreshReviewStates(
        _profile.nurseryLearning,
        DateTime.now(),
      );
    }
    _changed();
  }

  void setSoundEnabled(bool value) {
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "GameController setLearnerStage"

$OldBlock = @'
  String createProfile({
    required String name,
    required int classNumber,
    String avatarEmoji = '🧒',
  }) {
'@
$NewBlock = @'
  String createProfile({
    required String name,
    required int classNumber,
    LearnerStage learnerStage = LearnerStage.school,
    String avatarEmoji = '🧒',
  }) {
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "createProfile learnerStage parameter"

$OldBlock = @'
      name: trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed,
      avatarEmoji: avatarEmoji,
      selectedClass: normalizedClass,
'@
$NewBlock = @'
      name: trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed,
      avatarEmoji: avatarEmoji,
      learnerStage: learnerStage,
      selectedClass: normalizedClass,
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "createProfile learnerStage persistence"

$OldBlock = @'
    _profile.learning = _learningProgress.refreshReviewStates(
      _profile.learning,
      DateTime.now(),
    );
    _changed();
    return true;
'@
$NewBlock = @'
    _profile.learning = _learningProgress.refreshReviewStates(
      _profile.learning,
      DateTime.now(),
    );
    _profile.nurseryLearning = _nurseryProgress.refreshReviewStates(
      _profile.nurseryLearning,
      DateTime.now(),
    );
    _changed();
    return true;
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "switchProfile refreshes Nursery review state"

$OldBlock = @'
      name: current.name,
      avatarEmoji: current.avatarEmoji,
      selectedClass: current.selectedClass,
'@
$NewBlock = @'
      name: current.name,
      avatarEmoji: current.avatarEmoji,
      learnerStage: current.learnerStage,
      selectedClass: current.selectedClass,
'@
$ControllerText = Replace-Required $ControllerText $OldBlock $NewBlock "resetProgress preserves learnerStage"

# ---------------------------------------------------------------------------
# 3) Nursery Home can be mounted as the actual root learner shell.
# ---------------------------------------------------------------------------

$OldBlock = @'
class NurseryHomeScreen extends StatelessWidget {
  const NurseryHomeScreen({super.key});

  @override
'@
$NewBlock = @'
class NurseryHomeScreen extends StatelessWidget {
  const NurseryHomeScreen({
    this.rootMode = false,
    this.onOpenGrownUpArea,
    super.key,
  });

  final bool rootMode;
  final VoidCallback? onOpenGrownUpArea;

  @override
'@
$NurseryHomeText = Replace-Required $NurseryHomeText $OldBlock $NewBlock "NurseryHomeScreen root-mode contract"

$OldBlock = @'
            BrightHeader(
              showBack: true,
              title: 'Nursery Learning Garden',
              trailing: IconButton(
                tooltip: 'Hear welcome',
                onPressed: () => unawaited(
                  BrightAudioService.instance.speak(
                    'Welcome to Nursery Play. Tap the big play button, or choose a world.',
                    manual: true,
                  ),
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ),
'@
$NewBlock = @'
            BrightHeader(
              showBack: !rootMode,
              title: 'Nursery Learning Garden',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Hear welcome',
                    onPressed: () => unawaited(
                      BrightAudioService.instance.speak(
                        'Welcome to Nursery Play. Tap the big play button, or choose a world.',
                        manual: true,
                      ),
                    ),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                  if (rootMode && onOpenGrownUpArea != null)
                    IconButton(
                      key: const Key('nursery_grown_up_area'),
                      tooltip: 'Grown-up area',
                      onPressed: onOpenGrownUpArea,
                      icon: const Icon(Icons.supervisor_account_rounded),
                    ),
                ],
              ),
            ),
'@
$NurseryHomeText = Replace-Required $NurseryHomeText $OldBlock $NewBlock "Nursery root header and grown-up boundary"

# ---------------------------------------------------------------------------
# 4) Parent area chooses Nursery vs School explicitly; no fake class number.
# ---------------------------------------------------------------------------

$OldBlock = @'
import '../../core/models/game_models.dart';
import '../../core/models/progress_models.dart';
'@
$NewBlock = @'
import '../../core/models/game_models.dart';
import '../../core/models/learner_stage.dart';
import '../../core/models/progress_models.dart';
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Parent Dashboard LearnerStage import"

$OldBlock = @'
                '${controller.activeProfileAvatar} ${controller.activeProfileName} • Class ${controller.selectedClass}',
'@
$NewBlock = @'
                '${controller.activeProfileAvatar} ${controller.activeProfileName} • ${controller.isNurseryLearner ? 'Nursery' : 'Class ${controller.selectedClass}'}',
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Parent active learner stage label"

$OldBlock = @'
                      DropdownButtonFormField<int>(
                        key: ValueKey<String>(
                            'class-${controller.activeProfileId}'),
                        initialValue: controller.selectedClass,
                        decoration:
                            const InputDecoration(labelText: 'School class'),
                        items: const [3, 4, 5]
                            .map((value) => DropdownMenuItem<int>(
                                value: value, child: Text('Class $value')))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) controller.setClass(value);
                        },
                      ),
'@
$NewBlock = @'
                      DropdownButtonFormField<LearnerStage>(
                        key: ValueKey<String>(
                            'stage-${controller.activeProfileId}'),
                        initialValue: controller.learnerStage,
                        decoration:
                            const InputDecoration(labelText: 'Learning stage'),
                        items: const [
                          DropdownMenuItem<LearnerStage>(
                            value: LearnerStage.nursery,
                            child: Text('Nursery'),
                          ),
                          DropdownMenuItem<LearnerStage>(
                            value: LearnerStage.school,
                            child: Text('School'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.setLearnerStage(value);
                          }
                        },
                      ),
                      if (!controller.isNurseryLearner) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          key: ValueKey<String>(
                              'class-${controller.activeProfileId}'),
                          initialValue: controller.selectedClass,
                          decoration:
                              const InputDecoration(labelText: 'School class'),
                          items: const [3, 4, 5]
                              .map((value) => DropdownMenuItem<int>(
                                  value: value, child: Text('Class $value')))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) controller.setClass(value);
                          },
                        ),
                      ],
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Parent stage selector"

$OldBlock = @'
                  label: Text('${profile.name} • C${profile.selectedClass}'),
'@
$NewBlock = @'
                  label: Text(
                    profile.learnerStage == LearnerStage.nursery
                        ? '${profile.name} • Nursery'
                        : '${profile.name} • C${profile.selectedClass}',
                  ),
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Profile chip stage label"

$OldBlock = @'
    final nameController = TextEditingController();
    var classNumber = 3;
    var avatar = '🧒';
'@
$NewBlock = @'
    final nameController = TextEditingController();
    var learnerStage = LearnerStage.school;
    var classNumber = 3;
    var avatar = '🧒';
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Add-profile learnerStage state"

$OldBlock = @'
                DropdownButtonFormField<int>(
                  initialValue: classNumber,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: const [3, 4, 5]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('Class $value')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null)
                      setDialogState(() => classNumber = value);
                  },
                ),
'@
$NewBlock = @'
                DropdownButtonFormField<LearnerStage>(
                  initialValue: learnerStage,
                  decoration:
                      const InputDecoration(labelText: 'Learning stage'),
                  items: const [
                    DropdownMenuItem<LearnerStage>(
                      value: LearnerStage.nursery,
                      child: Text('Nursery'),
                    ),
                    DropdownMenuItem<LearnerStage>(
                      value: LearnerStage.school,
                      child: Text('School'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => learnerStage = value);
                    }
                  },
                ),
                if (learnerStage == LearnerStage.school) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: classNumber,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: const [3, 4, 5]
                        .map((value) => DropdownMenuItem(
                            value: value, child: Text('Class $value')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => classNumber = value);
                      }
                    },
                  ),
                ],
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Add-profile stage and school-class selector"

$OldBlock = @'
      final id = controller.createProfile(
          name: nameController.text,
          classNumber: classNumber,
          avatarEmoji: avatar);
'@
$NewBlock = @'
      final id = controller.createProfile(
        name: nameController.text,
        classNumber: classNumber,
        learnerStage: learnerStage,
        avatarEmoji: avatar,
      );
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Add-profile learnerStage creation"

# Nursery parent view must not expose the preserved School class analytics as
# though they were Nursery progress.
$OldBlock = @'
                      const SizedBox(height: 10),
                      _Row(
                          label: 'Level / XP',
                          value:
                              'Lv ${controller.level} • ${controller.xp} XP'),
                      _Row(label: 'All-time accuracy', value: '$accuracy%'),
                      _Row(
                        label: 'Today',
                        value:
                            '${controller.correctToday}/${controller.answersToday} correct ($dailyAccuracy%)',
                      ),
                      _Row(
                          label: 'Learning streak',
                          value: '${controller.streak} days'),
                      _Row(
                        label: 'Study time today',
                        value: '${controller.studyMinutesToday.floor()} min',
                      ),
'@
$NewBlock = @'
                      const SizedBox(height: 10),
                      if (controller.isNurseryLearner) ...[
                        _Row(
                          label: 'Nursery activities recorded',
                          value: '${controller.nurseryAttemptEvidence.length}',
                        ),
                        _Row(
                          label: 'Review ready',
                          value:
                              '${controller.dueNurseryReviewTasks(limit: 50).length}',
                        ),
                      ] else ...[
                        _Row(
                          label: 'Level / XP',
                          value:
                              'Lv ${controller.level} • ${controller.xp} XP',
                        ),
                        _Row(
                          label: 'All-time accuracy',
                          value: '$accuracy%',
                        ),
                        _Row(
                          label: 'Today',
                          value:
                              '${controller.correctToday}/${controller.answersToday} correct ($dailyAccuracy%)',
                        ),
                        _Row(
                          label: 'Learning streak',
                          value: '${controller.streak} days',
                        ),
                        _Row(
                          label: 'Study time today',
                          value: '${controller.studyMinutesToday.floor()} min',
                        ),
                      ],
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Nursery parent summary"

$OldBlock = @'
              const SizedBox(height: 18),
              const Text(
                'Class adventure map',
'@
$NewBlock = @'
              if (!controller.isNurseryLearner) ...[
                const SizedBox(height: 18),
                const Text(
                  'Class adventure map',
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Hide School analytics start for Nursery"

$OldBlock = @'
              const SizedBox(height: 18),
              const Text(
                'Reading & accessibility',
'@
$NewBlock = @'
              ],
              const SizedBox(height: 18),
              const Text(
                'Reading & accessibility',
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Hide School analytics end for Nursery"

$OldBlock = @'
              const SizedBox(height: 18),
              _DailyChallengeOverview(controller: controller),
'@
$NewBlock = @'
              if (!controller.isNurseryLearner) ...[
                const SizedBox(height: 18),
                _DailyChallengeOverview(controller: controller),
              ],
'@
$ParentText = Replace-Required $ParentText $OldBlock $NewBlock "Hide School daily challenges for Nursery"

# ---------------------------------------------------------------------------
# 5) Shared mission result: Continue is primary, Replay becomes secondary.
# ---------------------------------------------------------------------------

$OldBlock = @'
import '../core/models/progress_models.dart';
import '../core/presentation/game_feel_director.dart';
'@
$NewBlock = @'
import '../core/models/progress_models.dart';
import '../core/presentation/game_feel_director.dart';
import '../core/session/learning_session_exit.dart';
'@
$WidgetsText = Replace-Required $WidgetsText $OldBlock $NewBlock "Mission summary LearningSessionExit import"

$OldBlock = @'
                  title == null
                      ? 'Class ${controller.selectedClass}  ▾'
                      : 'Learn • Play • Grow',
'@
$NewBlock = @'
                  title == null
                      ? controller.isNurseryLearner
                          ? 'Nursery'
                          : 'Class ${controller.selectedClass}'
                      : 'Learn • Play • Grow',
'@
$WidgetsText = Replace-Required $WidgetsText $OldBlock $NewBlock "Header learner-stage label and false affordance removal"

$OldBlock = @'
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
'@
$NewBlock = @'
          const SizedBox(height: 16),
          if (cleared) ...[
            FilledButton.icon(
              key: const Key('mission_continue_button'),
              onPressed: () {
                final nextLevelId = moment.nextMissionPlan?.levelId;
                Navigator.of(context).pop<LearningSessionExit>(
                  nextLevelId == null
                      ? LearningSessionExit.backToWorld
                      : LearningSessionExit.continueToLevel(nextLevelId),
                );
              },
              icon: Icon(
                moment.nextMissionPlan == null
                    ? Icons.map_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                moment.nextMissionPlan == null
                    ? moment.worldComplete
                        ? 'Back to Worlds'
                        : 'Back to World'
                    : 'Continue',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('mission_replay_button'),
              onPressed: onReplay,
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                plan.isBoss ? 'Challenge Boss Again' : 'Replay Mission',
              ),
            ),
          ] else
            FilledButton.icon(
              key: const Key('mission_try_again_button'),
              onPressed: onReplay,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Again'),
            ),
'@
$WidgetsText = Replace-Required $WidgetsText $OldBlock $NewBlock "Mission result Continue/Replay hierarchy"

# ---------------------------------------------------------------------------
# 6) Router consumes the exact next-level ID from the result surface.
# ---------------------------------------------------------------------------

$OldBlock = @'
import '../../core/session/game_session_models.dart';
'@
$NewBlock = @'
import '../../core/session/game_session_models.dart';
import '../../core/session/learning_session_exit.dart';
'@
$RouterText = Replace-Required $RouterText $OldBlock $NewBlock "game_router LearningSessionExit import"

$OldBlock = @'
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => routedScreen))
      .whenComplete(() {
    unawaited(audio.stopVoice());
    final finishedSession = controller.gameSessionFor(
      gameId: id,
      classNumber: classNumber,
      learningLevelId: learningLevel?.id,
    );
    if (finishedSession?.stage == GameSessionStage.result) {
      controller.discardGameSession(finishedSession!);
    }
    if (controller.soundEnabled) {
      unawaited(audio.playMenuMusic(restart: true));
    }
  });
'@
$NewBlock = @'
  Navigator.of(context)
      .push<LearningSessionExit>(
        MaterialPageRoute<LearningSessionExit>(builder: (_) => routedScreen),
      )
      .then((exit) {
    unawaited(audio.stopVoice());
    final finishedSession = controller.gameSessionFor(
      gameId: id,
      classNumber: classNumber,
      learningLevelId: learningLevel?.id,
    );
    if (finishedSession?.stage == GameSessionStage.result) {
      controller.discardGameSession(finishedSession!);
    }
    if (controller.soundEnabled) {
      unawaited(audio.playMenuMusic(restart: true));
    }

    final nextLevelId = exit?.nextLevelId;
    final nextLevel =
        nextLevelId == null ? null : learningLevelById(nextLevelId);
    if (exit?.action == LearningSessionExitAction.continueNext &&
        nextLevel != null &&
        nextLevel.classNumber == controller.selectedClass &&
        controller.isLevelUnlocked(nextLevel) &&
        context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        openLearningLevel(context, nextLevel);
      });
    }
  });
'@
$RouterText = Replace-Required $RouterText $OldBlock $NewBlock "game_router typed result continuation"

# ---------------------------------------------------------------------------
# All source contracts validated. Write only now, so failure above is atomic.
# ---------------------------------------------------------------------------

$Writes = @{
    $ProgressPath = $ProgressText
    $ControllerPath = $ControllerText
    $WidgetsPath = $WidgetsText
    $RouterPath = $RouterText
    $ParentPath = $ParentText
    $NurseryHomePath = $NurseryHomeText
}

foreach ($RelativePath in $Writes.Keys) {
    $Path = Join-Path $RepoRoot $RelativePath
    [System.IO.File]::WriteAllText($Path, $Writes[$RelativePath], $Utf8NoBom)
}

Write-Host ""
Write-Host "Phase 7+8 production patch applied successfully."
Write-Host "No numeric Nursery class was introduced."
Write-Host "Run the qualification commands from PHASE_07_08_QA.md."
