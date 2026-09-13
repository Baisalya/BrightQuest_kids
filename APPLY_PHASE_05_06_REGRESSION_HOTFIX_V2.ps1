$ErrorActionPreference = "Stop"

$RepoRoot = (Get-Location).Path
$HomePath = Join-Path $RepoRoot "lib\features\home\home_screen.dart"
$TestPath = Join-Path $RepoRoot "test\game_session_resume_safety_test.dart"

if (-not (Test-Path $HomePath)) {
    throw "Missing file: $HomePath"
}
if (-not (Test-Path $TestPath)) {
    throw "Missing file: $TestPath"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Analyzer cleanup. IMPORTANT: use $HomeText, never $home because PowerShell
# variable names are case-insensitive and $HOME is a built-in read-only value.
$HomeText = [System.IO.File]::ReadAllText($HomePath)
$UnusedImport = "import '../../widgets/bright_adaptive.dart';"

if ($HomeText.Contains($UnusedImport)) {
    $HomeText = $HomeText.Replace($UnusedImport + "`r`n", "")
    $HomeText = $HomeText.Replace($UnusedImport + "`n", "")
    [System.IO.File]::WriteAllText($HomePath, $HomeText, $Utf8NoBom)
    Write-Host "Removed unused bright_adaptive import."
} else {
    Write-Host "Unused import already absent."
}

$TestText = [System.IO.File]::ReadAllText($TestPath)

$OldBlock = @'
      final adventuresSource =
          File('lib/features/adventures/adventures_screen.dart')
              .readAsStringSync();
      expect(adventuresSource, contains('controller.resumableGameSessions'));
      expect(adventuresSource, contains('resumeGameSession(context, session)'));
      expect(
          adventuresSource, contains('controller.discardGameSession(session)'));
'@.Trim()

$NewBlock = @'
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
'@.Trim()

if ($TestText.Contains($NewBlock)) {
    Write-Host "Step 10 resume ownership assertions already migrated."
} elseif ($TestText.Contains($OldBlock)) {
    $TestText = $TestText.Replace($OldBlock, $NewBlock)
    [System.IO.File]::WriteAllText($TestPath, $TestText, $Utf8NoBom)
    Write-Host "Migrated Step 10 resume ownership assertions."
} else {
    throw "Expected old Step 10 assertion block was not found. No test file changes were made."
}

Write-Host ""
Write-Host "Phase 5+6 regression hotfix v2 applied."
Write-Host "Run:"
Write-Host "  dart format lib\features\home\home_screen.dart test\game_session_resume_safety_test.dart"
Write-Host "  flutter analyze"
Write-Host "  flutter test test\game_session_resume_safety_test.dart"
Write-Host "  flutter test"
