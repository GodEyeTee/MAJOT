import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  UserModel? getCurrentUser();
  bool isAuthenticated();
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
  UserModel? getCurrentUser() {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  @override
  bool isAuthenticated() {
    return firebaseAuth.currentUser != null;
  }
}
