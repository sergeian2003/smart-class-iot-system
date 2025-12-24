import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- CONFIGURATION ---
// 1. For Android Emulator: use "10.0.2.2" (Host loopback)
// 2. For Real Device: use your PC's local IP (e.g., "192.168.1.35")
const String SERVER_IP = "10.0.2.2"; 
const String API_URL = "http://$SERVER_IP:5000/api/latest";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Class',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
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
  // Default UI state
  String temperature = "--";
  String light = "--";
  bool isMotionDetected = false;
  String lastUpdated = "Waiting...";
  bool isLoading = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchData();
    // Auto-refresh data every 2 seconds
    timer = Timer.periodic(const Duration(seconds: 2), (Timer t) => fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Fetches the latest sensor data from the Flask API
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(API_URL));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          // The server returns a list of rows from SQLite.
          // Schema: [id, classroom_id, temp, light, motion, timestamp]
          // Indexes: 2=temp, 3=light, 4=motion, 5=time
          
          final latestRecord = data[0]; // Get the most recent record

          setState(() {
            temperature = latestRecord[2].toString();
            light = latestRecord[3].toString();
            // 1 = Motion Detected, 0 = No Motion
            isMotionDetected = (latestRecord[4] == 1);
            
            // Parse and format timestamp (extracting time only)
            String rawTime = latestRecord[5].toString();
            // Simple string slicing to get HH:MM:SS
            lastUpdated = rawTime.length > 10 ? rawTime.substring(11, 19) : rawTime;
            
            isLoading = false;
          });
        }
      } else {
        print("Server returned error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Class Monitor', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Real-time Sensor Data",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Last updated: $lastUpdated",
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Temperature Card
                  SensorCard(
                    title: "Temperature",
                    value: "$temperature °C",
                    icon: Icons.thermostat,
                    color: Colors.orange,
                  ),
                  
                  // Light Level Card
                  SensorCard(
                    title: "Light Level",
                    value: "$light Lux",
                    icon: Icons.wb_sunny,
                    color: Colors.green,
                  ),

                  // Motion Status Card
                  SensorCard(
                    title: "Motion Status",
                    value: isMotionDetected ? "DETECTED" : "Safe",
                    icon: isMotionDetected ? Icons.run_circle : Icons.accessibility_new,
                    color: isMotionDetected ? Colors.red : Colors.blue,
                  ),
                  
                  const Spacer(),
                  
                  // Manual Refresh Button
                  ElevatedButton.icon(
                    onPressed: fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh Now"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

/// Reusable Widget for displaying sensor data cards
class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            // Text Information
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}