import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FruitClassifierPage extends StatefulWidget {
  const FruitClassifierPage({Key? key}) : super(key: key);

  @override
  _FruitClassifierPageState createState() => _FruitClassifierPageState();
}

class _FruitClassifierPageState extends State<FruitClassifierPage> {
  String? _imageUrl;
  bool _isModelLoaded = false;
  bool _isLoadingModel = false;
  bool _isPredicting = false;
  String _predictionResult = '';
  List<String> _labels = [];
  Map<String, dynamic>? _modelInfo;
  String _modelType = 'Demo';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    setState(() => _isLoadingModel = true);

    try {
      print('🔍 Vérification du modèle TFLite...');
      
      // Vérifier si le script est chargé
      await Future.delayed(Duration(milliseconds: 500));
      
      if (js_util.hasProperty(html.window, 'tfjsModel')) {
        print('✅ Modèle TFLite détecté');
        _modelType = 'TFLite';
        await _loadTFJSModel();
      } else {
        print('⚠️ Modèle TFLite non trouvé, mode démo');
        _loadDemoMode();
      }
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
      _loadDemoMode();
    } finally {
      setState(() => _isLoadingModel = false);
    }
  }

  Future<void> _loadTFJSModel() async {
    try {
      final tfjsModel = js_util.getProperty(html.window, 'tfjsModel');
      
      // Charger le modèle
      final promise = js_util.callMethod(tfjsModel, 'loadModel', []);
      final isLoaded = await _promiseToFuture(promise);
      
      if (isLoaded == true) {
        // Récupérer les labels
        final jsLabels = js_util.callMethod(tfjsModel, 'getLabels', []);
        _labels = _jsArrayToList(jsLabels);
        
        // Récupérer les infos du modèle
        final jsInfo = js_util.callMethod(tfjsModel, 'getModelInfo', []);
        _modelInfo = _jsObjectToMap(jsInfo);
        
        setState(() {
          _isModelLoaded = true;
        });
        
        print('✅ Modèle TFLite chargé avec succès');
        print('📋 Labels: $_labels');
        print('📊 Info modèle: $_modelInfo');
      } else {
        throw 'Échec du chargement du modèle';
      }
    } catch (e) {
      print('❌ Erreur de chargement TFLite: $e');
      _loadDemoMode();
    }
  }

  void _loadDemoMode() {
    _labels = ['Apple', 'Banana', 'Orange', 'Strawberry', 'Grape'];
    _modelInfo = {
      'name': 'Demo Fruit Classifier',
      'type': 'Demo Mode',
      'inputSize': 224,
      'classes': _labels.length,
      'loaded': false,
      'source': 'Demo',
      'student': 'Demo Student'
    };
    _modelType = 'Demo';
    
    setState(() {
      _isModelLoaded = true;
    });
    
    print('✅ Mode démo activé');
  }

  List<String> _jsArrayToList(dynamic jsArray) {
    final List<String> result = [];
    try {
      if (jsArray != null) {
        // Vérifier si c'est un tableau JavaScript
        if (js_util.hasProperty(jsArray, 'length')) {
          final length = js_util.getProperty(jsArray, 'length') as int;
          for (int i = 0; i < length; i++) {
            final item = js_util.getProperty(jsArray, i.toString());
            if (item != null) {
              result.add(item.toString());
            }
          }
        }
      }
    } catch (e) {
      print('Erreur conversion JS Array: $e');
    }
    return result.isNotEmpty ? result : ['Apple', 'Banana', 'Orange'];
  }

  Map<String, dynamic> _jsObjectToMap(dynamic jsObject) {
    final Map<String, dynamic> result = {};
    try {
      if (jsObject != null) {
        // Obtenir toutes les propriétés de l'objet
        final jsProperties = js_util.callMethod(jsObject, 'toString', []);
        print('JS Object properties: $jsProperties');
        
        // Copier les propriétés communes
        final properties = ['name', 'type', 'inputSize', 'classes', 'loaded', 'source', 'student'];
        for (final prop in properties) {
          if (js_util.hasProperty(jsObject, prop)) {
            final value = js_util.getProperty(jsObject, prop);
            result[prop] = value?.toString() ?? '';
          }
        }
      }
    } catch (e) {
      print('Erreur conversion JS Object: $e');
    }
    return result;
  }

  Future<dynamic> _promiseToFuture(dynamic promise) async {
    try {
      return await js_util.promiseToFuture(promise);
    } catch (e) {
      print('Erreur promiseToFuture: $e');
      return null;
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? picture = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (picture != null) {
        final bytes = await picture.readAsBytes();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        setState(() {
          _imageUrl = url;
          _predictionResult = '';
        });
        
        print('📸 Photo capturée: ${bytes.length} bytes');
        
        // Prédiction automatique
        await Future.delayed(Duration(milliseconds: 300));
        await _predictFruit();
      }
    } catch (e) {
      _showError('Erreur caméra: $e');
    }
  }

  Future<void> _predictFruit() async {
    if (_imageUrl == null) {
      _showError('Prenez d\'abord une photo');
      return;
    }
    
    if (!_isModelLoaded) {
      _showError('Modèle en cours de chargement');
      return;
    }

    setState(() {
      _isPredicting = true;
      _predictionResult = 'Analyse en cours...';
    });

    try {
      if (_modelType == 'TFLite' && js_util.hasProperty(html.window, 'tfjsModel')) {
        // Utiliser le modèle TFLite
        final tfjsModel = js_util.getProperty(html.window, 'tfjsModel');
        
        // Créer une image HTML
        final image = html.ImageElement()..src = _imageUrl!;
        await image.onLoad.first;
        
        print('🎯 Utilisation du modèle TFLite...');
        final promise = js_util.callMethod(tfjsModel, 'predict', [image]);
        final result = await _promiseToFuture(promise);
        
        if (result != null) {
          final fruit = js_util.getProperty(result, 'fruit')?.toString() ?? 'Inconnu';
          final confidence = js_util.getProperty(result, 'confidence')?.toString() ?? '0.00';
          
          setState(() {
            _predictionResult = '$fruit ($confidence% de confiance)';
          });
          
          print('✅ Prédiction TFLite: $fruit ($confidence%)');
        } else {
          throw 'Erreur de prédiction';
        }
      } else {
        // Mode démo
        await Future.delayed(Duration(seconds: 1));
        final randomIndex = DateTime.now().millisecondsSinceEpoch % _labels.length;
        final fruit = _labels[randomIndex];
        final confidence = (70 + DateTime.now().millisecond % 25).toString();
        
        setState(() {
          _predictionResult = '$fruit ($confidence% de confiance) [Mode démo]';
        });
        
        print('🎯 Prédiction démo: $fruit ($confidence%)');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur de prédiction: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback démo
      final fruit = _labels.isNotEmpty ? _labels.first : 'Apple';
      setState(() {
        _predictionResult = '$fruit (75% de confiance) [Erreur]';
      });
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showModelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_modelType == 'TFLite' ? 'Modèle TFLite' : 'Mode Démo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _modelType == 'TFLite' 
                    ? 'Ce modèle utilise votre architecture TFLite personnalisée pour classifier les fruits.'
                    : 'Mode démo activé - utilisez votre modèle TFLite pour des prédictions réelles.',
                style: TextStyle(fontSize: 16),
              ),
              
              SizedBox(height: 16),
              
              if (_modelInfo != null) ...[
                Text('Information modèle:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ..._modelInfo!.entries.map((entry) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${entry.key}: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(child: Text(entry.value?.toString() ?? 'N/A')),
                      ],
                    ),
                  )
                ).toList(),
              ],
              
              SizedBox(height: 16),
              
              Text('Labels détectables:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _labels.map((label) => Chip(
                  label: Text(label),
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.teal),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          if (_modelType == 'Demo')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _initModel(); // Re-tenter de charger le modèle
              },
              child: Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('Fruit Classifier'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showModelInfo,
          ),
        ],
      ),drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                  Text(
                    'Chaimae el bakay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'chaimae@gmail.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushNamed(context, "/home"); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Fruits classifier'),
              onTap: () {
                Navigator.pushNamed(context, "/fruits"); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Emsi CHATBOT'),
               onTap: () {
                Navigator.pushNamed(context, '/chat');
              },
            ),
            Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              trailing: const Icon(Icons.arrow_forward),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to Settings Page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'état
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE2E8F0).withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isModelLoaded 
                          ? (_modelType == 'TFLite' ? Colors.green : Colors.orange).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                    ),
                    child: Center(
                      child: _isLoadingModel
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.orange),
                              ),
                            )
                          : Icon(
                              _isModelLoaded 
                                  ? (_modelType == 'TFLite' ? Icons.verified : Icons.smart_toy)
                                  : Icons.error,
                              color: _isModelLoaded 
                                  ? (_modelType == 'TFLite' ? Colors.green : Colors.orange)
                                  : Colors.grey,
                              size: 20,
                            ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingModel ? 'Chargement...' : 
                          _isModelLoaded 
                              ? (_modelType == 'TFLite' ? 'TFLite Actif' : 'Mode Démo')
                              : 'Erreur',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _labels.isNotEmpty 
                              ? '${_labels.length} fruits détectables'
                              : 'Chargement des labels...',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_modelType == 'TFLite')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TFLite',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Zone d'affichage d'image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE2E8F0).withOpacity(0.5),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _imageUrl == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF7FAFC),
                                ),
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 36,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Aucune image',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Prenez une photo pour commencer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF667EEA)),
                                  ),
                                );
                              },
                            ),
                            if (_isPredicting)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Analyse TFLite...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Bouton d'analyse
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_isPredicting || !_isModelLoaded || _imageUrl == null)
                    ? null
                    : _predictFruit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  disabledBackgroundColor: Color(0xFFCBD5E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: _isPredicting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Analyse en cours...',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _modelType == 'TFLite' ? 'Analyser avec TFLite' : 'Analyser (Démo)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Section résultats
            if (_predictionResult.isNotEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE2E8F0).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: _modelType == 'TFLite' ? Colors.green : Colors.orange,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Résultat d\'analyse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      _predictionResult,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _modelType == 'TFLite' ? Colors.green : Colors.orange,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _modelType == 'TFLite'
                          ? 'Analyse basée sur votre modèle TFLite personnalisé'
                          : 'Mode démo - utilisez votre propre modèle TFLite',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        backgroundColor: Colors.teal,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}