import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Auth42Service {
  static const String clientId =
      'u-s4t2ud-3a548637642f107d2cecad69db98c514d882fe00b76e5a6f4139616121b33975'; // Your 42 client ID
  static const String clientSecret =
      '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'; // Your 42 client secret
  static const String redirectUri =
      'https://bitwarlock.github.io/auth42_callback/';
  static const String deepLinkUri = 'io.supabase.apprush://login';

  Future<void> authenticateWith42() async {
    final authUrl = Uri.parse(
      'https://api.intra.42.fr/oauth/authorize?' +
          'client_id=$clientId&' +
          'redirect_uri=${Uri.encodeComponent(redirectUri)}&' +
          'response_type=code&' +
          'scope=public',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication, // Always use external browser
      );
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user info: ${response.body}');
    }
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse('https://api.intra.42.fr/oauth/token'),
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code: ${response.body}');
    }

    return json.decode(response.body);
  }
}
