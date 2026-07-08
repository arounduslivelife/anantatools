import 'dart:io';

class PortScannerService {
  /// Memindai daftar port tertentu pada sebuah IP.
  /// Menggunakan batching untuk mencegah kehabisan file descriptor OS.
  static Future<List<int>> scanPorts(String ip, List<int> portsToScan, {void Function(int totalScanned)? onProgress}) async {
    List<int> openPorts = [];
    
    // Batch size untuk mencegah error socket OS (biasanya Windows membatasi koneksi simultan)
    int batchSize = 100; 
    int scannedCount = 0;

    for (int i = 0; i < portsToScan.length; i += batchSize) {
      int end = (i + batchSize < portsToScan.length) ? i + batchSize : portsToScan.length;
      List<int> currentBatch = portsToScan.sublist(i, end);

      List<Future<void>> futures = currentBatch.map((port) async {
        try {
          // Timeout agresif 500ms
          var socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 500));
          openPorts.add(port);
          socket.destroy();
        } catch (e) {
          // Port tertutup atau timeout
        }
      }).toList();

      await Future.wait(futures);
      scannedCount += currentBatch.length;
      if (onProgress != null) {
        onProgress(scannedCount);
      }
    }

    // Urutkan port dari terkecil ke terbesar
    openPorts.sort();
    return openPorts;
  }

  /// Mengembalikan daftar port umum yang paling sering dipakai teknisi IT
  static List<int> getCommonPorts() {
    return [
      21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 
      993, 995, 1723, 3306, 3389, 5432, 5900, 8000, 8080, 8443
    ];
  }

  /// Mengembalikan daftar port dari 1 - 1024 (Well Known Ports)
  static List<int> getWellKnownPorts() {
    return List<int>.generate(1024, (i) => i + 1);
  }

  static String getServiceName(int port) {
    Map<int, String> services = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      111: 'RPC',
      135: 'MSRPC',
      139: 'NetBIOS',
      143: 'IMAP',
      443: 'HTTPS',
      445: 'SMB',
      993: 'IMAPS',
      995: 'POP3S',
      1723: 'PPTP',
      3306: 'MySQL',
      3389: 'RDP (Remote Desktop)',
      5432: 'PostgreSQL',
      5900: 'VNC',
      8000: 'HTTP Alt',
      8080: 'HTTP Proxy',
      8443: 'HTTPS Alt',
    };
    return services[port] ?? 'Unknown Service';
  }
}
