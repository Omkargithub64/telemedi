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
            const SnackBar(
                content: Text("Registration Successful"),
                backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username")),
              TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name")),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  keyboardType: TextInputType.phone),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                    labelText: "Date of Birth (YYYY-MM-DD)"),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: ["Male", "Female", "Other"]
                    .map((gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: register, child: const Text("Register")),
            ],
          ),
        ),
      ),
    );
  }
}
