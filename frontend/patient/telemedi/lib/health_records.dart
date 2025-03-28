import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:telemedi/ImageViewerScreen.dart';
import 'package:telemedi/config.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  _HealthRecordsScreenState createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  List<dynamic> healthRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHealthRecords();
  }

  Future<void> fetchHealthRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _showError("User not authenticated");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health_records/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          healthRecords = json.decode(response.body)['health_records'];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch records: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError("Failed to fetch records: $e");
    }
  }

  Future<void> uploadHealthRecord() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return;

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/health_records/upload/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['record_name'] = fileName;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        _showSuccess("Record uploaded successfully");
        fetchHealthRecords(); // Refresh list
      } else {
        _showError("Upload failed: ${responseData.body}");
      }
    } catch (e) {
      _showError("Error uploading file: $e");
    }
  }

  Future<void> deleteHealthRecord(int recordId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/health_records/$recordId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          healthRecords.removeWhere((record) => record['id'] == recordId);
        });
        _showSuccess("Record deleted successfully");
      } else {
        throw Exception("Failed to delete record: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error deleting record: $e");
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
                      "Health Records",
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
                      onPressed: fetchHealthRecords,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2980b9)),
                        ),
                      )
                    : healthRecords.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 80, color: Color(0xFFbdc3c7)),
                                SizedBox(height: 20),
                                Text(
                                  "No health records found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF2c3e50),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchHealthRecords,
                            color: const Color(0xFF2980b9),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              itemCount: healthRecords.length,
                              itemBuilder: (context, index) {
                                var record = healthRecords[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16.0),
                                    leading: record['record_url'] != null
                                        ? GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ImageViewerScreen(
                                                          imageUrl: record[
                                                              'record_url']),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                record['record_url'],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.broken_image,
                                                        size: 60,
                                                        color:
                                                            Color(0xFFbdc3c7)),
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.image,
                                            size: 60, color: Color(0xFF2980b9)),
                                    title: Text(
                                      record['record_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2980b9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      "Uploaded: ${record['upload_date']}",
                                      style: const TextStyle(
                                          color: Color(0xFF7f8c8d)),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Color(0xFFe74c3c)),
                                      onPressed: () =>
                                          deleteHealthRecord(record['id']),
                                    ),
                                    onTap: () {
                                      if (record['record_url'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageViewerScreen(
                                                    imageUrl:
                                                        record['record_url']),
                                          ),
                                        );
                                      }
                                    },
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
      floatingActionButton: FloatingActionButton(
        onPressed: uploadHealthRecord,
        backgroundColor: const Color(0xFF2980b9),
        elevation: 5,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }
}
