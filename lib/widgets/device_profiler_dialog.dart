import 'dart:io';
import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';

class DeviceProfilerDialog extends StatefulWidget {
  final Map<String, String> device;

  const DeviceProfilerDialog({super.key, required this.device});

  @override
  State<DeviceProfilerDialog> createState() => _DeviceProfilerDialogState();
}

class _DeviceProfilerDialogState extends State<DeviceProfilerDialog> {
  int _currentIndex = 0; // 0 = Ping, 1 = Port Scan

  // Ping State
  Process? _pingProcess;
  bool _isPinging = false;
  final ScrollController _pingScrollController = ScrollController();
  final List<String> _pingLogs = [];

  // Port Scan State
  bool _isScanningPorts = false;
  final Map<int, bool?> _portResults = {}; // null: waiting, true: open, false: closed
  final Map<int, String> _targetPorts = {
    80: 'HTTP (Web)',
    443: 'HTTPS (Web Secure)',
    8080: 'HTTP Alternate',
    21: 'FTP (File Transfer)',
    22: 'SSH (Remote CLI)',
    23: 'Telnet (Insecure CLI)',
    3389: 'RDP (Remote Desktop)',
    445: 'SMB (Windows Share)',
    135: 'RPC (Windows)',
    554: 'RTSP (CCTV Video)',
    8000: 'DVR/NVR (CCTV)',
    3306: 'MySQL (Database)',
    5432: 'PostgreSQL (Database)',
    1433: 'SQL Server (Database)',
    5555: 'ADB (Android Debug)',
    8008: 'Google Cast',
    62078: 'Apple Sync',
    7000: 'AirPlay'
  };

  @override
  void dispose() {
    _pingProcess?.kill();
    _pingScrollController.dispose();
    super.dispose();
  }

  void _togglePing() async {
    if (_isPinging) {
      _pingProcess?.kill();
      setState(() {
        _isPinging = false;
        _pingLogs.add('--- Ping stopped ---');
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _isPinging = true;
      _pingLogs.add('--- Starting Ping to ${widget.device['ip']} ---');
    });

    try {
      _pingProcess = await Process.start('ping', ['-t', widget.device['ip']!]);
      _pingProcess!.stdout.transform(utf8.decoder).listen((data) {
        if (!mounted) return;
        List<String> lines = data.split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            setState(() {
              _pingLogs.add(line.trim());
            });
            _scrollToBottom();
          }
        }
      });
    } catch (e) {
      setState(() {
        _pingLogs.add('Error starting ping: $e');
        _isPinging = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_pingScrollController.hasClients) {
        _pingScrollController.jumpTo(_pingScrollController.position.maxScrollExtent);
      }
    });
  }

  void _startPortScan() async {
    setState(() {
      _isScanningPorts = true;
      _portResults.clear();
      for (var port in _targetPorts.keys) {
        _portResults[port] = null; // Set semua jadi pending
      }
    });

    String ip = widget.device['ip']!;
    List<Future<void>> scanTasks = [];

    for (var port in _targetPorts.keys) {
      scanTasks.add(_scanSinglePort(ip, port));
    }

    await Future.wait(scanTasks);

    if (mounted) {
      setState(() {
        _isScanningPorts = false;
      });
    }
  }

  Future<void> _scanSinglePort(String ip, int port) async {
    try {
      Socket socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 1500));
      socket.destroy();
      if (mounted) {
        setState(() => _portResults[port] = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _portResults[port] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Device Profiler: ${widget.device['ip']}'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Info
          InfoLabel(label: 'MAC Address:', child: Text(widget.device['mac'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          InfoLabel(label: 'Vendor:', child: Text(widget.device['type'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
          if ((widget.device['hostname'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            InfoLabel(label: 'Hostname:', child: Text(widget.device['hostname']!, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          const SizedBox(height: 16),
          
          // Tabbed Content (Using TabView)
          Expanded(
            child: TabView(
              currentIndex: _currentIndex,
              onChanged: (index) => setState(() => _currentIndex = index),
              tabs: [
                Tab(
                  text: const Text('Live Ping'),
                  icon: const Icon(FluentIcons.network_tower),
                  body: _buildPingTab(),
                ),
                Tab(
                  text: const Text('Deep Port Scan'),
                  icon: const Icon(FluentIcons.search),
                  body: _buildPortScanTab(),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Tutup'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildPingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Button(
          onPressed: _togglePing,
          child: Text(_isPinging ? 'Stop Ping' : 'Mulai Ping Terus-menerus (-t)'),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              controller: _pingScrollController,
              itemCount: _pingLogs.length,
              itemBuilder: (context, index) {
                String line = _pingLogs[index];
                Color textColor = Colors.white;
                if (line.contains('timed out') || line.contains('unreachable') || line.contains('RTO')) {
                  textColor = Colors.red;
                } else if (line.contains('Reply from')) {
                  textColor = Colors.green;
                }
                
                return Text(
                  line,
                  style: TextStyle(fontFamily: 'Consolas', color: textColor, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortScanTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(
              onPressed: _isScanningPorts ? null : _startPortScan,
              child: const Text('Mulai Deep Port Scan'),
            ),
            const SizedBox(width: 16),
            if (_isScanningPorts) const ProgressRing(strokeWidth: 2.5),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _targetPorts.length,
            itemBuilder: (context, index) {
              int port = _targetPorts.keys.elementAt(index);
              String desc = _targetPorts[port]!;
              bool? result = _portResults[port];

              IconData icon = FluentIcons.unknown;
              Color color = Colors.grey;
              if (result == true) {
                icon = FluentIcons.check_mark;
                color = Colors.green;
              } else if (result == false) {
                icon = FluentIcons.status_circle_error_x;
                color = Colors.red;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Port $port\n$desc',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
