import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NetworkService {
  static Map<String, String>? _ieeeDb;

  static Future<void> _loadIeeeDb() async {
    if (_ieeeDb != null) return;
    _ieeeDb = {};
    try {
      String csv = await rootBundle.loadString('assets/oui.csv');
      LineSplitter.split(csv).skip(1).forEach((line) {
        int firstComma = line.indexOf(',');
        if (firstComma == -1) return;
        int secondComma = line.indexOf(',', firstComma + 1);
        if (secondComma == -1) return;
        
        String assignment = line.substring(firstComma + 1, secondComma).trim();
        if (assignment.length != 6) return;
        
        String rest = line.substring(secondComma + 1).trim();
        String orgName = rest;
        if (rest.startsWith('"')) {
          int nextQuote = rest.indexOf('"', 1);
          if (nextQuote != -1) {
            orgName = rest.substring(1, nextQuote);
          }
        } else {
          int thirdComma = rest.indexOf(',');
          if (thirdComma != -1) {
            orgName = rest.substring(0, thirdComma);
          }
        }
        _ieeeDb![assignment] = orgName;
      });
    } catch (e) {
      print('Gagal memuat IEEE OUI: $e');
    }
  }

  /// Mendapatkan IP lokal komputer saat ini (contoh: 192.168.1.15)
  static Future<String?> getLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Mengabaikan IP VirtualBox/VMware jika memungkinkan (biasanya dimulai dengan 169 atau 192.168.56 dll, tapi kita ambil yang pertama valid)
            return addr.address;
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Melakukan Ping Sweep secara paralel ke 254 host, lalu membaca tabel ARP
  static Future<List<Map<String, String>>> scanNetwork({bool isDeepScan = false}) async {
    await _loadIeeeDb(); // Load IEEE DB first

    String? localIp = await getLocalIp();
    if (localIp == null) return [];

    // Mengambil subnet (contoh: 192.168.1)
    List<String> parts = localIp.split('.');
    if (parts.length != 4) return [];
    String subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // 1. PING & TCP SWEEP PARALEL
    List<Future<dynamic>> sweepTasks = [];
    for (int i = 1; i < 255; i++) {
      String targetIp = '$subnet.$i';
      
      if (isDeepScan) {
        // Deep Scan: Ping agresif + Furious Port 1 + Port Populer
        sweepTasks.add(Process.run('ping', ['-n', '1', '-w', '1000', targetIp]));
        sweepTasks.add(_stealthTcpSweep(targetIp, 1, 1000)); // Teknik Furious
        sweepTasks.add(_stealthTcpSweep(targetIp, 80, 1000));
        sweepTasks.add(_stealthTcpSweep(targetIp, 443, 1000));
        sweepTasks.add(_stealthTcpSweep(targetIp, 135, 1000));
        sweepTasks.add(_stealthTcpSweep(targetIp, 5353, 1000));
      } else {
        // Quick Scan: Ping biasa + Furious Port 1 (Lebih akurat dari ping biasa!)
        sweepTasks.add(Process.run('ping', ['-n', '1', '-w', '500', targetIp]));
        sweepTasks.add(_stealthTcpSweep(targetIp, 1, 500)); // Teknik Furious
      }
    }
    
    // Tunggu semua proses sweep selesai
    await Future.wait(sweepTasks);

    // Memberi waktu sejenak agar sistem Windows mencatat MAC
    int delayMs = isDeepScan ? 2000 : 500;
    await Future.delayed(Duration(milliseconds: delayMs));

    // 2. BACA TABEL ARP
    var arpResult = await Process.run('arp', ['-a']);
    String arpOutput = arpResult.stdout.toString();

    List<Map<String, String>> activeDevices = [];

    // Ambil IP lokal dan tambahkan sebagai perangkat pertama (This PC)
    String? localIpAddress = await getLocalIp();
    if (localIpAddress != null) {
      activeDevices.add({
        'ip': localIpAddress,
        'mac': 'Bawaan PC',
        'type': 'Komputer Anda (Localhost)',
        'hostname': 'localhost'
      });
    }

    // Regex untuk menangkap IP (192.168.1.x) dan MAC Address (xx-xx-xx-xx-xx-xx)
    RegExp arpRegex = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([0-9a-fA-F\-]{17})\s+([a-zA-Z]+)');
    Iterable<RegExpMatch> matches = arpRegex.allMatches(arpOutput);

    List<Future<Map<String, String>?>> enrichmentTasks = [];

    for (var match in matches) {
      String ip = match.group(1)!;
      String mac = match.group(2)!.toUpperCase();
      String type = match.group(3)!;

      // Filter hanya IP yang berada di subnet yang sama, dan abaikan tipe "static"
      if (ip.startsWith(subnet) && type != 'invalid' && mac != 'FF-FF-FF-FF-FF-FF') {
        if (!ip.endsWith('.255')) {
           enrichmentTasks.add(_enrichDeviceData(ip, mac, subnet));
        }
      }
    }

    var enrichmentResults = await Future.wait(enrichmentTasks);
    for (var res in enrichmentResults) {
      if (res != null) {
        activeDevices.add(res);
      }
    }

    // Mengurutkan IP agar rapi (1, 2, 3... 254)
    activeDevices.sort((a, b) {
      int ipA = int.parse(a['ip']!.split('.').last);
      int ipB = int.parse(b['ip']!.split('.').last);
      return ipA.compareTo(ipB);
    });

    return activeDevices;
  }

  static Future<Map<String, String>?> _enrichDeviceData(String ip, String mac, String subnet) async {
    String hostname = '';
    try {
      InternetAddress addr = InternetAddress(ip);
      InternetAddress rev = await addr.reverse().timeout(const Duration(milliseconds: 400));
      if (rev.host != ip) hostname = rev.host;
    } catch (_) {}

    String type = _guessDeviceType(mac, ip, subnet);

    // [Port Fingerprinting]
    // Jika MAC diacak, coba tebak lewat Port Scanner super kilat (timeout 300ms)
    if (type.contains('Private/Randomized')) {
       var apple1 = _isPortOpen(ip, 62078); // Apple Sync
       var apple2 = _isPortOpen(ip, 7000);  // Apple AirPlay
       var android1 = _isPortOpen(ip, 8008); // Google Cast
       var android2 = _isPortOpen(ip, 5555); // ADB

       var results = await Future.wait([apple1, apple2, android1, android2]);
       
       if (results[0] || results[1]) {
         type = 'Apple Device (Detected via Port 62078/7000)';
       } else if (results[2] || results[3]) {
         type = 'Android/Google Device (Detected via Port 8008/5555)';
       }
    }

    return {
      'ip': ip,
      'mac': mac,
      'type': type,
      'hostname': hostname,
    };
  }

  static Future<bool> _isPortOpen(String ip, int port) async {
    try {
      Socket socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Memaksa ARP Resolution dengan mengirim TCP SYN, kita tidak peduli hasilnya
  static Future<void> _stealthTcpSweep(String ip, int port, int timeoutMs) async {
    try {
      Socket socket = await Socket.connect(ip, port, timeout: Duration(milliseconds: timeoutMs));
      socket.destroy();
    } catch (e) {
      // Abaikan. Tujuannya hanya memaksa perangkat target membalas TCP RST/SYN-ACK 
      // yang akan memicu ARP Resolution di Windows.
    }
  }

  /// Menebak jenis perangkat berdasarkan 3 byte pertama MAC Address (OUI)
  static String _guessDeviceType(String mac, String ip, String subnet) {
    if (ip == '$subnet.1') return 'Router (Gateway)';

    try {
      String firstOctetHex = mac.substring(0, 2);
      int firstOctet = int.parse(firstOctetHex, radix: 16);
      if ((firstOctet & 2) == 2) {
        return 'Private/Randomized MAC (Phone/PC)';
      }
    } catch (e) {
      // Abaikan jika parsing gagal
    }

    String oui = mac.substring(0, 8).replaceAll('-', '').toUpperCase(); // format: XXXXXX
    
    if (_ieeeDb != null && _ieeeDb!.containsKey(oui)) {
      return _ieeeDb![oui]!;
    }

    return 'Unknown Device';
  }
}
