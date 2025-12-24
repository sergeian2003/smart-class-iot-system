import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- CONFIGURATION ---
const String serverIp = "10.0.2.2"; // Or your PC IP
const String baseUrl = "http://$serverIp:5000";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart School',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> classrooms = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchData();
    timer = Timer.periodic(const Duration(seconds: 2), (t) => fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/status"));
      if (response.statusCode == 200) {
        setState(() {
          classrooms = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> sendControl(String id, String action) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/api/control"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"classroom_id": id, "action": action}),
      );
      fetchData(); // Refresh UI immediately
    } catch (e) {
      debugPrint("Error sending control: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart School Control"), centerTitle: true),
      body: classrooms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classrooms.length,
              itemBuilder: (context, index) {
                final room = classrooms[index];
                final isAuto = room['mode'] == 'AUTO';
                final isLightOn = room['light_status'] == 'ON';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(room['classroom_id'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isAuto ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(isAuto ? "AUTO (AI)" : "MANUAL", 
                                  style: TextStyle(color: isAuto ? Colors.blue[800] : Colors.black54, fontSize: 12)),
                            )
                          ],
                        ),
                        const Divider(),
                        // Data Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _dataColumn(Icons.thermostat, "${room['last_temp']}°C", "Temp"),
                            _dataColumn(Icons.wb_sunny, "${room['last_lux']} Lx", "Light"),
                            _dataColumn(Icons.directions_run, room['last_motion'] == 1 ? "Yes" : "No", "Motion"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Control Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => sendControl(room['classroom_id'], 'ON'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (!isAuto && isLightOn) ? Colors.green : Colors.green[50],
                                  foregroundColor: (!isAuto && isLightOn) ? Colors.white : Colors.green,
                                ),
                                child: const Text("LIGHT ON"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => sendControl(room['classroom_id'], 'OFF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (!isAuto && !isLightOn) ? Colors.red : Colors.red[50],
                                  foregroundColor: (!isAuto && !isLightOn) ? Colors.white : Colors.red,
                                ),
                                child: const Text("LIGHT OFF"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => sendControl(room['classroom_id'], 'AUTO'),
                            icon: const Icon(Icons.refresh),
                            label: const Text("RESET TO AUTO MODE"),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _dataColumn(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 5),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
