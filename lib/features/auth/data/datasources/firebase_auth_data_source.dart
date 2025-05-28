import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser(); // เปลี่ยนเป็น Future
  Stream<UserModel?> get authStateChanges; // เพิ่ม stream
  Future<bool> isAuthenticated();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was canceled by the user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      if (userCredential.user == null) {
        throw const AuthException('Failed to retrieve user information');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // แทนที่จะใช้ currentUser โดยตรง ให้รอ authStateChanges แรก
      final user = await firebaseAuth.authStateChanges().first;
      if (user != null) {
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      // แทนที่จะเช็ค currentUser ให้รอ authStateChanges
      final user = await firebaseAuth.authStateChanges().first;
      return user != null;
    } catch (e) {
      return false;
    }
  }
}
