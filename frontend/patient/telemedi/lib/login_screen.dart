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

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("full_name", fullName ?? "");
        await prefs.setString("email", email);
        await prefs.setString("phone_number", phoneNumber ?? "");
        await prefs.setString("date_of_birth", dateOfBirth ?? "");
        await prefs.setString("gender", gender ?? "");

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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFe6f0fa), // Light blue from previous designs
              Color(0xFFf7f9fc), // Light gray
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo or Icon
                  const Icon(
                    Icons.local_hospital,
                    size: 80,
                    color: Color(0xFF2980b9),
                  ),
                  const SizedBox(height: 10),

                  // Stylish Heading
                  Text(
                    "TeleMedi",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2980b9),
                      letterSpacing: 1.5,
                      shadows: [
                        const Shadow(
                          color: Colors.black12,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Input Field
                  _buildTextField(
                    controller: emailController,
                    label: "Email",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Password Input Field
                  _buildTextField(
                    controller: passwordController,
                    label: "Password",
                    hint: "Enter your password",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2980b9),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black26,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                        children: [
                          TextSpan(
                            text: "Register",
                            style: TextStyle(
                              color: Color(0xFF2980b9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF2980b9)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF2980b9)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3498db), width: 2),
          ),
        ),
      ),
    );
  }
}
