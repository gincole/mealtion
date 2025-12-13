import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mealtion',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = 'Not checked yet';

  Future<void> checkHealth() async {
    try {
      final uri = Uri.parse('http://localhost:8080/health');
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        setState(() => status = 'HTTP ${res.statusCode}');
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() => status = data['status']?.toString() ?? 'unknown');
    } catch (e) {
      setState(() => status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mealtion')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('API status: $status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: checkHealth,
              child: const Text('Check /health'),
            ),
          ],
        ),
      ),
    );
  }
}
