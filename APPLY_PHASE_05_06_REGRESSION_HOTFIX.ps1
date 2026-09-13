$ErrorActionPreference = "Stop"

$Root = (Get-Location).Path
$HomePath = Join-Path $Root "lib\features\home\home_screen.dart"
$TestPath = Join-Path $Root "test\game_session_resume_safety_test.dart"

if (-not (Test-Path $HomePath)) {
  throw "Missing file: $HomePath"
}
if (-not (Test-Path $TestPath)) {
  throw "Missing file: $TestPath"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$home = [System.IO.File]::ReadAllText($HomePath)
$unusedImport = "import '../../widgets/bright_adaptive.dart';"
if ($home.Contains($unusedImport)) {
  $home = $home.Replace($unusedImport + "`r`n", "")
  $home = $home.Replace($unusedImport + "`n", "")
  [System.IO.File]::WriteAllText($HomePath, $home, $Utf8NoBom)
  Write-Host "Removed unused bright_adaptive import."
} else {
  Write-Host "Unused import already absent."
}

$test = [System.IO.File]::ReadAllText($TestPath)
$old = @'
      final adventuresSource =
          File('lib/features/adventures/adventures_screen.dart')
              .readAsStringSync();
      expect(adventuresSource, contains('controller.resumableGameSessions'));
      expect(adventuresSource, contains('resumeGameSession(context, session)'));
      expect(
          adventuresSource, contains('controller.discardGameSession(session)'));
'@
$new = @'
      final homeSource =
          File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(homeSource, contains('controller.resumableGameSessions'));
      expect(homeSource, contains('resumeGameSession(context, session)'));

      final adventuresSource =
          File('lib/features/adventures/adventures_screen.dart')
              .readAsStringSync();
      expect(adventuresSource, contains('controller.resumableGameSessions'));
      expect(
        adventuresSource,
        isNot(contains('resumeGameSession(context, session)')),
      );

      final worldSource =
          File('lib/features/adventures/learning_world_screen.dart')
              .readAsStringSync();
      expect(worldSource, contains('resumeGameSession(context, session)'));
      expect(
        worldSource,
        contains('onDiscardSaved: controller.discardGameSession'),
      );
'@

if ($test.Contains($new.TrimEnd())) {
  Write-Host "Resume ownership regression block already migrated."
} elseif ($test.Contains($old.TrimEnd())) {
  $test = $test.Replace($old.TrimEnd(), $new.TrimEnd())
  [System.IO.File]::WriteAllText($TestPath, $test, $Utf8NoBom)
  Write-Host "Migrated Step 10 resume ownership assertions."
} else {
  throw "Expected old Step 10 assertion block was not found. Refusing to patch an unknown file state."
}

Write-Host ""
Write-Host "Hotfix applied. Run:"
Write-Host "  dart format lib\features\home\home_screen.dart test\game_session_resume_safety_test.dart"
Write-Host "  flutter analyze"
Write-Host "  flutter test test\game_session_resume_safety_test.dart"
Write-Host "  flutter test"
