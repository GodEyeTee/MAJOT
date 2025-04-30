import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;

  // Constructor for injecting SupabaseClient
  AuthService({required this.supabase});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Save user data to Supabase using the correct API
    try {
      await supabase.from('users').upsert({
        'id': userCredential.user!.uid,
        'email': userCredential.user!.email,
        'full_name': userCredential.user!.displayName,
      });

      // Note: No .execute() call - the operation is executed implicitly
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await supabase.auth.signOut();
  }
}
