import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedGender;
  final Dio dio = Dio();

  Future<void> register() async {
    if (_validateInputs()) {
      try {
        Response response = await dio.post(
          "$baseUrl/users/patients/register/",
          data: {
            "username": usernameController.text.trim(),
            "full_name": fullNameController.text.trim(),
            "email": emailController.text.trim(),
            "phone_number": phoneController.text.trim(),
            "date_of_birth": dobController.text.trim(),
            "gender": selectedGender,
            "password": passwordController.text
          },
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Registration Successful"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          _showError("Error: ${response.data}");
          print(response.data);
        }
      } catch (e) {
        _showError("Something went wrong! Error: $e");
      }
    }
  }

  bool _validateInputs() {
    if (usernameController.text.trim().isEmpty ||
        fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        selectedGender == null ||
        passwordController.text.isEmpty) {
      _showError("Please fill all fields correctly.");
      return false;
    }
    return true;
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

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2980b9),
              onPrimary: Colors.white,
              surface: Color(0xFFf8fafc),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
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
              Color(0xFFe6f0fa),
              Color(0xFFf7f9fc),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
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
                  "Register with TeleMedi",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2980b9),
                    letterSpacing: 1.2,
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

                // Username
                _buildTextField(
                  controller: usernameController,
                  label: "Username",
                  hint: "Enter your username",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Full Name
                _buildTextField(
                  controller: fullNameController,
                  label: "Full Name",
                  hint: "Enter your full name",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),

                // Email
                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Phone Number
                _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  hint: "Enter your phone number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Date of Birth
                _buildTextField(
                  controller: dobController,
                  label: "Date of Birth",
                  hint: "Select your date of birth",
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),

                // Gender Dropdown
                Container(
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
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      labelStyle: TextStyle(color: Color(0xFF2980b9)),
                      prefixIcon:
                          Icon(Icons.transgender, color: Color(0xFF2980b9)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    ),
                    items: ["Male", "Female", "Other"]
                        .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF2980b9)),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Register Button
                ElevatedButton(
                  onPressed: register,
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
                    "Register",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login Link
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                      children: [
                        TextSpan(
                          text: "Login",
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
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
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
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
