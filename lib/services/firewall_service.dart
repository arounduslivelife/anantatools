import 'dart:io';
import 'dart:convert';

class FirewallService {
  /// Membaca status firewall saat ini untuk ketiga profil (Domain, Private, Public)
  static Future<Map<String, bool>> getFirewallStatus() async {
    Map<String, bool> status = {
      'Domain': false,
      'Private': false,
      'Public': false,
    };

    try {
      // Menggunakan powershell untuk mengambil status profile
      var result = await Process.run('powershell', [
        '-Command',
        'Get-NetFirewallProfile | Select-Object Name, Enabled | ConvertTo-Json'
      ]);

      if (result.stdout.toString().trim().isNotEmpty) {
        var jsonResult = jsonDecode(result.stdout.toString());
        if (jsonResult is List) {
          for (var profile in jsonResult) {
            String name = profile['Name'].toString();
            bool enabled = profile['Enabled'] == true || profile['Enabled'] == 1; // Tergantung versi powershell
            if (status.containsKey(name)) {
              status[name] = enabled;
            }
          }
        }
      }
    } catch (e) {
      // Jika terjadi error, kita biarkan false
    }

    return status;
  }

  /// Mengubah status (On/Off) untuk profil firewall tertentu menggunakan hak akses Administrator (UAC)
  static Future<bool> setFirewallStatus(String profile, bool isEnabled) async {
    String state = isEnabled ? 'True' : 'False';
    try {
      String command = 'Set-NetFirewallProfile -Profile $profile -Enabled $state';
      
      var result = await Process.run('powershell', [
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-WindowStyle',
        'Hidden',
        '-ArgumentList',
        '"-Command $command"'
      ]);

      // Kita tidak bisa menangkap stdout dari proses UAC, 
      // asumsikan berhasil jika exitcode 0 (berarti berhasil memanggil UAC prompt)
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Menambahkan aturan baru untuk membuka atau memblokir port (Membutuhkan UAC)
  static Future<bool> addPortRule(String ruleName, int port, String protocol, bool isAllow) async {
    String action = isAllow ? 'Allow' : 'Block';
    // Gunakan kutip agar aman jika nama mengandung spasi
    String command = 'New-NetFirewallRule -DisplayName \\"$ruleName\\" -Direction Inbound -LocalPort $port -Protocol $protocol -Action $action';
    
    try {
      var result = await Process.run('powershell', [
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-WindowStyle',
        'Hidden',
        '-ArgumentList',
        '"-Command $command"'
      ]);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Membaca status Real-time Monitoring dari Windows Defender
  static Future<bool> getDefenderStatus() async {
    try {
      var result = await Process.run('powershell', [
        '-Command',
        '(Get-MpPreference).DisableRealtimeMonitoring'
      ]);

      String output = result.stdout.toString().trim();
      // DisableRealtimeMonitoring = True artinya Defender MATI.
      // Jadi jika False, artinya Defender NYALA (Terlindungi).
      if (output.toLowerCase() == 'false') {
        return true; // Terlindungi
      }
      return false; // Mati
    } catch (e) {
      return false;
    }
  }

  /// Mengubah status Real-time Monitoring Windows Defender (Membutuhkan UAC & Tamper Protection Mati)
  static Future<bool> setDefenderStatus(bool isEnabled) async {
    // Jika isEnabled = true, maka DisableRealtimeMonitoring = $false
    String state = isEnabled ? '\$false' : '\$true';
    try {
      String command = 'Set-MpPreference -DisableRealtimeMonitoring $state';
      
      var result = await Process.run('powershell', [
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-WindowStyle',
        'Hidden',
        '-ArgumentList',
        '"-Command $command"'
      ]);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
