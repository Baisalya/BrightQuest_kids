import 'package:url_launcher/url_launcher.dart';

/// Opens parent-approved external destinations outside BrightQuest Kids.
///
/// Child-facing surfaces do not call this service. Keeping all website, store,
/// email and creator-support exits behind the Parent Center prevents accidental
/// navigation away from the learning experience.
class ExternalLinkService {
  const ExternalLinkService();

  Future<bool> open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> email({
    required String address,
    required String subject,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: <String, String>{'subject': subject},
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
