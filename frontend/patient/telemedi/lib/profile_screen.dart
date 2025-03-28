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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientProfile();
  }

  Future<void> _fetchPatientProfile() async {
    try {
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
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError("Error loading profile: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFe74c3c),
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
              Color(0xFFe6f0fa),
              Color(0xFFf7f9fc),
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2980b9)),
                  ),
                )
              : patientData == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 80, color: Color(0xFFbdc3c7)),
                          SizedBox(height: 20),
                          Text(
                            "Failed to load profile",
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "My Profile",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
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
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Color(0xFF2980b9)),
                                onPressed: _fetchPatientProfile,
                              ),
                            ],
                          ),
                        ),

                        // Profile Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                _buildProfilePic(),
                                const SizedBox(height: 30),
                                _buildProfileCard(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildProfilePic() {
    return CircleAvatar(
      radius: 70,
      backgroundColor: const Color(0xFF2980b9).withOpacity(0.1),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.white,
        child: patientData!['profile_picture'] != null &&
                patientData!['profile_picture'].isNotEmpty
            ? ClipOval(
                child: Image.network(
                  patientData!['profile_picture'],
                  fit: BoxFit.cover,
                  width: 130,
                  height: 130,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    size: 70,
                    color: Color(0xFF2980b9),
                  ),
                ),
              )
            : const Icon(
                Icons.person,
                size: 70,
                color: Color(0xFF2980b9),
              ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileInfo("Full Name", patientData!['full_name'] ?? "N/A"),
            const Divider(height: 20, color: Color(0xFFe6e6e6)),
            _buildProfileInfo("Email", patientData!['email'] ?? "N/A"),
            const Divider(height: 20, color: Color(0xFFe6e6e6)),
            _buildProfileInfo("Phone", patientData!['phone_number'] ?? "N/A"),
            const Divider(height: 20, color: Color(0xFFe6e6e6)),
            _buildProfileInfo(
                "Date of Birth", patientData!['date_of_birth'] ?? "N/A"),
            const Divider(height: 20, color: Color(0xFFe6e6e6)),
            _buildProfileInfo("Gender", patientData!['gender'] ?? "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2980b9),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2c3e50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
