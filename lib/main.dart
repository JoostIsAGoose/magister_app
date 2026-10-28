import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
                      print('User enterd school: $school');

                      // build login URL here
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