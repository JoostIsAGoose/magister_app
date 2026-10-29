import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MagisterApp());
}

class MagisterApp extends StatefulWidget {
  const MagisterApp({super.key});

  @override
  State<MagisterApp> createState() => _MagisterAppState();
}

class _MagisterAppState extends State<MagisterApp> {
  final storage = const FlutterSecureStorage();

  final TextEditingController _schoolController = TextEditingController();
  
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _checkToken() async {
    String? savedToken = await storage.read(key: 'bearer_token');
    
    setState(() {
      _token = savedToken;
      _isLoading = false;
    });
  }

  Future<void> _launchAuthUrl(String urlString) async {
    final Uri url= Uri.parse(urlString);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show loading spinner while checking storage
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 2. Once loaded, display dashboard or login screen
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _token != null 
            ? const Text(
                'Token found! Ready for dashboard.', 
                style: TextStyle(fontSize: 18),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Magister Client',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your school subdomain ("yourschool".magister.net)',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _schoolController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'SchoolSubdomain',
                      hintText: 'dewillem',
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String school = _schoolController.text.trim();

                      if (school.isEmpty) {
                        print('Error: School subdomain cannot be empty');
                        return;
                      }

                      String authUrl = 'https://accounts.magister.net/connect/authorize?'
                          'client_id=M6-$school.magister.net&'
                          'redirect_uri=https://$school.magister.net/oidc/redirect_callback.html&'
                          'response_type=id_token token&'
                          'scope=openid profile opp.read opp.manage attendance.overview attendance.administration calendar.user calendar.ical.user calendar.to-do.user grades.read grades.manage oso.administration registration.admin lockers.administration exams.administration enrollment.admin privacyportal.administration learningmaterials.user&'
                          'state=811b239be24b4f6dac5c553e3f0591da&'
                          'nonce=385004e8675547a99061a95056ecddf5&'
                          'acr_values=tenant:$school.magister.net';

                          print(authUrl);

                          _launchAuthUrl(authUrl);
                     },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Log in with Magister',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}