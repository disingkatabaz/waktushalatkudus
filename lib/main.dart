import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jadwal Shalat',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const JadwalShalatPage(),
    );
  }
}

class JadwalShalatPage extends StatefulWidget {
  const JadwalShalatPage({super.key});

  @override
  State<JadwalShalatPage> createState() => _JadwalShalatPageState();
}

class _JadwalShalatPageState extends State<JadwalShalatPage> {
  final String cityId = '1415'; // Kudus
  
  Map<String, dynamic>? jadwalData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    ambilJadwalShalat();
  }

  Future<void> ambilJadwalShalat() async {
    // Ambil tanggal hari ini
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = now.day;

    // Susun URL API
    final url = Uri.parse(
        'https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month/$day');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Navigasi struktur JSON API myquran: data -> jadwal
          jadwalData = data['data']['jadwal'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Tampilkan error di terminal debug jika ada
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Shalat Kudus'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jadwalData == null
              ? const Center(child: Text("Gagal mengambil data"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header Tanggal
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.green),
                              const SizedBox(width: 10),
                              Text(
                                jadwalData!['tanggal'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // List Jadwal
                      Expanded(
                        child: ListView(
                          children: [
                            _buildJadwalItem("Subuh", jadwalData!['subuh']),
                            _buildJadwalItem("Dzuhur", jadwalData!['dzuhur']),
                            _buildJadwalItem("Ashar", jadwalData!['ashar']),
                            _buildJadwalItem("Maghrib", jadwalData!['maghrib']),
                            _buildJadwalItem("Isya", jadwalData!['isya']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJadwalItem(String waktu, String jam) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.access_time_filled, color: Colors.green),
        title: Text(waktu, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          jam,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}