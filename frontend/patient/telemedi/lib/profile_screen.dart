import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telemedi/config.dart';

class PatientProfileScreen extends StatefulWidget {
  final String token;

  const PatientProfileScreen({super.key, required this.token});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    _fetchPatientProfile();
  }

  Future<void> _fetchPatientProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/patients/profile/'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        patientData = json.decode(response.body);
      });
    } else {
      print("Failed to load profile: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Profile")),
      body: patientData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: patientData!['profile_picture'] != ""
                        ? NetworkImage(patientData!['profile_picture'])
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 20),
                  _buildProfileInfo("Full Name", patientData!['full_name']),
                  _buildProfileInfo("Email", patientData!['email']),
                  _buildProfileInfo("Phone", patientData!['phone_number']),
                  _buildProfileInfo(
                      "Date of Birth", patientData!['date_of_birth']),
                  _buildProfileInfo("Gender", patientData!['gender']),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
