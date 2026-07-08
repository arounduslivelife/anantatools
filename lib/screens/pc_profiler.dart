import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/pc_profiler_service.dart';

class PcProfilerPage extends StatefulWidget {
  const PcProfilerPage({super.key});

  @override
  State<PcProfilerPage> createState() => _PcProfilerPageState();
}

class _PcProfilerPageState extends State<PcProfilerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    setState(() => _isLoading = true);
    var data = await PcProfilerService.getSystemProfile();
    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String title, String value) {
    Clipboard.setData(ClipboardData(text: value));
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Disalin'),
        content: Text('$title berhasil disalin.'),
        severity: InfoBarSeverity.success,
      ),
      alignment: Alignment.bottomRight,
    );
  }

  String _formatBytes(String? bytesStr) {
    if (bytesStr == null || bytesStr.isEmpty) return 'Unknown';
    try {
      double bytes = double.parse(bytesStr);
      double gb = bytes / (1024 * 1024 * 1024);
      if (gb >= 1000) {
        double tb = gb / 1024;
        return '${tb.toStringAsFixed(2)} TB';
      }
      return '${gb.toStringAsFixed(2)} GB';
    } catch (e) {
      return bytesStr;
    }
  }

  Widget _buildInfoRow(String label, String? value, {bool copyable = true}) {
    String safeValue = value ?? 'Tidak Diketahui';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(safeValue),
          ),
          if (copyable && safeValue != 'Tidak Diketahui' && safeValue.isNotEmpty)
            IconButton(
              icon: const Icon(FluentIcons.copy, size: 12),
              onPressed: () => _copyToClipboard(label, safeValue),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Deep PC Profiler'),
        commandBar: _isLoading
            ? const ProgressRing()
            : FilledButton(
                onPressed: _fetchProfile,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(FluentIcons.refresh), SizedBox(width: 8), Text('Refresh')],
                ),
              ),
      ),
      children: [
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Menggali data inti sistem...')))
        else if (_profileData != null) ...[
          // OS & CPU ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionCard('Sistem Operasi', FluentIcons.devices3, [
                  _buildInfoRow('Nama OS', _profileData!['os']?['Caption']),
                  _buildInfoRow('Arsitektur', _profileData!['os']?['OSArchitecture']),
                  _buildInfoRow('Versi', _profileData!['os']?['Version']),
                  _buildInfoRow('Build', _profileData!['os']?['BuildNumber']),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSectionCard('Prosesor (CPU)', FluentIcons.processing, [
                  _buildInfoRow('Nama CPU', _profileData!['cpu']?['Name']),
                  _buildInfoRow('Jumlah Core', _profileData!['cpu']?['NumberOfCores']),
                  _buildInfoRow('Logical Processors', _profileData!['cpu']?['NumberOfLogicalProcessors']),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // RAM & Motherboard ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionCard('Memori (RAM)', FluentIcons.save, [
                  _buildInfoRow('Kapasitas Total', '${_profileData!['ram']?['TotalGB'] ?? '?'} GB'),
                  _buildInfoRow('Kapasitas Bebas', '${_profileData!['ram']?['FreeGB'] ?? '?'} GB'),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSectionCard('Motherboard', FluentIcons.settings, [
                  _buildInfoRow('Pabrikan', _profileData!['motherboard']?['Manufacturer']),
                  _buildInfoRow('Produk (Model)', _profileData!['motherboard']?['Product']),
                  _buildInfoRow('Serial Number', _profileData!['motherboard']?['SerialNumber']),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Penyimpanan
          const Text('Penyimpanan Fisik (Hardisk/SSD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          if (_profileData!['disks'] != null && _profileData!['disks'] is List)
            ...(_profileData!['disks'] as List).map((disk) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoRow('Model', disk['Model']),
                        _buildInfoRow('Kapasitas', _formatBytes(disk['Size'])),
                        _buildInfoRow('Serial Number', disk['SerialNumber']),
                        _buildInfoRow('Interface', disk['InterfaceType']),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
          const SizedBox(height: 16),
          
          // Jaringan
          const Text('Adapter Jaringan Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          if (_profileData!['networks'] != null && _profileData!['networks'] is List)
            ...(_profileData!['networks'] as List).map((net) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInfoRow('Adapter', net['Name']),
                        _buildInfoRow('MAC Address', net['MACAddress']),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
        ],
      ],
    );
  }
}
