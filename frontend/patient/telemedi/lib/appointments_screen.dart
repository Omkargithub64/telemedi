import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemedi/room.dart';
import 'config.dart';

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

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
    if (token != null) {
      fetchAppointments();
    } else {
      _showError("Login required");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
      );
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await dio.get(
        "$baseUrl/patient/appointments",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          appointments = response.data['appointments'];
        });
      } else {
        throw Exception("Failed to fetch appointments: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching appointments: $e");
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2ecc71),
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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "My Appointments",
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
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF2980b9)),
                      onPressed: fetchAppointments,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: appointments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 80, color: Color(0xFFbdc3c7)),
                            SizedBox(height: 20),
                            Text(
                              "No appointments found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchAppointments,
                        color: const Color(0xFF2980b9),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        const Color(0xFF2980b9).withOpacity(0.1),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    size: 30,
                                    color: Color(0xFF2980b9),
                                  ),
                                ),
                                title: Text(
                                  "Dr. ${appointment['doctor_name']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2980b9),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "${appointment['date']} ${appointment['start_time'] ?? ''} - ${appointment['end_time'] ?? ''}",
                                      style: const TextStyle(
                                          color: Color(0xFF7f8c8d)),
                                    ),
                                    if (appointment['reason'] != null)
                                      Text(
                                        "Reason: ${appointment['reason']}",
                                        style: const TextStyle(
                                            color: Color(0xFF7f8c8d)),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Room(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2980b9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                  ),
                                  child: const Text(
                                    "Join",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}