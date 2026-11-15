/// Spells Armenian text in Latin letters the way Armenian song titles and
/// artist names are usually written in music stores ("Սիրուշո" → "Sirusho",
/// "Սիրո հասակ" → "Siro hasak").
///
/// The iTunes catalog lists Armenian songs in Latin letters only, so a search
/// typed in Armenian finds nothing unless it is spelled over first.
abstract final class ArmenianTransliteration {
  static final _armenian = RegExp('[Ա-և]');

  static bool containsArmenian(String text) => _armenian.hasMatch(text);

  /// [text] with each Armenian letter replaced by its usual Latin spelling;
  /// anything else is kept as it is.
  static String toLatin(String text) {
    final out = StringBuffer();
    final chars = text.toLowerCase().runes.map(String.fromCharCode).toList();
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      final atWordStart = i == 0 || !_armenian.hasMatch(chars[i - 1]);
      if (c == 'ո' && next == 'ւ') {
        out.write('u');
        i++;
      } else if (c == 'ե' && atWordStart) {
        out.write('ye');
      } else if (c == 'ո' && atWordStart) {
        out.write('vo');
      } else {
        out.write(_letters[c] ?? c);
      }
    }
    return out.toString();
  }

  static const _letters = {
    'ա': 'a', 'բ': 'b', 'գ': 'g', 'դ': 'd', 'ե': 'e', 'զ': 'z', 'է': 'e',
    'ը': 'e', 'թ': 't', 'ժ': 'zh', 'ի': 'i', 'լ': 'l', 'խ': 'kh', 'ծ': 'ts',
    'կ': 'k', 'հ': 'h', 'ձ': 'dz', 'ղ': 'gh', 'ճ': 'ch', 'մ': 'm', 'յ': 'y',
    'ն': 'n', 'շ': 'sh', 'ո': 'o', 'չ': 'ch', 'պ': 'p', 'ջ': 'j', 'ռ': 'r',
    'ս': 's', 'վ': 'v', 'տ': 't', 'ր': 'r', 'ց': 'ts', 'ւ': 'v', 'փ': 'p',
    'ք': 'q', 'և': 'ev', 'օ': 'o', 'ֆ': 'f',
  };
}
