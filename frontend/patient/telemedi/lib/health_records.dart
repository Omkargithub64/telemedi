import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:telemedi/ImageViewerScreen.dart';
import 'package:telemedi/config.dart'; // Ensure `baseUrl` is correctly defined
// Import Image Viewer Screen

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch records")),
      );
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
        fetchHealthRecords(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $responseData")),
        );
      }
    } catch (e) {
      print("Error uploading file: $e");
    }
  }

  Future<void> deleteHealthRecord(int recordId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    final response = await http.delete(
      Uri.parse('$baseUrl/health_records/$recordId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        healthRecords.removeWhere((record) => record['id'] == recordId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Records")),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadHealthRecord,
        child: const Icon(Icons.upload_file),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : healthRecords.isEmpty
              ? const Center(child: Text("No health records found"))
              : ListView.builder(
                  itemCount: healthRecords.length,
                  itemBuilder: (context, index) {
                    var record = healthRecords[index];
                    return ListTile(
                      title: Text(record['record_name']),
                      subtitle: Text("Uploaded: ${record['upload_date']}"),
                      leading: record['record_url'] != null
                          ? Image.network(record['record_url'],
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 50),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteHealthRecord(record['id']),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                                imageUrl: record['record_url']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
