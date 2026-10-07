import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/config/secrets.dart';

/// Why a cartoon generation failed, so the UI can pick the right message.
enum CartoonFailure { network, rejected, other }

class CartoonAvatarException implements Exception {
  const CartoonAvatarException(this.failure, [this.detail]);

  final CartoonFailure failure;
  final String? detail;

  @override
  String toString() => 'CartoonAvatarException($failure, $detail)';
}

/// Turns a soldier's photo into a cartoon portrait via the OpenAI Images
/// edit endpoint. The photo leaves the device only when the user explicitly
/// asks for it; the result is saved into the app's documents directory.
class CartoonAvatarService {
  CartoonAvatarService({http.Client? client, this.apiKey = openAiApiKey})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  /// Best first. The mini model ignores the reference face much more than
  /// the full ones, so try those first and fall back when the project's key
  /// isn't allowed to use them. Enabling a better model in the OpenAI
  /// dashboard then upgrades every install without a new build.
  static const List<_ModelOption> _models = [
    _ModelOption('gpt-image-1.5'),
    _ModelOption('gpt-image-1', highFidelity: true),
    _ModelOption('gpt-image-1-mini'),
  ];

  /// Index into [_models] of the first one that isn't known to be refused,
  /// so later generations skip the failed attempts.
  int _firstUsableModel = 0;
  static final Uri _endpoint =
      Uri.parse('https://api.openai.com/v1/images/edits');

  // Generation regularly takes 30–60 s; leave headroom for slow networks.
  static const Duration _timeout = Duration(seconds: 150);

  // A style transfer, not a new picture: anything the prompt asks for
  // (framing, outfit, background) makes the model recompose the scene, so it
  // only names the style and lists what must stay put.
  static const String _prompt =
      'Redraw this exact photo as a cartoon illustration. This is a style '
      'change only — the result must match the original photo one-to-one. '
      'Keep exactly the same composition, framing and crop, camera angle, '
      'camera distance and zoom, head position and tilt, body pose, hands, '
      'facial expression, clothing, accessories, background, objects, '
      'lighting direction and colors. Do not add, remove, move or resize '
      'anything, do not zoom in or out, do not center or re-frame the '
      'subject, do not add people. Keep every person in the photo fully '
      'recognizable: same face shape and '
      'proportions, eyes, eyebrows, nose, lips, ears, skin tone, hairstyle, '
      'facial hair and glasses; do not beautify, slim or change age. '
      'Only change the rendering: clean outlines, flat soft cel shading and '
      'simplified textures, like a frame from a modern animated film.';

  /// OpenAI rejects uploads without an explicit image type, and picked files
  /// don't reliably carry a matching extension, so read the magic bytes.
  static Future<MediaType> _sniffImageType(String path) async {
    final file = await File(path).open();
    final List<int> head;
    try {
      head = await file.read(12);
    } finally {
      await file.close();
    }
    bool startsWith(List<int> sig, [int offset = 0]) =>
        head.length >= offset + sig.length &&
        List.generate(sig.length, (i) => head[offset + i] == sig[i])
            .every((match) => match);

    if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) {
      return MediaType('image', 'png');
    }
    if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
        startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return MediaType('image', 'webp');
    }
    // image_picker re-encodes to JPEG when it resizes, so that's the default.
    return MediaType('image', 'jpeg');
  }

  Future<http.Response> _send(
    _ModelOption model,
    String photoPath,
    MediaType contentType,
  ) async {
    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model.name
      ..fields['prompt'] = _prompt
      ..fields['size'] = 'auto'
      ..fields['quality'] = 'medium'
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          photoPath,
          contentType: contentType,
        ),
      );
    if (model.highFidelity) request.fields['input_fidelity'] = 'high';

    try {
      return await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
    } on SocketException catch (e) {
      throw CartoonAvatarException(CartoonFailure.network, '$e');
    } on http.ClientException catch (e) {
      throw CartoonAvatarException(CartoonFailure.network, '$e');
    } on Exception catch (e) {
      // TimeoutException and friends.
      throw CartoonAvatarException(CartoonFailure.network, '$e');
    }
  }

  /// The project key can be restricted to certain models (or the org not yet
  /// verified for them); OpenAI then answers as if the model didn't exist.
  static bool _isModelUnavailable(http.Response response) {
    if (response.statusCode != 400 &&
        response.statusCode != 403 &&
        response.statusCode != 404) {
      return false;
    }
    final body = response.body;
    return body.contains('model_not_found') ||
        body.contains('does not exist') ||
        body.contains('does not have access') ||
        body.contains('must be verified') ||
        body.contains('invalid_input_fidelity_model');
  }

  /// Whether a key was baked into this build; the UI hides the feature
  /// otherwise.
  bool get isConfigured => apiKey.isNotEmpty;

  /// Sends [photoPath] to OpenAI and returns the path of the saved cartoon.
  Future<String> cartoonize(String photoPath) async {
    final contentType = await _sniffImageType(photoPath);

    late http.Response response;
    for (var i = _firstUsableModel; i < _models.length; i++) {
      response = await _send(_models[i], photoPath, contentType);
      if (i < _models.length - 1 && _isModelUnavailable(response)) {
        _firstUsableModel = i + 1;
        continue;
      }
      break;
    }

    if (response.statusCode != 200) {
      // Content-policy refusals come back as 400 with a moderation code.
      final body = response.body;
      final rejected = response.statusCode == 400 &&
          (body.contains('moderation') || body.contains('safety'));
      throw CartoonAvatarException(
        rejected ? CartoonFailure.rejected : CartoonFailure.other,
        '${response.statusCode}: $body',
      );
    }

    final String? b64;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      b64 = ((json['data'] as List).first as Map<String, dynamic>)['b64_json']
          as String?;
    } on Object catch (e) {
      throw CartoonAvatarException(CartoonFailure.other, '$e');
    }
    if (b64 == null) {
      throw const CartoonAvatarException(CartoonFailure.other, 'no image');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dir.path, 'cartoon_${DateTime.now().millisecondsSinceEpoch}.png'),
    );
    await file.writeAsBytes(base64Decode(b64));
    return file.path;
  }
}

class _ModelOption {
  const _ModelOption(this.name, {this.highFidelity = false});

  final String name;

  /// gpt-image-1 only keeps the face when asked to; 1.5 always does and
  /// mini rejects the parameter outright.
  final bool highFidelity;
}

final cartoonAvatarServiceProvider = Provider<CartoonAvatarService>(
  (ref) => CartoonAvatarService(),
);
