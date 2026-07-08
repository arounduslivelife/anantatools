import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/port_scanner_service.dart';

class PortScannerPage extends StatefulWidget {
  const PortScannerPage({super.key});

  @override
  State<PortScannerPage> createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _ipController = TextEditingController();
  
  bool _isScanning = false;
  int _scanMode = 0; // 0 = Common, 1 = 1-1024
  
  double _progress = 0;
  List<int> _openPorts = [];
  bool _scanComplete = false;

  void _startScan() async {
    if (_ipController.text.isEmpty) {
      _showError('Masukkan IP target terlebih dahulu.');
      return;
    }

    setState(() {
      _isScanning = true;
      _progress = 0;
      _openPorts = [];
      _scanComplete = false;
    });

    List<int> targetPorts = _scanMode == 0 
        ? PortScannerService.getCommonPorts() 
        : PortScannerService.getWellKnownPorts();

    int totalPorts = targetPorts.length;

    var results = await PortScannerService.scanPorts(
      _ipController.text, 
      targetPorts,
      onProgress: (scanned) {
        if (mounted) {
          setState(() {
            _progress = (scanned / totalPorts) * 100;
          });
        }
      }
    );

    if (mounted) {
      setState(() {
        _isScanning = false;
        _openPorts = results;
        _scanComplete = true;
      });
    }
  }

  void _showError(String msg) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: const Text('Error'),
          content: Text(msg),
          severity: InfoBarSeverity.error,
        );
      },
      alignment: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Deep Port Scanner'),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pemindai Keamanan Jaringan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Alat ini mencoba melakukan koneksi ke berbagai port untuk mendeteksi layanan apa saja yang sedang berjalan (listening) pada perangkat target.'),
                const SizedBox(height: 24),
                
                InfoLabel(
                  label: 'Target IP Address / Domain',
                  child: TextBox(
                    controller: _ipController,
                    placeholder: 'Contoh: 192.168.1.1 atau google.com',
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Mode Pemindaian', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ComboBox<int>(
                  value: _scanMode,
                  items: const [
                    ComboBoxItem(value: 0, child: Text('Fast Scan (20 Port Umum IT)')),
                    ComboBoxItem(value: 1, child: Text('Deep Scan (Port 1 - 1024)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _scanMode = val);
                  },
                ),
                const SizedBox(height: 24),
                
                FilledButton(
                  onPressed: _isScanning ? null : _startScan,
                  child: _isScanning ? const Text('Scanning...') : const Text('Mulai Scan'),
                ),
                
                if (_isScanning) ...[
                  const SizedBox(height: 16),
                  ProgressBar(value: _progress),
                  const SizedBox(height: 8),
                  Text('Progress: ${_progress.toStringAsFixed(1)}%'),
                ]
              ],
            ),
          ),
        ),
        
        if (_scanComplete) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hasil Pemindaian (${_openPorts.length} Port Terbuka)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              if (_openPorts.isNotEmpty)
                Button(
                  child: const Row(
                    children: [Icon(FluentIcons.copy, size: 14), SizedBox(width: 8), Text('Salin Hasil')],
                  ),
                  onPressed: () {
                    String results = 'Scan Result for ${_ipController.text}:\n';
                    for (var port in _openPorts) {
                      results += 'Port $port (${PortScannerService.getServiceName(port)})\n';
                    }
                    Clipboard.setData(ClipboardData(text: results));
                    displayInfoBar(
                      context,
                      builder: (context, close) => const InfoBar(
                        title: Text('Disalin'),
                        content: Text('Hasil scan port berhasil disalin.'),
                        severity: InfoBarSeverity.success,
                      ),
                      alignment: Alignment.bottomRight,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_openPorts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Tidak ada port terbuka yang terdeteksi (semua Stealth/Closed).', style: TextStyle(color: Colors.green)),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FixedColumnWidth(100),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(120),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1)),
                  children: const [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('PORT', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('LAYANAN (SERVICE)', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ..._openPorts.map((port) {
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(port.toString())),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(PortScannerService.getServiceName(port))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('OPEN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ],
                  );
                }).toList(),
              ],
            ),
        ]
      ],
    );
  }
}
