import 'dart:io';
import 'dart:convert';

class PingResult {
  final String host;
  final bool isOnline;
  final int latencyMs;
  final String message;

  PingResult({
    required this.host,
    required this.isOnline,
    required this.latencyMs,
    required this.message,
  });
}

class PingService {
  /// Melakukan Ping ICMP tunggal ke host target (Windows only)
  static Future<PingResult> ping(String host) async {
    try {
      // -n 1 : Kirim 1 paket saja
      // -w 1000 : Tunggu maksimal 1000ms (1 detik) sebelum Timeout
      var result = await Process.run('ping', ['-n', '1', '-w', '1000', host]);
      String output = result.stdout.toString().toLowerCase();

      // Cek apakah output mengandung 'reply from' atau 'balasan dari' (bahasa Indonesia)
      // dan pastikan tidak mengandung 'unreachable' atau 'tidak dapat dijangkau'
      if ((output.contains('reply from') || output.contains('balasan dari')) &&
          !output.contains('unreachable') && !output.contains('tidak dapat dijangkau')) {
        
        // Ekstrak latency menggunakan Regex
        RegExp exp = RegExp(r'(?:time|waktu)[=<](\d+)ms');
        var match = exp.firstMatch(output);
        int latency = 0;
        if (match != null && match.groupCount >= 1) {
          latency = int.tryParse(match.group(1)!) ?? 0;
        }

        return PingResult(
          host: host,
          isOnline: true,
          latencyMs: latency,
          message: 'Online',
        );
      } else {
        return PingResult(
          host: host,
          isOnline: false,
          latencyMs: 0,
          message: 'Request Timed Out / Unreachable',
        );
      }
    } catch (e) {
      return PingResult(
        host: host,
        isOnline: false,
        latencyMs: 0,
        message: 'Error: \${e.toString()}',
      );
    }
  }

  /// Menembakkan Magic Packet (Wake-on-LAN) ke MAC Address target
  static Future<bool> wakeOnLan(String macAddress) async {
    try {
      // Bersihkan MAC Address dari karakter non-hex (seperti ':' atau '-')
      String cleanMac = macAddress.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
      if (cleanMac.length != 12) {
        return false; // MAC Address tidak valid
      }

      // Buat List bytes dari MAC Address
      List<int> macBytes = [];
      for (int i = 0; i < cleanMac.length; i += 2) {
        macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
      }

      // Payload Magic Packet: 6 bytes 0xFF, diikuti 16 kali pengulangan MAC Address
      List<int> payload = List<int>.filled(6, 0xFF);
      for (int i = 0; i < 16; i++) {
        payload.addAll(macBytes);
      }

      // Kirim UDP Broadcast ke 255.255.255.255 di Port 9 (Standar WoL)
      var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(payload, InternetAddress('255.255.255.255'), 9);
      socket.close();

      return true;
    } catch (e) {
      return false;
    }
  }
}
