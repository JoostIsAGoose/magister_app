import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http; 
import 'package:url_launcher/url_launcher.dart';

class AuthService {
    // constants for Magister OAuth
  static const String clientId = 'M6App'; // Standard client id used by Magister mobile app
  // using local loopback port for desktop app redirection
  static const String redirectUri = 'http://localhost:8080/';
  static const String authEndpoint = 'https://id.magister.net/connect/authorize';
  static const String tokenEndpoint = 'https://id.magister.net/connect/token';

  // scopes restricted to profile, schedual and grades (+tokens)
  static const String requestedScopes = 'openid offline_access profiel rooster cijfers';

  // 1. Generate code verifier
  String generateCodeVerifier() {
    // create random number generator
    final random = Random.secure();

    // generate 32 random bytes
    final values = List<int>.generate(32, (i) => random.nextInt(256));

    // encode bytes into Base64URL withouth padding
    return base64UrlEncode(values).replaceAll('=', '');
  }

  // 2. generate code challenge
  String generateCodeChallenge(String codeVerifier) {
    //convert text verifier into utf-8
    final bytes = utf8.encode(codeVerifier);

    // hash bytes using SHA-256
    final digest = sha256.convert(bytes);

    // encode hash into Base64URL string and strip padding
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  //3 login URL
  String buildAuthorizationUrl(String codeChallenge) {
    // using uri to safely encode parameters so special characters dont break the link
    final uri = Uri.parse(authEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': requestedScopes, //permissions
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256', // tell magister we hashed our verifier using SHA-256
    });

    return uri.toString();
  }

  // MAIN LOGIN FLOW: server + browser launcher + code Catcher
  Future<String?> loginAndGetCode() async {
    //1. generate PKCE security keys
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);

    //2. start local HTTP server listening on port 8080 localhost
    // (trap waiting for browser callback)
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

    //3. build login URL with challenge and launch system browser
    final authUrl = buildAuthorizationUrl(challenge);
    final uri = Uri.parse(authUrl);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await server.close();
      throw Exception('Could not launch the browser for login.');
    }

    try {
      //4. wait for browser to redirect to http://localhost:8080/?code=...
      // server.first listens for exact http request and stops after
      final request = await server.first;

      //extract 'code' quety parameter from URL browser sent
      final code = request.uri.queryParameters['code'];

      //5. send success message to browser tab so user know to close
      request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('<html><body style="font-family: sans-serif; text-align: center; padding-top: 50px;">'
      '<h2>Logins Successful!</h2>'
      '<p>You can close this tab and return to your app.</p>'
      '</body></html>');
      await request.response.close();

      //6. close temp local server
      await server.close(force: true);

      //return the raw authorization code
      return code;
    } catch (e) {
      //make sure to shutdown server if something goes wrong
      await server.close(force: true);
      rethrow;
    }
  }
    //TOKEN EXCHANGE: trading the code + verifier for tokens
    Future<Map<String, dynamic>?> exchangeCodeForTokens(String code, String codeVerifier) async {
      final uri = Uri.parse(tokenEndpoint);

      // OAuth token exchange requires form-urlencoded peramteres
      final body = {
        'client_id': clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier, // proves we are the exact app that started the login
      };

      try {
        //send POST request to Magisters token server
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        );

        if (response.statusCode == 200) {
          // if successful, magister returns jSON map with token
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data;
        } else {
          //print or hande error if magister rejects code
          print('Token exchange failed: ${response.statusCode} - ${response.body}');
          return null;
        }
      } catch (e) {
        print('Network error during token exchange: $e');
        return null;
      }
    }
  
}