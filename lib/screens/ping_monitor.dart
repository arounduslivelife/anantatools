import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/ping_service.dart';

class MonitoredTarget {
  String host;
  String macAddress;
  bool isOnline;
  int latencyMs;
  String message;

  MonitoredTarget({
    required this.host,
    this.macAddress = '',
    this.isOnline = false,
    this.latencyMs = 0,
    this.message = 'Menunggu Pengecekan...',
  });
}

class PingMonitorPage extends StatefulWidget {
  const PingMonitorPage({super.key});

  @override
  State<PingMonitorPage> createState() => _PingMonitorPageState();
}

class _PingMonitorPageState extends State<PingMonitorPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _hostCtrl = TextEditingController();
  final TextEditingController _macCtrl = TextEditingController();

  List<MonitoredTarget> _targets = [
    MonitoredTarget(host: '1.1.1.1', message: 'Cloudflare DNS'), // Target dummy
  ];

  bool _isAutoPing = false;
  int _intervalSeconds = 3;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _hostCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  void _addTarget() {
    if (_hostCtrl.text.trim().isEmpty) return;
    setState(() {
      _targets.add(MonitoredTarget(
        host: _hostCtrl.text.trim(),
        macAddress: _macCtrl.text.trim(),
      ));
    });
    _hostCtrl.clear();
    _macCtrl.clear();
    _pingAll(); // Langsung cek satu kali
  }

  void _removeTarget(int index) {
    setState(() {
      _targets.removeAt(index);
    });
  }

  void _toggleAutoPing(bool value) {
    setState(() {
      _isAutoPing = value;
      if (_isAutoPing) {
        _startAutoPing();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startAutoPing() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (timer) {
      if (!mounted || !_isAutoPing) {
        timer.cancel();
        return;
      }
      _pingAll();
    });
  }

  void _updateInterval(String? value) {
    if (value != null) {
      setState(() {
        _intervalSeconds = int.parse(value);
        if (_isAutoPing) {
          _startAutoPing(); // Restart timer dengan interval baru
        }
      });
    }
  }

  Future<void> _pingAll() async {
    for (int i = 0; i < _targets.length; i++) {
      if (!mounted) break;
      var target = _targets[i];
      var result = await PingService.ping(target.host);
      
      if (mounted) {
        setState(() {
          target.isOnline = result.isOnline;
          target.latencyMs = result.latencyMs;
          target.message = result.message;
        });
      }
    }
  }

  Future<void> _pingSingle(int index) async {
    var target = _targets[index];
    setState(() {
      target.message = 'Pinging...';
    });
    var result = await PingService.ping(target.host);
    if (mounted) {
      setState(() {
        target.isOnline = result.isOnline;
        target.latencyMs = result.latencyMs;
        target.message = result.message;
      });
    }
  }

  void _sendWakeOnLan(MonitoredTarget target) async {
    if (target.macAddress.isEmpty) {
      _showToast('MAC Address belum diisi untuk ${target.host}!', InfoBarSeverity.warning);
      return;
    }

    bool success = await PingService.wakeOnLan(target.macAddress);
    if (success) {
      _showToast(
        'Magic Packet dikirim ke ${target.macAddress}. \\nCatatan: PC target harus terhubung via kabel LAN dan opsi Wake-on-LAN di BIOS/UEFI harus diaktifkan agar alat ini berfungsi.',
        InfoBarSeverity.success,
      );
    } else {
      _showToast('Format MAC Address salah. Gunakan format seperti 00:1A:2B:3C:4D:5E', InfoBarSeverity.error);
    }
  }

  void _showToast(String message, InfoBarSeverity severity) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(severity == InfoBarSeverity.error ? 'Error' : 'Info'),
        content: Text(message),
        severity: severity,
      ),
      alignment: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Ping Monitor & Wake-on-LAN'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Auto-Ping Interval:'),
            const SizedBox(width: 8),
            ComboBox<String>(
              value: _intervalSeconds.toString(),
              items: const [
                ComboBoxItem(value: '3', child: Text('3 Detik')),
                ComboBoxItem(value: '5', child: Text('5 Detik')),
                ComboBoxItem(value: '10', child: Text('10 Detik')),
                ComboBoxItem(value: '30', child: Text('30 Detik')),
              ],
              onChanged: _isAutoPing ? null : _updateInterval,
            ),
            const SizedBox(width: 16),
            ToggleSwitch(
              checked: _isAutoPing,
              onChanged: _toggleAutoPing,
              content: const Text('Auto-Ping'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: _isAutoPing ? null : _pingAll,
              child: const Row(
                children: [Icon(FluentIcons.play), SizedBox(width: 8), Text('Ping Sekarang (Manual)')],
              ),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Tambah Target
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: InfoLabel(
                        label: 'IP Address / Hostname',
                        child: TextBox(
                          controller: _hostCtrl,
                          placeholder: 'Contoh: 192.168.1.100',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: InfoLabel(
                        label: 'MAC Address (Opsional untuk WoL)',
                        child: TextBox(
                          controller: _macCtrl,
                          placeholder: 'Contoh: 1A:2B:3C:4D:5E:6F',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Button(
                      onPressed: _addTarget,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Tambahkan Target'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Daftar Target
            const Text('Daftar Monitoring', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _targets.length,
                itemBuilder: (context, index) {
                  return _buildTargetCard(_targets[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(MonitoredTarget target, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Indikator Status
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: target.isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Host
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(target.host, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(target.message, style: TextStyle(color: target.isOnline ? Colors.green : Colors.red)),
                      if (target.isOnline) ...[
                        const SizedBox(width: 8),
                        Text('|  Ping: ${target.latencyMs} ms', style: const TextStyle(color: Colors.grey)),
                      ]
                    ],
                  ),
                  if (target.macAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('MAC: ${target.macAddress}', style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                ],
              ),
            ),
            
            // Aksi
            Row(
              children: [
                if (!target.isOnline)
                  Tooltip(
                    message: 'Kirim Magic Packet (Wake-on-LAN)',
                    child: IconButton(
                      icon: Icon(FluentIcons.lightning_bolt, color: Colors.orange, size: 20),
                      onPressed: () => _sendWakeOnLan(target),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FluentIcons.refresh),
                  onPressed: _isAutoPing ? null : () => _pingSingle(index),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(FluentIcons.delete, color: Colors.red),
                  onPressed: () => _removeTarget(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
