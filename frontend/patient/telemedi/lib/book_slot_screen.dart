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
  final TextEditingController reasonController = TextEditingController();

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
      fetchAvailableSlots();
    } else {
      _showError("Login required");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

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
        throw Exception("Failed to fetch slots: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching slots: $e");
    }
  }

  Future<void> bookSlot(int slotId, String reason) async {
    try {
      final response = await dio.post(
        "$baseUrl/patient/slots/book/$slotId",
        data: {"reason": reason},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        _showSuccess("Slot booked successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        throw Exception("Failed to book slot: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error booking slot: $e");
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
                      "Book a Slot",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      onPressed: fetchAvailableSlots,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: availableSlots.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2980b9)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchAvailableSlots,
                        color: const Color(0xFF2980b9),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableSlots[index];
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
                                    color: const Color(0xFF2980b9)
                                        .withOpacity(0.1),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color(0xFF2980b9),
                                  ),
                                ),
                                title: Text(
                                  "Dr. ${slot['doctor_name']}",
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
                                      "${slot['start_time']} - ${slot['end_time']}",
                                      style: const TextStyle(
                                          color: Color(0xFF7f8c8d)),
                                    ),
                                    Text(
                                      "Specialty: ${slot['doctor_specialty']}",
                                      style: const TextStyle(
                                          color: Color(0xFF7f8c8d)),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    reasonController.clear();
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          title: const Text(
                                            "Book Appointment",
                                            style: TextStyle(
                                              color: Color(0xFF2980b9),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: _buildReasonField(),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                    color: Color(0xFFe74c3c)),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                String reason = reasonController
                                                    .text
                                                    .trim();
                                                if (reason.isEmpty) {
                                                  _showError(
                                                      "Please enter a reason");
                                                } else {
                                                  bookSlot(slot['id'], reason);
                                                  Navigator.pop(context);
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF2980b9),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                "Book",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2980b9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Book",
                                    style: TextStyle(color: Colors.white),
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

  Widget _buildReasonField() {
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
        controller: reasonController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Reason for Appointment",
          labelStyle: TextStyle(color: Color(0xFF2980b9)),
          hintText: "Enter your reason here",
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF3498db), width: 2),
          ),
        ),
      ),
    );
  }
}
