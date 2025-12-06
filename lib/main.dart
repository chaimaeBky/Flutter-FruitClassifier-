// main.dart - MODIFIEZ-LE POUR AJOUTER CES PRINTS
import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/fruitsClassifier_page.dart';
import 'screens/EmsiChat_page.dart';
import 'screens/profile_page.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 


void main() async {
  // 1. Initialiser Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  print(' Démarrage de l\'application...'); // AJOUT
  
  try {
    // 2. Initialiser Firebase
    print(' Tentative d\'initialisation Firebase...'); // AJOUT
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print(' Firebase initialisé avec succès!'); // AJOUT
    
    // 3. Vérifier Firebase Auth
    final auth = FirebaseAuth.instance;
    print(' Firebase Auth disponible'); // AJOUT
    
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      print(' Utilisateur déjà connecté: ${currentUser.email}'); // AJOUT
    } else {
      print(' Aucun utilisateur connecté'); // AJOUT
    }
    
  } catch (e, stackTrace) {
    print(' ERREUR Firebase: $e'); // AJOUT
    print(' Stack trace: $stackTrace'); // AJOUT
  }
  
  print(' Lancement de l\'application...'); // AJOUT
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chaimae Elbakay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/fruits': (context) => FruitClassifierPage(),
        '/chat': (context) => const ChatPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}