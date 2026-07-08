import 'dart:io';

class IpChangerService {
  /// Mendapatkan daftar semua network adapter di PC Windows
  static Future<List<String>> getAdapters() async {
    try {
      var result = await Process.run('netsh', ['interface', 'show', 'interface']);
      if (result.exitCode != 0) return [];

      List<String> adapters = [];
      List<String> lines = result.stdout.toString().split('\n');
      
      // Lewati 3 baris header pertama
      for (int i = 3; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;

        // Pisahkan spasi ganda (format tabel cmd)
        List<String> columns = line.split(RegExp(r'\s{2,}'));
        if (columns.length >= 4) {
          adapters.add(columns[3]); // Kolom ke-4 adalah Interface Name
        }
      }
      return adapters;
    } catch (e) {
      return [];
    }
  }

  /// Mendapatkan detail IP dari sebuah adapter
  static Future<Map<String, dynamic>?> getAdapterInfo(String adapterName) async {
    try {
      var result = await Process.run('netsh', ['interface', 'ip', 'show', 'config', 'name="$adapterName"']);
      if (result.exitCode != 0) return null;

      String output = result.stdout.toString();
      
      bool isDhcp = output.contains('DHCP enabled:                         Yes');
      
      String ip = '';
      String mask = '';
      String gateway = '';

      var ipMatch = RegExp(r'IP Address:\s+([\d\.]+)').firstMatch(output);
      if (ipMatch != null) ip = ipMatch.group(1)!;

      var maskMatch = RegExp(r'mask ([\d\.]+)').firstMatch(output);
      if (maskMatch != null) mask = maskMatch.group(1)!;

      var gwMatch = RegExp(r'Default Gateway:\s+([\d\.]+)').firstMatch(output);
      if (gwMatch != null) gateway = gwMatch.group(1)!;

      return {
        'isDhcp': isDhcp,
        'ip': ip,
        'mask': mask,
        'gateway': gateway,
      };
    } catch (e) {
      return null;
    }
  }

  /// Mengubah IP menjadi otomatis (DHCP) dengan hak akses Admin (UAC)
  static Future<bool> setDhcp(String adapterName) async {
    try {
      // Menggunakan PowerShell Start-Process -Verb RunAs untuk memanggil UAC prompt
      String script = 'Start-Process netsh -ArgumentList "interface ip set address name=\\"$adapterName\\" dhcp" -Verb RunAs -Wait';
      var result = await Process.run('powershell', ['-Command', script]);
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Mengubah IP menjadi statis dengan hak akses Admin (UAC)
  static Future<bool> setStatic(String adapterName, String ip, String mask, String gateway) async {
    try {
      // Menggunakan PowerShell Start-Process -Verb RunAs untuk memanggil UAC prompt
      String script = 'Start-Process netsh -ArgumentList "interface ip set address name=\\"$adapterName\\" static $ip $mask $gateway" -Verb RunAs -Wait';
      var result = await Process.run('powershell', ['-Command', script]);
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
