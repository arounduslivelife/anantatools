import 'dart:io';
import 'dart:async';
import 'network_service.dart';

class IpSuggesterService {
  /// Mendapatkan daftar IP yang benar-benar kosong di jaringan
  static Future<Map<String, dynamic>> getAvailableIps() async {
    String? localIp = await NetworkService.getLocalIp();
    if (localIp == null) {
      return {'error': 'Tidak dapat mendeteksi IP Lokal'};
    }

    List<String> parts = localIp.split('.');
    String subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // 1. Ambil daftar IP yang sedang dipakai (termasuk PC ini karena sudah dimasukkan di scanNetwork)
    List<Map<String, String>> usedDevices = await NetworkService.scanNetwork(isDeepScan: false);
    Set<String> usedIps = usedDevices.map((e) => e['ip']!).toSet();
    
    int activeCount = usedIps.length;

    // 2. Kunci IP wajib (Router dan Cadangan)
    Set<String> lockedIps = {};
    if (!usedIps.contains('$subnet.1')) lockedIps.add('$subnet.1');
    if (!usedIps.contains('$subnet.254')) lockedIps.add('$subnet.254');
    
    // Gabungkan untuk pencarian IP kosong
    Set<String> allUnavailableIps = {}..addAll(usedIps)..addAll(lockedIps);

    // 2. Cari IP yang kosong
    List<String> availableIps = [];
    for (int i = 2; i < 254; i++) {
      String ip = '$subnet.$i';
      if (!allUnavailableIps.contains(ip)) {
        availableIps.add(ip);
      }
    }

    // 3. Pilih 3 rekomendasi IP (bawah, tengah, atas)
    List<String> recommendations = [];
    if (availableIps.isNotEmpty) {
      // Ambil yang di blok bawah (misal 2-50)
      var low = availableIps.where((ip) => int.parse(ip.split('.')[3]) <= 50).toList();
      if (low.isNotEmpty) recommendations.add(low.first);

      // Ambil yang di blok tengah (100-150)
      var mid = availableIps.where((ip) {
        int last = int.parse(ip.split('.')[3]);
        return last >= 100 && last <= 150;
      }).toList();
      if (mid.isNotEmpty) recommendations.add(mid.first);

      // Ambil yang di blok atas (200-250)
      var high = availableIps.where((ip) => int.parse(ip.split('.')[3]) >= 200).toList();
      if (high.isNotEmpty) recommendations.add(high.first);
      
      // Jika masih belum 3, ambil acak dari sisa
      for (var ip in availableIps) {
        if (recommendations.length >= 3) break;
        if (!recommendations.contains(ip)) recommendations.add(ip);
      }
    }

    // 4. Double check ke 3 IP rekomendasi tersebut untuk memastikan 100% mati
    List<String> verifiedRecommendations = [];
    for (String ip in recommendations) {
      bool isDead = await _verifyDeadIp(ip);
      if (isDead) {
        verifiedRecommendations.add(ip);
      }
    }

    return {
      'subnet': '$subnet.0/24',
      'activeCount': activeCount,
      'lockedCount': lockedIps.length,
      'availableCount': availableIps.length,
      'allAvailable': availableIps,
      'recommendations': verifiedRecommendations,
    };
  }

  /// Verifikasi ganda: Ping lama + Port 1, 80, 135
  static Future<bool> _verifyDeadIp(String ip) async {
    try {
      // 1. Ping
      var pingRes = await Process.run('ping', ['-n', '1', '-w', '1000', ip]);
      if (pingRes.stdout.toString().contains('Reply from')) {
        return false; // Ada balasan ping, berarti hidup!
      }

      // 2. Port Check (1, 80, 135)
      var p1 = Socket.connect(ip, 1, timeout: const Duration(milliseconds: 500));
      var p80 = Socket.connect(ip, 80, timeout: const Duration(milliseconds: 500));
      var p135 = Socket.connect(ip, 135, timeout: const Duration(milliseconds: 500));

      var results = await Future.wait([
        p1.then((s) { s.destroy(); return true; }).catchError((e) => e.toString().contains('refused')),
        p80.then((s) { s.destroy(); return true; }).catchError((e) => e.toString().contains('refused')),
        p135.then((s) { s.destroy(); return true; }).catchError((e) => e.toString().contains('refused')),
      ]);

      // Jika ada port yang connect atau refused (bukan timeout), berarti host hidup
      if (results.any((res) => res == true)) {
        return false; // Hidup!
      }

      // Jika semuanya timeout, berarti benar-benar mati
      return true;
    } catch (e) {
      return true;
    }
  }
}
