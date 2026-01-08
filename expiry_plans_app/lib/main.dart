import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await NotificationService.init();
  } catch (e) {
    print("⚠️ Notification Error: $e"); 
  }

  runApp(const ExpiryPlansApp());
}

class ExpiryPlansApp extends StatelessWidget {
  const ExpiryPlansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expiry Plans',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const RegisterScreen(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> registerUser() async {
    // ⚠️ Use 10.0.2.2 for Android
    final String url = 'http://10.0.2.2:8080/auth/register'; 

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": _nameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ User Registered Successfully!')));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.lock_clock, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("Already have an account? Log In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}