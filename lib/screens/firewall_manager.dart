import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../services/firewall_service.dart';

class FirewallManagerPage extends StatefulWidget {
  const FirewallManagerPage({super.key});

  @override
  State<FirewallManagerPage> createState() => _FirewallManagerPageState();
}

class _FirewallManagerPageState extends State<FirewallManagerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  Map<String, bool> _firewallStatus = {
    'Domain': false,
    'Private': false,
    'Public': false,
  };
  bool _defenderStatus = false;

  // Rule Builder Form
  final TextEditingController _ruleNameCtrl = TextEditingController();
  final TextEditingController _rulePortCtrl = TextEditingController();
  String _ruleProtocol = 'TCP';
  bool _ruleIsAllow = true;
  bool _isApplyingRule = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  void _fetchStatus() async {
    setState(() => _isLoading = true);
    var status = await FirewallService.getFirewallStatus();
    var defStatus = await FirewallService.getDefenderStatus();
    
    if (mounted) {
      setState(() {
        _firewallStatus = status;
        _defenderStatus = defStatus;
        _isLoading = false;
      });
    }
  }

  void _toggleFirewall(String profile, bool newValue) async {
    // Optimistic UI update
    setState(() {
      _firewallStatus[profile] = newValue;
    });

    _showToast('Meminta otorisasi Administrator (UAC)...', severity: InfoBarSeverity.info);
    bool success = await FirewallService.setFirewallStatus(profile, newValue);
    
    if (success) {
      // Beri jeda sedikit agar powershell di belakang layar selesai bekerja
      await Future.delayed(const Duration(seconds: 2));
      _fetchStatus();
      _showToast('Berhasil mengubah status Firewall $profile.', severity: InfoBarSeverity.success);
    } else {
      // Revert jika gagal
      _fetchStatus();
      _showToast('Gagal mengubah Firewall atau UAC ditolak.', severity: InfoBarSeverity.error);
    }
  }

  void _toggleDefender(bool newValue) async {
    setState(() => _defenderStatus = newValue);
    _showToast('Meminta otorisasi Administrator (UAC)...', severity: InfoBarSeverity.info);
    bool success = await FirewallService.setDefenderStatus(newValue);
    
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      _fetchStatus();
      _showToast('Berhasil mengubah status Windows Defender.', severity: InfoBarSeverity.success);
    } else {
      _fetchStatus();
      _showToast('Gagal! Pastikan "Tamper Protection" sudah dimatikan di Windows Security.', severity: InfoBarSeverity.error);
    }
  }

  void _addRule() async {
    if (_ruleNameCtrl.text.isEmpty || _rulePortCtrl.text.isEmpty) {
      _showToast('Nama Aturan dan Port tidak boleh kosong!', severity: InfoBarSeverity.warning);
      return;
    }

    int? port = int.tryParse(_rulePortCtrl.text);
    if (port == null || port < 1 || port > 65535) {
      _showToast('Port harus berupa angka antara 1 - 65535!', severity: InfoBarSeverity.warning);
      return;
    }

    setState(() => _isApplyingRule = true);
    _showToast('Meminta otorisasi Administrator (UAC)...', severity: InfoBarSeverity.info);

    bool success = await FirewallService.addPortRule(_ruleNameCtrl.text, port, _ruleProtocol, _ruleIsAllow);
    
    if (mounted) {
      setState(() => _isApplyingRule = false);
    }

    if (success) {
      _showToast('Aturan Firewall berhasil ditambahkan!', severity: InfoBarSeverity.success);
      _ruleNameCtrl.clear();
      _rulePortCtrl.clear();
    } else {
      _showToast('Gagal menambahkan aturan atau UAC ditolak.', severity: InfoBarSeverity.error);
    }
  }

  void _showToast(String message, {InfoBarSeverity severity = InfoBarSeverity.info}) {
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
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Windows Security Manager'),
        commandBar: _isLoading
            ? const ProgressRing()
            : FilledButton(
                onPressed: _fetchStatus,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(FluentIcons.refresh), SizedBox(width: 8), Text('Refresh Status')],
                ),
              ),
      ),
      children: [
        const InfoBar(
          title: Text('Peringatan Administratif'),
          content: Text('Semua perubahan pada halaman ini akan mengubah konfigurasi keamanan inti Windows. Jendela UAC kuning akan muncul setiap kali Anda melakukan modifikasi. Harap tekan "Yes".'),
          severity: InfoBarSeverity.warning,
          isLong: true,
        ),
        const SizedBox(height: 24),
        
        // Windows Defender Section
        const Text('Windows Defender Antivirus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Real-time Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Matikan sementara saat Anda butuh mengekstrak/menjalankan file yang selalu dihapus oleh Defender (misal: crack/patch).', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      const InfoBar(
                        title: Text('Perhatian: Tamper Protection'),
                        content: Text('Jika Windows versi terbaru Anda memiliki fitur "Tamper Protection" yang menyala, maka saklar ini akan diabaikan oleh Windows. Anda harus mematikan Tamper Protection secara manual di Settings terlebih dahulu.'),
                        severity: InfoBarSeverity.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ToggleSwitch(
                  checked: _defenderStatus,
                  onChanged: _toggleDefender,
                  content: Text(_defenderStatus ? 'ON (Aman)' : 'OFF (Rentan)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Firewall Status Cards
        const Text('Status Windows Firewall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildProfileCard('Domain', 'Jaringan tempat kerja/perusahaan', _firewallStatus['Domain']!)),
            const SizedBox(width: 16),
            Expanded(child: _buildProfileCard('Private', 'Jaringan rumah (Aman)', _firewallStatus['Private']!)),
            const SizedBox(width: 16),
            Expanded(child: _buildProfileCard('Public', 'Jaringan publik (Kafe/Bandara)', _firewallStatus['Public']!)),
          ],
        ),
        
        const SizedBox(height: 32),

        // Rule Builder
        const Text('Port Rule Builder (Inbound)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        const Text('Buka atau blokir port tertentu agar aplikasi Anda (misal: CCTV, Database) bisa diakses dari jaringan.'),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InfoLabel(
                        label: 'Nama Aturan (Bebas)',
                        child: TextBox(
                          controller: _ruleNameCtrl,
                          placeholder: 'Contoh: Buka Port Database MySQL',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: InfoLabel(
                        label: 'Port Tujuan',
                        child: TextBox(
                          controller: _rulePortCtrl,
                          placeholder: 'Contoh: 3306',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InfoLabel(
                        label: 'Protokol Jaringan',
                        child: ComboBox<String>(
                          isExpanded: true,
                          value: _ruleProtocol,
                          items: const [
                            ComboBoxItem(value: 'TCP', child: Text('TCP (Paling Umum)')),
                            ComboBoxItem(value: 'UDP', child: Text('UDP (Game/Video)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _ruleProtocol = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoLabel(
                        label: 'Aksi Aturan',
                        child: ComboBox<bool>(
                          isExpanded: true,
                          value: _ruleIsAllow,
                          items: const [
                            ComboBoxItem(value: true, child: Text('Allow (Izinkan Akses)')),
                            ComboBoxItem(value: false, child: Text('Block (Blokir Akses)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _ruleIsAllow = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isApplyingRule ? null : _addRule,
                  child: _isApplyingRule 
                      ? const Text('Menerapkan Aturan...') 
                      : const Text('Eksekusi & Terapkan Aturan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(String title, String desc, bool isEnabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(
                  isEnabled ? FluentIcons.check_mark : FluentIcons.status_circle_error_x,
                  color: isEnabled ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ToggleSwitch(
              checked: isEnabled,
              onChanged: (v) => _toggleFirewall(title, v),
              content: Text(isEnabled ? 'ON (Terlindungi)' : 'OFF (Rentan)'),
            ),
          ],
        ),
      ),
    );
  }
}
