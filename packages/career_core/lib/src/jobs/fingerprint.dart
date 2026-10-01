import '../util/text_normalize.dart';

class JobFingerprint {
  JobFingerprint._();

  static String compute({
    required String company,
    required String title,
    required String locationOrRemote,
  }) {
    final compNorm = TextNormalize.normalizeCompany(company);
    final titleNorm = TextNormalize.normalizeTitle(title);
    final locNorm = TextNormalize.collapseWhitespace(locationOrRemote.toLowerCase());
    return TextNormalize.sha1Hex('$compNorm|$titleNorm|$locNorm');
  }
}
