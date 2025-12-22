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
  final String cityId = "1415"; 
  
  Map<String, dynamic>? prayerTimes;
  String? lokasiInfo;
  String? daerahInfo;
  String? tanggalInfo;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes();
  }

  Future<void> fetchPrayerTimes() async {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString();
    String day = now.day.toString();

    // Endpoint myQuran.com
    final String url = 'https://api.myquran.com/v2/sholat/jadwal/$cityId/$year/$month/$day';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == true) {
          final data = jsonResponse['data'];
          setState(() {
            lokasiInfo = data['lokasi'];
            daerahInfo = data['daerah'];
            prayerTimes = data['jadwal'];
            tanggalInfo = data['jadwal']['tanggal'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Gagal memuat data. Pastikan ID Kota benar.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Error Server: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Koneksi gagal: Pastikan internet aktif.";
        isLoading = false;
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
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              fetchPrayerTimes();
            },
          )
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                             setState(() {
                                isLoading = true;
                                errorMessage = null;
                             });
                             fetchPrayerTimes();
                          }, 
                          child: const Text("Coba Lagi")
                        )
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        // PERBAIKAN DI SINI: Mengganti withOpacity dengan withValues
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        child: Column(
                          children: [
                            Text(
                              "$lokasiInfo, $daerahInfo",
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tanggalInfo ?? "-",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.secondary
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderedPrayers.length,
                          itemBuilder: (context, index) {
                            String key = orderedPrayers[index];
                            String time = prayerTimes?[key] ?? '-';
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  Icons.access_time_filled, 
                                  color: Theme.of(context).primaryColor
                                ),
                                title: Text(
                                  capitalize(key),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18
                                  ),
                                ),
                                trailing: Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Monospace' 
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Sumber data: myQuran.com",
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}