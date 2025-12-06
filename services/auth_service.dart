
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Écouteur d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Connexion avec email/mot de passe
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Erreur connexion email: $e');
      return null;
    }
  }
  
  // Inscription avec email/mot de passe
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Mettre à jour le nom
      if (name.isNotEmpty) {
        await result.user?.updateDisplayName(name);
      }
      
      // Envoyer email de vérification
      await result.user?.sendEmailVerification();
      
      return result.user;
    } catch (e) {
      print('Erreur inscription: $e');
      return null;
    }
  }
  
  // Connexion avec Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print('Erreur Google Sign-In: $e');
      return null;
    }
  }
  
  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Réinitialiser mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}