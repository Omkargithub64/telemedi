import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Assuming you have a config file with your base URL and other constants

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> appointments = [];
  String? token;
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
    if (token != null) {
      fetchAppointments();
    } else {
      _showMessage("Login required");
    }
  }

  // Fetch appointments from API
  Future<void> fetchAppointments() async {
    try {
      final response = await dio.get(
        "$baseUrl/patient/appointments", // Adjust the endpoint as per your API
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          appointments =
              response.data['appointments']; // Assuming the response structure
        });
      } else {
        _showMessage("Failed to fetch appointments");
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  // Show Snackbar messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: appointments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(appointment[
                        'doctor_name']), // Displaying doctor name or other details from the response
                    subtitle: Text(
                        appointment['date']), // Displaying appointment date
                    trailing: ElevatedButton(
                      onPressed: () {
                        // You can add functionality for canceling or completing an appointment
                      },
                      child: const Text("Start"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
