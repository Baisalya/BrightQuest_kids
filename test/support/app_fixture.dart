import 'package:brightquest_kids/app/brightquest_app.dart';
import 'package:brightquest_kids/app/brightquest_scope.dart';
import 'package:brightquest_kids/core/content/content_repository.dart';
import 'package:brightquest_kids/core/state/game_controller.dart';
import 'package:flutter/widgets.dart';

import 'content_fixture.dart';

BrightQuestApp buildTestApp(
  GameController controller, {
  ContentRepository? contentRepository,
}) =>
    BrightQuestApp(
      controller: controller,
      contentRepository: contentRepository ?? buildContentRepository(),
    );

BrightQuestScope buildTestScope({
  required GameController controller,
  required Widget child,
  ContentRepository? contentRepository,
}) =>
    BrightQuestScope(
      controller: controller,
      contentRepository: contentRepository ?? buildContentRepository(),
      child: child,
    );
