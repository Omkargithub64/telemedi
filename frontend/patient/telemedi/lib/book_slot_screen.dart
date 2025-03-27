import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemedi/home_screen.dart';
import 'config.dart';

class BookSlotScreen extends StatefulWidget {
  const BookSlotScreen({super.key});

  @override
  _BookSlotScreenState createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  List<dynamic> availableSlots = [];
  String? token;
  final Dio dio = Dio();
  TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // 🔹 Load token from SharedPreferences
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
    if (token != null) {
      fetchAvailableSlots();
    } else {
      _showMessage("Login required");
    }
  }

  // 🔹 Fetch available doctor slots
  Future<void> fetchAvailableSlots() async {
    try {
      final response = await dio.get(
        "$baseUrl/slots/available",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          availableSlots = response.data['available_slots'];
        });
      } else {
        _showMessage("Failed to fetch slots");
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  // 🔹 Book a slot
  Future<void> bookSlot(int slotId, String reason) async {
    try {
      final response = await dio.post(
        "$baseUrl/patient/slots/book/$slotId",
        data: {"reason": reason},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        _showMessage("Slot booked successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        ); // Refresh after booking
      } else {
        _showMessage("Failed to book slot");
      }
    } catch (e) {
      _showMessage("Error booking slot: $e");
    }
  }

  // 🔹 Show Snackbar messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book a Slot")),
      body: availableSlots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final slot = availableSlots[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Doctor: ${slot['doctor_name']}"),
                    subtitle: Text(
                        "${slot['start_time']} - ${slot['end_time']} \nAvailable for: ${slot['doctor_specialty']}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Book Slot"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: reasonController,
                                    decoration: const InputDecoration(
                                      labelText: "Reason for Appointment",
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    String reason =
                                        reasonController.text.trim();
                                    if (reason.isEmpty) {
                                      _showMessage("Please enter a reason");
                                    } else {
                                      bookSlot(slot['id'], reason);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text("Book"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Cancel"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text("Book"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
