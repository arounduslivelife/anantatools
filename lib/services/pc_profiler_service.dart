import 'dart:io';

class PcProfilerService {
  /// Mendapatkan seluruh profil informasi PC secara asinkron
  static Future<Map<String, dynamic>> getSystemProfile() async {
    Map<String, dynamic> profile = {};

    try {
      // 1. Dapatkan info OS
      var osResult = await Process.run('wmic', ['os', 'get', 'Caption,Version,OSArchitecture,BuildNumber', '/value']);
      profile['os'] = _parseWmic(osResult.stdout);

      // 2. Dapatkan info CPU
      var cpuResult = await Process.run('wmic', ['cpu', 'get', 'Name,NumberOfCores,NumberOfLogicalProcessors', '/value']);
      profile['cpu'] = _parseWmic(cpuResult.stdout);

      // 3. Dapatkan info RAM
      var ramResult = await Process.run('wmic', ['OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/value']);
      var ramData = _parseWmic(ramResult.stdout);
      
      // Konversi KB ke GB
      if (ramData.containsKey('TotalVisibleMemorySize')) {
        double totalGb = int.parse(ramData['TotalVisibleMemorySize']!) / (1024 * 1024);
        ramData['TotalGB'] = totalGb.toStringAsFixed(2);
      }
      if (ramData.containsKey('FreePhysicalMemory')) {
        double freeGb = int.parse(ramData['FreePhysicalMemory']!) / (1024 * 1024);
        ramData['FreeGB'] = freeGb.toStringAsFixed(2);
      }
      profile['ram'] = ramData;

      // 4. Dapatkan info Motherboard
      var moboResult = await Process.run('wmic', ['baseboard', 'get', 'Manufacturer,Product,SerialNumber', '/value']);
      profile['motherboard'] = _parseWmic(moboResult.stdout);

      // 5. Dapatkan info Penyimpanan (Disk Drives) - Bisa lebih dari 1
      var diskResult = await Process.run('wmic', ['diskdrive', 'get', 'Model,Size,SerialNumber,InterfaceType', '/value']);
      profile['disks'] = _parseWmicList(diskResult.stdout);

      // 6. Dapatkan info Network Adapters aktif
      var netResult = await Process.run('wmic', ['nic', 'where', 'NetEnabled=true', 'get', 'Name,MACAddress', '/value']);
      profile['networks'] = _parseWmicList(netResult.stdout);

    } catch (e) {
      profile['error'] = e.toString();
    }

    return profile;
  }

  /// Mem-parsing output wmic dalam bentuk key-value berurutan
  static Map<String, String> _parseWmic(String raw) {
    Map<String, String> result = {};
    var lines = raw.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty && line.contains('=')) {
        var parts = line.split('=');
        if (parts.length >= 2) {
          result[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
    return result;
  }

  /// Mem-parsing output wmic yang menghasilkan array objek
  static List<Map<String, String>> _parseWmicList(String raw) {
    List<Map<String, String>> results = [];
    Map<String, String> currentObject = {};
    
    var lines = raw.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        if (currentObject.isNotEmpty) {
          results.add(Map.from(currentObject));
          currentObject.clear();
        }
      } else if (line.contains('=')) {
        var parts = line.split('=');
        if (parts.length >= 2) {
          currentObject[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
    
    if (currentObject.isNotEmpty) {
      results.add(currentObject);
    }
    
    return results;
  }
}
