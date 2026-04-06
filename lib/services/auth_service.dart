import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

const bool kUseMockMode = false;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  // Mock data for fallback or mock mode
  static final Map<String, UserModel> _mockUsers = {
    AppStrings.guestEmail: UserModel(
      uid: 'mock-guest-uid',
      email: AppStrings.guestEmail,
      name: 'Guest User',
      role: 'guest',
    ),
    AppStrings.adminEmail: UserModel(
      uid: 'mock-admin-uid',
      email: AppStrings.adminEmail,
      name: 'Admin User',
      role: 'admin',
    ),
  };

  Future<UserModel?> signIn(String email, String password) async {
    if (kUseMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final trimmed = email.trim().toLowerCase();
      final user = _mockUsers[trimmed];
      if (user == null) throw Exception('User not found.');

      final expectedPass = trimmed == AppStrings.adminEmail
          ? AppStrings.adminPass
          : AppStrings.guestPass;
      if (password != expectedPass) throw Exception('Incorrect password.');

      _currentUser = user;
      return user;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      if (cred.user == null) return null;

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap({...doc.data()!, 'uid': doc.id});
      } else {
        _currentUser = UserModel(
          uid: cred.user!.uid,
          email: cred.user!.email ?? '',
          name: 'User',
          role: 'guest',
        );
      }
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (kUseMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final trimmed = email.trim().toLowerCase();
      if (_mockUsers.containsKey(trimmed)) {
        throw Exception('Email already registered.');
      }
      final newUser = UserModel(
        uid: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        email: trimmed,
        name: name,
        role: 'guest',
      );
      _mockUsers[trimmed] = newUser;
      _currentUser = newUser;
      return newUser;
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      if (cred.user == null) return null;

      final user = UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        name: name,
        role: 'guest',
      );

      await _db.collection('users').doc(user.uid).set(user.toMap());
      _currentUser = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (kUseMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = null;
      return;
    }
    await _auth.signOut();
    _currentUser = null;
  }
}
