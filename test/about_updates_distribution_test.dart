import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('About screen uses verified Baisalya identity and parent-only links', () {
    final about = File(
      'lib/features/parent/parent_about_app_screen.dart',
    ).readAsStringSync();
    final distribution = File(
      'lib/core/services/app_distribution_info.dart',
    ).readAsStringSync();

    expect(about, contains("title: 'About us & updates'"));
    expect(about, contains("Key('about_official_website')"));
    expect(about, contains("Key('about_downloads_page')"));
    expect(about, contains("Key('about_privacy_policy')"));
    expect(about, contains("Key('about_support_page')"));
    expect(about, contains("Key('about_terms_page')"));
    expect(about, contains("Key('about_baisalya_website')"));
    expect(about, contains("Key('about_buy_me_a_coffee')"));
    expect(about, contains("Key('about_rate_app')"));
    expect(about, contains("Key('about_check_updates')"));
    expect(about, contains("Key('about_whats_new')"));
    expect(about, contains("Key('about_more_developer_details')"));

    expect(distribution, contains("developerName = 'Baishalya Roul'"));
    expect(distribution, contains("developerAlias = 'Baisalya'"));
    expect(
      distribution,
      contains("website = 'https://baisalya.com/brightquest-kids/'"),
    );
    expect(distribution, contains('brightquest-kids/downloads.html'));
    expect(distribution, contains('brightquest-kids/privacy.html'));
    expect(distribution, contains('brightquest-kids/support.html'));
    expect(distribution, contains('brightquest-kids/terms.html'));
    expect(
      distribution,
      contains("developerWebsite = 'https://baisalya.com/'"),
    );
    expect(
      distribution,
      contains("buyMeACoffee = 'https://www.buymeacoffee.com/baisalya'"),
    );
    expect(distribution, contains("email = 'baishalya1999@gmail.com'"));
    expect(distribution, contains('Centurion University'));
    expect(distribution, contains('Utkal University'));
  });

  test('Store actions fail closed until BrightQuest listings are verified', () {
    final distribution = File(
      'lib/core/services/app_distribution_info.dart',
    ).readAsStringSync();
    final about = File(
      'lib/features/parent/parent_about_app_screen.dart',
    ).readAsStringSync();

    expect(distribution, contains('googlePlayPublished = false'));
    expect(distribution, contains('microsoftStorePublished = false'));
    expect(distribution, contains('String? googlePlayUrl = null'));
    expect(distribution, contains('String? microsoftStoreUrl = null'));
    expect(about, contains('no verified public'));
    expect(about, contains('Rate BrightQuest Kids'));
    expect(about, contains('Not published yet'));
  });

  test('Distribution version stays aligned with pubspec', () {
    final distribution = File(
      'lib/core/services/app_distribution_info.dart',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([^\r\n]+)', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull);
    final version = match!.group(1)!.trim();
    expect(distribution, contains("version = '$version'"));
    expect(distribution, contains('updateNoticeId = version'));
  });

  test('BrightQuest branding is shared by Flutter, Android and Windows', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final illustrations = File(
      'lib/widgets/bright_illustrations.dart',
    ).readAsStringSync();
    final about = File(
      'lib/features/parent/parent_about_app_screen.dart',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final runner = File('windows/runner/Runner.rc').readAsStringSync();
    final mainCpp = File('windows/runner/main.cpp').readAsStringSync();

    expect(
      File('assets/branding/brightquest_app_icon.png').existsSync(),
      isTrue,
    );
    expect(pubspec, contains('assets/branding/brightquest_app_icon.png'));
    expect(illustrations, contains('class BrightQuestAppIcon'));
    expect(illustrations, contains('brightquest_app_icon.png'));
    expect(about, contains('BrightQuestAppIcon(size: 56)'));
    expect(manifest, contains('android:label="BrightQuest Kids"'));
    expect(runner, contains('VALUE "ProductName", "BrightQuest Kids"'));
    expect(mainCpp, contains('window.Create(L"BrightQuest Kids"'));

    for (final path in <String>[
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'windows/runner/resources/app_icon.ico',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('External links use one service and url_launcher dependency', () {
    final service = File(
      'lib/core/services/external_link_service.dart',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('url_launcher: ^6.3.2'));
    expect(service, contains("package:url_launcher/url_launcher.dart"));
    expect(service, contains('LaunchMode.externalApplication'));
    expect(service, contains("scheme: 'mailto'"));
  });
}
