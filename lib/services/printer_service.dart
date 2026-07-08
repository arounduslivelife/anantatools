import 'dart:io';
import 'dart:convert';

class PrinterInfo {
  final String name;
  final bool isDefault;
  final int status; // 3 = Idle, 4 = Printing, 7 = Offline/Error
  final bool isShared;
  final String portName;
  final String driverName;

  PrinterInfo({
    required this.name,
    required this.isDefault,
    required this.status,
    required this.isShared,
    required this.portName,
    required this.driverName,
  });

  factory PrinterInfo.fromJson(Map<String, dynamic> json) {
    return PrinterInfo(
      name: json['Name']?.toString() ?? 'Unknown Printer',
      isDefault: json['Default'] == true,
      status: json['PrinterStatus'] ?? 3,
      isShared: json['Shared'] == true,
      portName: json['PortName']?.toString() ?? '',
      driverName: json['DriverName']?.toString() ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case 1: return 'Other';
      case 2: return 'Unknown';
      case 3: return 'Idle (Ready)';
      case 4: return 'Printing';
      case 5: return 'Warming Up';
      case 6: return 'Stopped';
      case 7: return 'Offline / Error';
      default: return 'Ready';
    }
  }
}

class PrinterService {
  /// Mengambil daftar printer dari WMI
  static Future<List<PrinterInfo>> getPrinters() async {
    List<PrinterInfo> printers = [];
    try {
      String command = 'Get-WmiObject Win32_Printer | Select-Object Name, Default, PrinterStatus, Shared, PortName, DriverName | ConvertTo-Json -Depth 1';
      var result = await Process.run('powershell', ['-Command', command]);

      if (result.stdout.toString().trim().isNotEmpty) {
        var jsonResult = jsonDecode(result.stdout.toString());
        if (jsonResult is List) {
          for (var item in jsonResult) {
            printers.add(PrinterInfo.fromJson(item));
          }
        } else if (jsonResult is Map) {
          printers.add(PrinterInfo.fromJson(jsonResult as Map<String, dynamic>));
        }
      }
    } catch (e) {
      // Abaikan
    }
    
    // Sort: Default printer pertama, lalu A-Z
    printers.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    
    return printers;
  }

  /// Menjadikan printer sebagai default
  static Future<bool> setDefaultPrinter(String printerName) async {
    try {
      String command = '(New-Object -ComObject WScript.Network).SetDefaultPrinter(\\"$printerName\\")';
      var result = await Process.run('powershell', ['-Command', command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Menghitung jumlah dokumen yang nyangkut di antrean
  static Future<int> getQueuedJobsCount() async {
    try {
      // Mendapatkan jumlah file di folder spool
      String command = '(Get-ChildItem -Path \\"\$env:windir\\System32\\spool\\PRINTERS\\" -File | Measure-Object).Count';
      var result = await Process.run('powershell', ['-Command', command]);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Tombol Nuklir: Menghentikan Spooler, menghapus antrean nyangkut, dan menyalakan Spooler kembali
  static Future<bool> nuclearClearQueue() async {
    try {
      String command = "Stop-Service -Name Spooler -Force; Remove-Item -Path '\$env:windir\\System32\\spool\\PRINTERS\\*.*' -Force -Recurse; Start-Service -Name Spooler";
      var result = await Process.run('powershell', [
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-WindowStyle',
        'Hidden',
        '-Wait',
        '-ArgumentList',
        '"-Command $command"'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Restart Spooler Service saja (Tanpa menghapus antrean)
  static Future<bool> restartSpooler() async {
    try {
      String command = 'Restart-Service -Name Spooler -Force';
      var result = await Process.run('powershell', [
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-WindowStyle',
        'Hidden',
        '-Wait',
        '-ArgumentList',
        '"-Command $command"'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
