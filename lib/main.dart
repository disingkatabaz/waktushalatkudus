import 'dart:async';
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
      title: 'Waktu Shalat Kudus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C4F)),
        useMaterial3: true,
      ),
      home: const PrayerTimesPage(),
    );
  }
}

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  final String cityId = "1415"; // ID Kudus
  
  Map<String, dynamic>? prayerTimes;
  String? lokasiInfo;
  String? daerahInfo;
  String? tanggalInfo;
  
  // Variabel untuk Countdown
  String countdownText = "-- : -- : --";
  String nextPrayerName = "Memuat...";
  Timer? _timer;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPrayerTimes() async {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString();
    String day = now.day.toString();

    final String url = 'https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month/$day';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == true) {
          final data = jsonResponse['data'];
          if (mounted) {
            setState(() {
              lokasiInfo = data['lokasi'];
              daerahInfo = data['daerah'];
              prayerTimes = data['jadwal'];
              tanggalInfo = data['jadwal']['tanggal'];
              isLoading = false;
            });
            startCountdown();
          }
        } else {
          if (mounted) setState(() { errorMessage = "Gagal memuat data."; isLoading = false; });
        }
      } else {
        if (mounted) setState(() { errorMessage = "Error Server: ${response.statusCode}"; isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { errorMessage = "Koneksi gagal."; isLoading = false; });
    }
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      calculateNextPrayer();
    });
  }

  void calculateNextPrayer() {
    if (prayerTimes == null) return;

    DateTime now = DateTime.now();
    
    List<String> timesToCheck = ['imsak', 'subuh', 'terbit', 'dhuha', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    
    String? upcomingPrayer;
    DateTime? upcomingTime;

    // 1. Cek jadwal hari ini
    for (String key in timesToCheck) {
      String timeString = prayerTimes![key]; 
      List<String> parts = timeString.split(':');
      
      DateTime prayerDate = DateTime(
        now.year, now.month, now.day, 
        int.parse(parts[0]), int.parse(parts[1])
      );

      if (prayerDate.isAfter(now)) {
        upcomingPrayer = key;
        upcomingTime = prayerDate;
        break; 
      }
    }

    // 2. Jika tidak ada jadwal tersisa hari ini, target ke Imsak besok
    if (upcomingTime == null) {
      upcomingPrayer = 'imsak'; 
      String timeString = prayerTimes!['imsak'];
      List<String> parts = timeString.split(':');
      
      upcomingTime = DateTime(
        now.year, now.month, now.day + 1, 
        int.parse(parts[0]), int.parse(parts[1])
      );
    }

    // 3. Hitung selisih waktu
    Duration diff = upcomingTime.difference(now);

    // 4. Format ke HH:MM:SS
    String formattedTime = 
      "${diff.inHours.toString().padLeft(2, '0')}:"
      "${(diff.inMinutes % 60).toString().padLeft(2, '0')}:"
      "${(diff.inSeconds % 60).toString().padLeft(2, '0')}";

    // 5. Update UI
    if (mounted) {
      setState(() {
        nextPrayerName = capitalize(upcomingPrayer!);
        countdownText = formattedTime;
      });
    }
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> orderedPrayers = [
      'imsak', 'subuh', 'terbit', 'dhuha', 'dzuhur', 'ashar', 'maghrib', 'isya'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Shalat Kudus'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { isLoading = true; errorMessage = null; });
              fetchPrayerTimes();
            },
          )
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Text(errorMessage!)
                : Column(
                    children: [
                      // --- BAGIAN COUNTDOWN ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Menuju $nextPrayerName",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              countdownText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Monospace',
                                letterSpacing: 2
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$lokasiInfo, $tanggalInfo",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      // --- LIST JADWAL ---
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderedPrayers.length,
                          itemBuilder: (context, index) {
                            String key = orderedPrayers[index];
                            String time = prayerTimes?[key] ?? '-';
                            
                            bool isNext = capitalize(key) == nextPrayerName;
                            
                            return Card(
                              color: isNext ? Theme.of(context).colorScheme.primaryContainer : null,
                              elevation: isNext ? 4 : 1,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  Icons.access_time_filled, 
                                  color: isNext ? Colors.black : Theme.of(context).primaryColor
                                ),
                                title: Text(
                                  capitalize(key),
                                  style: TextStyle(
                                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 18
                                  ),
                                ),
                                trailing: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                                    fontFamily: 'Monospace' 
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}