/// Verified public identity and distribution metadata used by Parent Center.
///
/// Store publication is intentionally fail-closed. BrightQuest Kids currently
/// has no verified public Google Play or Microsoft Store listing, so the app
/// must never invent a store URL or imply that a rating/update action is live.
class AppDistributionInfo {
  const AppDistributionInfo._();

  static const appName = 'BrightQuest Kids';
  static const version = '0.6.0+26';
  // Automatic What's New suppression is scoped to this release only.
  // Incrementing the app version automatically makes the next update visible.
  static const updateNoticeId = version;

  static const developerName = 'Baishalya Roul';
  static const developerAlias = 'Baisalya';
  static const developerRole = 'Independent software builder';
  static const developerSummary =
      'Building practical Android, Windows and web products with a product mindset, local-first workflows where they matter, and release hardening as part of the product.';
  static const developerFocus =
      'Flutter & Dart • Android • Windows • Web • local-first software • offline workflows • recovery • release engineering';
  static const education = <String>[
    'Master of Computer Applications — Centurion University (2021–2023)',
    'Bachelor of Computer Applications — Utkal University (2017–2020)',
  ];
  static const products = <String>[
    'DevDesk',
    'ShopPilot',
    'Construction ERP',
    'NotiVault',
    'EduSheet',
    'SurveyCam',
  ];

  static const website = 'https://baisalya.com/brightquest-kids/';
  static const downloadsPage =
      'https://baisalya.com/brightquest-kids/downloads.html';
  static const privacyPolicy =
      'https://baisalya.com/brightquest-kids/privacy.html';
  static const supportPage =
      'https://baisalya.com/brightquest-kids/support.html';
  static const termsPage =
      'https://baisalya.com/brightquest-kids/terms.html';
  static const developerWebsite = 'https://baisalya.com/';
  static const github = 'https://github.com/Baisalya';
  static const linkedin =
      'https://www.linkedin.com/in/baishalya-roul-02a0b9153/';
  static const buyMeACoffee = 'https://www.buymeacoffee.com/baisalya';
  static const email = 'baishalya1999@gmail.com';

  static const googlePlayPublished = false;
  static const microsoftStorePublished = false;
  static const String? googlePlayUrl = null;
  static const String? microsoftStoreUrl = null;

  static const currentHighlights = <String>[
    'New BrightQuest Kids app icon plus official website, Downloads, Privacy and Support links in the parent area.',
    'Narrated lesson flow with stronger teaching, replay and feedback sequencing.',
    'Timed Challenge/Mastery gameplay with clearer right, wrong and timeout pacing.',
    'Game-specific background music and interaction sounds with parent audio controls.',
    'Cleaner Parent Center with PIN recovery, accessibility and separated management areas.',
  ];
}
