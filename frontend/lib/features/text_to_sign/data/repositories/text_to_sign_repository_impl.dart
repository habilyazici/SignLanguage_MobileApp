import '../../../../../core/utils/turkish_normalizer.dart';
import '../../domain/entities/sign_token.dart';
import '../../domain/repositories/text_to_sign_repository.dart';
import '../datasources/manifest_datasource.dart';

class TextToSignRepositoryImpl implements TextToSignRepository {
  TextToSignRepositoryImpl({required ManifestDatasource datasource})
      : _datasource = datasource;

  final ManifestDatasource _datasource;

  /// word → videoUrl haritası (manifest'ten yüklenir)
  Map<String, String> _manifest = {};

  Set<String> _knownWords = {};
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    _manifest = await _datasource.fetchManifest();
    _knownWords = _manifest.keys.toSet();
    _ready = true;
  }

  @override
  List<SignToken> parse(String text) {
    final tokens = TurkishNormalizer.tokenize(text);
    return tokens.map((word) => _resolve(word)).toList();
  }

  SignToken _resolve(String originalWord) {
    final stem = TurkishNormalizer.findStem(originalWord, _knownWords);
    if (stem == null) return SignNotFound(originalWord);

    return SignFound(
      originalWord,
      matchedWord: stem,
      videoUrl: _manifest[stem]!,
    );
  }
}
