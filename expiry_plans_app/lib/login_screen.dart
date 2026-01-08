import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_screen.dart';
import 'main.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> loginUser() async {
    // ⚠️ Use 10.0.2.2 for Android
    final String url = 'http://10.0.2.2:8080/auth/login'; 

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome Back"), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loginUser,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blueAccent),
              child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
              child: const Text("Don't have an account? Sign Up"),
            )
          ],
        ),
      ),
    );
  }
}