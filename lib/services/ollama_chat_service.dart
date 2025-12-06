import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaChatService {
  // Configuration par défaut
  static const String _defaultBaseUrl = 'http://localhost:11434';
  static const String _defaultModel = 'llama3.2:latest';
  
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 512;
  static const int defaultTopK = 40;
  static const double defaultTopP = 0.95;
  
  String _baseUrl = _defaultBaseUrl;
  String _model = _defaultModel;
  
  /// Configurer l'URL
  void configure({String? baseUrl, String? model}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (model != null) _model = model;
  }
  
  /// Envoyer un message à Ollama
  Future<String> sendMessage({
    required String prompt,
    double temperature = defaultTemperature,
    int maxTokens = defaultMaxTokens,
    int topK = defaultTopK,
    double topP = defaultTopP,
    bool stream = false,
  }) async {
    try {
      final response = await _postWithTimeout(
        Uri.parse('$_baseUrl/api/generate'),
        jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': stream,
          'options': {
            'num_predict': maxTokens,
            'temperature': temperature,
            'top_k': topK,
            'top_p': topP,
          },
        }),
        const Duration(seconds: 120),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Pas de réponse du modèle';
      } else {
        throw Exception('Erreur Ollama (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion à Ollama: $e');
    }
  }
  
  /// Vérifier si Ollama est accessible
  Future<bool> checkConnection({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final response = await _getWithTimeout(
        Uri.parse('$_baseUrl/api/tags'),
        timeout,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Lister les modèles disponibles
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _getWithTimeout(
        Uri.parse('$_baseUrl/api/tags'),
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List<dynamic>;
        return models.map<String>((model) => model['name'] as String).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Méthode helper pour GET avec timeout
  Future<http.Response> _getWithTimeout(Uri url, Duration timeout) async {
    final completer = Completer<http.Response>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Request timeout after $timeout'),
        );
      }
    });

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      timer.cancel();
      completer.complete(response);
    } catch (e) {
      timer.cancel();
      completer.completeError(e);
    }

    return completer.future;
  }
  
  /// Méthode helper pour POST avec timeout
  Future<http.Response> _postWithTimeout(Uri url, String body, Duration timeout) async {
    final completer = Completer<http.Response>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Request timeout after $timeout'),
        );
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      timer.cancel();
      completer.complete(response);
    } catch (e) {
      timer.cancel();
      completer.completeError(e);
    }

    return completer.future;
  }
}