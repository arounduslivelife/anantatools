import 'dart:io';
import 'dart:convert';
import 'app_config.dart';
import '../data/services_dictionary.dart';

class WindowsServiceInfo {
  final String name;
  final String displayName;
  final String state; // Running, Stopped, dll
  final String startMode; // Auto, Manual, Disabled
  final String description;
  final String pathName;
  final bool isSystemCore;

  WindowsServiceInfo({
    required this.name,
    required this.displayName,
    required this.state,
    required this.startMode,
    required this.description,
    required this.pathName,
    required this.isSystemCore,
  });

  factory WindowsServiceInfo.fromJson(Map<String, dynamic> json) {
    String path = json['PathName']?.toString() ?? '';
    
    // SABUK PENGAMAN (Safety Filter)
    bool core = false;
    String lowerPath = path.toLowerCase();
    if (lowerPath.contains('c:\\windows\\system32') || 
        lowerPath.contains('c:\\windows\\syswow64') ||
        lowerPath.contains('svchost.exe') ||
        lowerPath.contains('lsass.exe') ||
        lowerPath.contains('services.exe')) {
      core = true;
    }

    return WindowsServiceInfo(
      name: json['Name']?.toString() ?? 'Unknown',
      displayName: json['DisplayName']?.toString() ?? 'Unknown',
      state: json['State']?.toString() ?? 'Unknown',
      startMode: json['StartMode']?.toString() ?? 'Unknown',
      description: json['Description']?.toString() ?? 'Tidak ada deskripsi tersedia.',
      pathName: path,
      isSystemCore: core,
    );
  }
}

class ServicesService {
  /// Mengambil semua daftar services beserta deskripsinya melalui WMI
  static Future<List<WindowsServiceInfo>> getServices() async {
    List<WindowsServiceInfo> services = [];
    try {
      String command = 'Get-WmiObject Win32_Service | Select-Object Name, DisplayName, State, StartMode, Description, PathName | ConvertTo-Json -Depth 1';
      var result = await Process.run('powershell', ['-Command', command]);

      if (result.stdout.toString().trim().isNotEmpty) {
        var jsonResult = jsonDecode(result.stdout.toString());
        if (jsonResult is List) {
          for (var item in jsonResult) {
            var serviceInfo = WindowsServiceInfo.fromJson(item);
            
            // Terapkan Kamus Masif Eksternal jika setting terjemahan aktif
            if (AppConfig.translateServices) {
              String? translation = ServicesDictionary.getTranslation(serviceInfo.name);
              if (translation != null) {
                serviceInfo = WindowsServiceInfo(
                  name: serviceInfo.name,
                  displayName: serviceInfo.displayName,
                  state: serviceInfo.state,
                  startMode: serviceInfo.startMode,
                  description: translation,
                  pathName: serviceInfo.pathName,
                  isSystemCore: serviceInfo.isSystemCore,
                );
              }
            }
            
            services.add(serviceInfo);
          }
        }
      }
    } catch (e) {
      // abaikan error
    }
    
    // Sort A-Z by DisplayName
    services.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return services;
  }

  /// Mengubah state dari service (Start, Stop, Restart) - Membutuhkan UAC
  static Future<bool> changeServiceState(String name, String action) async {
    // action: 'Start-Service', 'Stop-Service', 'Restart-Service'
    try {
      String command = '$action -Name \\"$name\\" -Force';
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

  /// Mengubah tipe startup (Automatic, Manual, Disabled) - Membutuhkan UAC
  static Future<bool> changeStartupType(String name, String startType) async {
    // startType: 'Automatic', 'Manual', 'Disabled'
    try {
      String command = 'Set-Service -Name \\"$name\\" -StartupType $startType';
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
