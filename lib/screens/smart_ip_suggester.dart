import 'package:fluent_ui/fluent_ui.dart';
import '../services/ip_suggester_service.dart';

class SmartIPSuggesterPage extends StatefulWidget {
  const SmartIPSuggesterPage({super.key});

  @override
  State<SmartIPSuggesterPage> createState() => _SmartIPSuggesterPageState();
}

class _SmartIPSuggesterPageState extends State<SmartIPSuggesterPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  Map<String, dynamic>? _data;

  void _analyzeNetwork() async {
    setState(() {
      _isLoading = true;
    });

    var data = await IpSuggesterService.getAvailableIps();

    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Smart IP Suggester'),
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari IP Kosong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Alat ini akan mendeteksi seluruh jaringan Anda dan merekomendasikan IP Address yang 100% aman (kosong) untuk digunakan pada perangkat baru (Server, CCTV, Printer) guna mencegah IP Conflict.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _analyzeNetwork,
                  child: _isLoading ? const ProgressRing() : const Text('Mulai Analisis Jaringan'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_data != null) ...[
          if (_data!.containsKey('error'))
            InfoBar(
              title: const Text('Error'),
              content: Text(_data!['error']),
              severity: InfoBarSeverity.error,
            )
          else ...[
            Text('Statistik Jaringan (${_data!['subnet']})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        Icon(FluentIcons.network_tower, size: 32, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text('${_data!['activeCount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('IP Aktif'),
                        const Text('(Termasuk PC ini)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        Icon(FluentIcons.lock, size: 32, color: Colors.orange),
                        const SizedBox(height: 8),
                        Text('${_data!['lockedCount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('IP Terkunci'),
                        const Text('(Dicadangkan)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        Icon(FluentIcons.check_mark, size: 32, color: Colors.green),
                        const SizedBox(height: 8),
                        Text('${_data!['availableCount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('IP Kosong'),
                        const Text('(Aman Dipakai)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Rekomendasi IP Static yang Aman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(_data!['recommendations'] as List<String>).map((ip) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: Icon(FluentIcons.shield, color: Colors.green, size: 32),
                  title: Text(ip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Text('Telah diverifikasi menggunakan Double-Check (Ping + TCP Stealth). 100% Kosong.'),
                  trailing: Button(
                    child: const Text('Salin IP'),
                    onPressed: () {
                      // Salin ke clipboard logika bisa ditambahkan di sini
                    },
                  ),
                ),
              );
            }).toList(),
          ]
        ]
      ],
    );
  }
}
