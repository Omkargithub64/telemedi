import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio();

  Future<void> login() async {
    try {
      Response response = await dio.post(
        "$baseUrl/users/patients/login/",
        data: {
          "email": emailController.text.trim(),
          "password": passwordController.text
        },
      );

      if (response.statusCode == 200) {
        var data = response.data;
        String? token = data["token"];
        String? fullName = data["full_name"];
        String? email = data["email"];
        String? phoneNumber = data["phone_number"];
        String? dateOfBirth = data["date_of_birth"];
        String? gender = data["gender"];

        if (token == null || email == null) {
          _showError("Invalid response from server. Please try again.");
          return;
        }

        // Store values safely (fallback to empty string if null)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("full_name", fullName ?? "");
        await prefs.setString("email", email);
        await prefs.setString("phone_number", phoneNumber ?? "");
        await prefs.setString("date_of_birth", dateOfBirth ?? "");
        await prefs.setString("gender", gender ?? "");

        // Navigate to Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showError("Invalid credentials");
      }
    } catch (e) {
      _showError("Login failed! $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
