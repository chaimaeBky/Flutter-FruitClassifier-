import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ollama_chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OllamaChatService _chatService = OllamaChatService();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  
  double _temperature = 0.7;
  int _maxTokens = 256;
  int _topK = 40;
  double _topP = 0.95;
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }
  
  Future<void> _checkConnection() async {
    final isConnected = await _chatService.checkConnection();
    setState(() {
      _isConnected = isConnected;
    });
  }
  
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    
    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      final response = await _chatService.sendMessage(
        prompt: text,
        temperature: _temperature,
        maxTokens: _maxTokens,
        topK: _topK,
        topP: _topP,
      );
      
      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Erreur: $e',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Paramètres du modèle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSettingsSlider(
                      'Temperature: ${_temperature.toStringAsFixed(1)}',
                      _temperature,
                      0.0,
                      1.5,
                      (value) => setState(() => _temperature = value),
                    ),
                    _buildSettingsSlider(
                      'Max Tokens: $_maxTokens',
                      _maxTokens.toDouble(),
                      50,
                      4000,
                      (value) => setState(() => _maxTokens = value.toInt()),
                    ),
                    _buildSettingsSlider(
                      'Top-K: $_topK',
                      _topK.toDouble(),
                      0,
                      200,
                      (value) => setState(() => _topK = value.toInt()),
                    ),
                    _buildSettingsSlider(
                      'Top-P: ${_topP.toStringAsFixed(2)}',
                      _topP,
                      0.0,
                      1.0,
                      (value) => setState(() => _topP = value),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ajustez les paramètres pour contrôler la créativité et la longueur des réponses.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildSettingsSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 0.1).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as DateTime;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
  CircleAvatar(
    backgroundImage: AssetImage('assets/images/OIP.webp'),
    backgroundColor: Colors.teal,
  ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'Vous' : 'EMSI Assistant',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue[50]
                        : Colors.teal[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUser
                          ? Colors.blue[100]!
                          : Colors.teal[200]!,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            CircleAvatar(
                                backgroundImage: AssetImage('assets/images/profile.png'),
                                backgroundColor: Colors.teal,
                              ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMSI Chatbot'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _messages.isNotEmpty ? _clearChat : null,
          ),
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkConnection,
          ),
        ],
      ),
      drawer: Drawer(
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
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Ollama non connecté. Assurez-vous qu\'il est en cours d\'exécution sur http://localhost:11434',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkConnection,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Commencez une conversation avec l\'assistant EMSI',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: AssetImage('assets/images/OIP.webp'),
                                backgroundColor: Colors.teal,
                                
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EMSI Assistant',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.teal[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.teal[200]!,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Réflexion en cours...'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Posez votre question...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (value) => _sendMessage(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: _isConnected ? Colors.teal : Colors.grey),
                          onPressed: _isConnected ? _sendMessage : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}