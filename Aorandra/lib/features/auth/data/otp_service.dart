import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpService {
  // Supabase client instance
  final supabase = Supabase.instance.client;

  // EmailJS configuration
  final String serviceId = "service_p3mh3qb";
  final String templateId = "template_shfxfcc";

  // ⚠️ IMPORTANT: Replace with your real Public Key from EmailJS (NOT template ID)
  final String publicKey = "7gT1IRVjxFFipGXIv";

  // ================= SEND EMAIL =================

  /// Sends OTP code to the user's email using EmailJS
 Future<void> _sendEmailOtp(String email, String code) async {
  try {
    final response = await http.post(
      Uri.parse("https://api.emailjs.com/api/v1.0/email/send"),
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost', // 🔥 مهم جداً
      },
      body: jsonEncode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": publicKey,
        "template_params": {
          "to_email": email,
          "code": code,
        }
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Email failed");
    }

  } catch (e) {
    print("EMAIL ERROR: $e");
    rethrow;
  }
}

  // ================= SEND OTP =================

  /// Generates OTP, saves it in database, then sends it via email
  Future<void> sendOtp(String email) async {
    // Generate 6-digit OTP code
    final code = (100000 + Random().nextInt(900000)).toString();

    // Delete any previous OTPs for this email
    await supabase.from('otp_codes').delete().eq('email', email);

    // Insert new OTP into database
    await supabase.from('otp_codes').insert({
      "email": email,
      "code": code,
      "created_at": DateTime.now().toUtc().toIso8601String(),
      "expires_at": DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5)) // expires in 5 minutes
          .toIso8601String(),
    });

    // Send OTP via email
    await _sendEmailOtp(email, code);

    // Debug log
    print("OTP SENT: $code");
  }

  // ================= VERIFY OTP =================

  /// Verifies the OTP entered by the user
  Future<bool> verifyOtp(String email, String input) async {
    final data = await supabase
        .from('otp_codes')
        .select()
        .eq('email', email)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // If no OTP found
    if (data == null) {
      print("No OTP found");
      return false;
    }

    final dbCode = data['code'].toString().trim();
    final expiresAt = DateTime.parse(data['expires_at']).toUtc();
    final now = DateTime.now().toUtc();

    // Debug logs
    print("INPUT CODE: $input");
    print("DB CODE: $dbCode");
    print("NOW: $now");
    print("EXPIRES AT: $expiresAt");

    // Check if code matches
    if (dbCode != input) {
      print("Code mismatch");
      return false;
    }

    // Check if code expired
    if (now.isAfter(expiresAt)) {
      print("Code expired");
      return false;
    }

    print("OTP VALID");
    return true;
  }

  // ================= CLEAR OTP =================

  /// Deletes OTP after successful verification
  Future<void> clearOtp(String email) async {
    await supabase.from('otp_codes').delete().eq('email', email);
  }
}