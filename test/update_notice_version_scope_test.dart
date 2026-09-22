import 'dart:io';

import 'package:brightquest_kids/app/brightquest_app.dart';
import 'package:brightquest_kids/core/services/app_distribution_info.dart';
import 'package:brightquest_kids/core/services/update_notice_service.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_fixture.dart';

void main() {
  test('suppressing one update never suppresses a newer update', () {
    expect(
      UpdateNoticePolicy.shouldShow(
        currentNoticeId: '0.6.0+26',
        suppressedNoticeId: null,
      ),
      isTrue,
    );
    expect(
      UpdateNoticePolicy.shouldShow(
        currentNoticeId: '0.6.0+26',
        suppressedNoticeId: '0.6.0+26',
      ),
      isFalse,
    );
    expect(
      UpdateNoticePolicy.shouldShow(
        currentNoticeId: '0.6.1+27',
        suppressedNoticeId: '0.6.0+26',
      ),
      isTrue,
    );
  });

  testWidgets('automatic dialog can suppress only the installed update',
      (tester) async {
    final noticeService = _FakeUpdateNoticeService();

    await tester.pumpWidget(
      BrightQuestApp(
        controller: GameController(),
        contentRepository: buildContentRepository(),
        updateNoticeService: noticeService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('whats_new_dialog')), findsOneWidget);
    expect(
      find.byKey(const Key('whats_new_suppress_this_version')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('whats_new_suppress_this_version')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('whats_new_dialog')), findsNothing);
    expect(noticeService.suppressedId, AppDistributionInfo.updateNoticeId);
  });

  testWidgets('Show next time closes without suppressing the update',
      (tester) async {
    final noticeService = _FakeUpdateNoticeService();

    await tester.pumpWidget(
      BrightQuestApp(
        controller: GameController(),
        contentRepository: buildContentRepository(),
        updateNoticeService: noticeService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('whats_new_show_next_launch')));
    await tester.pumpAndSettle();

    expect(noticeService.suppressedId, isNull);
  });

  test('automatic notice stays version-scoped and manual What is new remains', () {
    final app = File('lib/app/brightquest_app.dart').readAsStringSync();
    final dialog = File('lib/widgets/whats_new_dialog.dart').readAsStringSync();
    final distribution = File(
      'lib/core/services/app_distribution_info.dart',
    ).readAsStringSync();
    final about = File(
      'lib/features/parent/parent_about_app_screen.dart',
    ).readAsStringSync();

    expect(distribution, contains('updateNoticeId = version'));
    expect(app, contains('_maybeShowAutomaticUpdateNotice'));
    expect(app, contains('updateNoticeService.shouldShow'));
    expect(app, contains('updateNoticeService.suppress'));
    expect(dialog, contains("Don't show this update again"));
    expect(dialog, contains("Key('whats_new_suppress_this_version')"));
    expect(dialog, contains("Key('whats_new_show_next_launch')"));
    expect(about, contains('showBrightQuestWhatsNewDialog'));
    expect(about, contains('automatic: false'));
  });
}

class _FakeUpdateNoticeService extends UpdateNoticeService {
  String? suppressedId;

  @override
  Future<bool> shouldShow(String noticeId) async => suppressedId != noticeId;

  @override
  Future<void> suppress(String noticeId) async {
    suppressedId = noticeId;
  }
}
