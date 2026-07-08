import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/network_service.dart';
import '../widgets/device_profiler_dialog.dart';

class NetworkScannerPage extends StatefulWidget {
  const NetworkScannerPage({super.key});

  @override
  State<NetworkScannerPage> createState() => _NetworkScannerPageState();
}

class _NetworkScannerPageState extends State<NetworkScannerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isScanning = false;
  double _progress = 0;
  List<Map<String, String>> _devices = [];
  bool _isDeepScan = false;

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _progress = 0;
      _devices = [];
    });

    // Simulasi loading progress bar
    var progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_progress < 90) {
        if (mounted) setState(() => _progress += 2);
      }
    });

    var devices = await NetworkService.scanNetwork(isDeepScan: _isDeepScan);

    progressTimer.cancel();
    
    if (mounted) {
      setState(() {
        _progress = 100;
        _isScanning = false;
        _devices = devices;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk KeepAlive
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Network Scanner'),
        commandBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilledButton(
                  onPressed: _isScanning ? null : _startScan,
                  child: const Text('Scan Sekarang'),
                ),
                const SizedBox(width: 16),
                ToggleSwitch(
                  checked: _isDeepScan,
                  onChanged: _isScanning ? null : (v) => setState(() => _isDeepScan = v),
                  content: const Text('Mode Deep Scan (Siluman)'),
                ),
                const SizedBox(width: 16),
                if (_isScanning) const ProgressRing(),
                if (_isScanning) const SizedBox(width: 16),
                if (_isScanning) Text(_isDeepScan ? 'Menjalankan deteksi siluman (TCP & Ping)...' : 'Mencari perangkat di jaringan...'),
              ],
            ),
          ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isScanning) const ProgressBar(),
            const SizedBox(height: 20),
            Expanded(
              child: _devices.isEmpty
                  ? const Center(
                      child: Text('Belum ada perangkat yang terdeteksi. Tekan "Scan Sekarang" untuk memulai.'),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        IconData iconData = FluentIcons.devices3;
                        String typeLower = device['type']!.toLowerCase();
                        if (typeLower.contains('router') || typeLower.contains('tp-link') || typeLower.contains('mikrotik') || typeLower.contains('ubiquiti') || typeLower.contains('cisco')) {
                          iconData = FluentIcons.network_tower;
                        } else if (typeLower.contains('cctv') || typeLower.contains('hikvision') || typeLower.contains('dahua') || typeLower.contains('uniview')) {
                          iconData = FluentIcons.video;
                        } else if (typeLower.contains('apple') || typeLower.contains('samsung') || typeLower.contains('xiaomi') || typeLower.contains('oppo') || typeLower.contains('vivo') || typeLower.contains('phone')) {
                          iconData = FluentIcons.cell_phone;
                        } else if (typeLower.contains('sony') || typeLower.contains('nintendo')) {
                          iconData = FluentIcons.game;
                        }

                        String subtitle = 'MAC: ${device['mac']}\nVendor: ${device['type']}';
                        if (device.containsKey('hostname') && device['hostname']!.isNotEmpty) {
                          subtitle = 'Hostname: ${device['hostname']}\n$subtitle';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Icon(iconData, size: 32),
                            title: Row(
                              children: [
                                Text(device['ip'] ?? 'Unknown IP', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(FluentIcons.copy, size: 12),
                                  onPressed: () {
                                    if (device['ip'] != null) {
                                      Clipboard.setData(ClipboardData(text: device['ip']!));
                                      displayInfoBar(
                                        context,
                                        builder: (context, close) => const InfoBar(
                                          title: Text('Disalin'),
                                          content: Text('IP Address berhasil disalin.'),
                                          severity: InfoBarSeverity.success,
                                        ),
                                        alignment: Alignment.bottomRight,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            subtitle: Text(subtitle),
                            trailing: Button(
                              child: const Text('Detail'),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => DeviceProfilerDialog(device: device),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
