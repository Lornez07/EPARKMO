import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class OtpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate a cryptographically random N-digit OTP
  String generateOtp([int length = AppStrings.otpLength]) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  /// Store a pending OTP in Firestore and trigger Email via Google Script
  Future<String> createAndStoreOtp(String userId, String userEmail) async {
    final otp = generateOtp();
    final expiresAt = DateTime.now()
        .add(const Duration(seconds: AppStrings.otpExpirySeconds));

    // 1. Store in Firestore
    await _db.collection('pendingOtp').doc(userId).set({
      'otp': otp,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt.toIso8601String(),
    });

    // 2. Send via Google Script Proxy (Universal support)
    _sendEmailViaProxy(userEmail, otp).catchError((e) {
      print('❌ FAILED to send email: $e');
    });

    return otp;
  }

  /// Sends the OTP via an HTTP POST request to the Google Apps Script proxy.
  /// This bypasses browser restrictions (SMTP blocking) and is 100% free.
  Future<void> _sendEmailViaProxy(String recipient, String otp) async {
    print('DEBUG: Attempting to send OTP email via Proxy to $recipient...');

    if (AppStrings.googleScriptUrl.contains('YOUR_GOOGLE_SCRIPT_WEB_APP_URL_HERE')) {
      print('❌ Google Script URL not configured in app_constants.dart.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(AppStrings.googleScriptUrl),
        body: jsonEncode({
          'recipient': recipient,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        print('✅ SUCCESS: OTP sent to $recipient via Google Script.');
      } else {
        print('❌ FAILED: Script returned Status Code ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ ERROR sending via Proxy: $e');
    }
  }

  /// Verify the OTP entered by the user
  Future<bool> verifyOtp(String userId, String enteredOtp) async {
    final doc = await _db.collection('pendingOtp').doc(userId).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'] as String;
    final expiresAt = DateTime.parse(data['expiresAt'] as String);

    // Check expiry
    if (DateTime.now().isAfter(expiresAt)) {
      await doc.reference.delete(); // clean up expired OTP
      return false;
    }

    // Check match
    if (storedOtp == enteredOtp) {
      await doc.reference.delete(); // clean up used OTP
      return true;
    }

    return false;
  }

  /// Delete any pending OTP for a user (e.g. on cancel)
  Future<void> clearPendingOtp(String userId) async {
    await _db.collection('pendingOtp').doc(userId).delete();
  }
}
