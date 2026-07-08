import 'package:fluent_ui/fluent_ui.dart';
import '../services/app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = AppConfig.uiLanguage;
  bool _translateServices = AppConfig.translateServices;
  String _selectedTheme = AppConfig.themeMode;

  void _saveConfig() {
    AppConfig.uiLanguage = _selectedLanguage;
    AppConfig.translateServices = _translateServices;
    AppConfig.themeMode = _selectedTheme;
    AppConfig.save();
  }

  void _showRestartToast() {
    displayInfoBar(
      context,
      builder: (context, close) => const InfoBar(
        title: Text('Pengaturan Disimpan'),
        content: Text('Silakan muat ulang (restart) aplikasi agar perubahan bahasa diterapkan ke seluruh halaman.'),
        severity: InfoBarSeverity.success,
      ),
      alignment: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Pengaturan Aplikasi (Settings)'),
      ),
      children: [
        // Bagian Bahasa
        const Text('Bahasa & Terjemahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLabel(
                  label: 'Bahasa Antarmuka Aplikasi (UI Language)',
                  child: ComboBox<String>(
                    isExpanded: true,
                    value: _selectedLanguage,
                    items: const [
                      ComboBoxItem(value: 'id', child: Text('Bahasa Indonesia')),
                      ComboBoxItem(value: 'en', child: Text('English (US)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        _saveConfig();
                        _showRestartToast();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Terjemahan Cerdas', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Menerjemahkan teks rumit dari mesin operasi Windows ke bahasa pilihan Anda menggunakan kamus internal.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                ToggleSwitch(
                  checked: _translateServices,
                  onChanged: (v) {
                    setState(() => _translateServices = v);
                    _saveConfig();
                    displayInfoBar(
                      context,
                      builder: (context, close) => InfoBar(
                        title: const Text('Info'),
                        content: Text(v ? 'Kamus lokal diaktifkan.' : 'Kamus lokal dimatikan. Data akan tampil apa adanya.'),
                        severity: InfoBarSeverity.info,
                      ),
                      alignment: Alignment.bottomRight,
                    );
                  },
                  content: Text(_translateServices ? 'Aktif (Menerjemahkan Deskripsi Windows Services)' : 'Mati (Gunakan Bahasa Asli Windows)'),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Bagian Tampilan
        const Text('Tampilan (Appearance)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLabel(
                  label: 'Tema Aplikasi',
                  child: ComboBox<String>(
                    isExpanded: true,
                    value: _selectedTheme,
                    items: const [
                      ComboBoxItem(value: 'system', child: Text('Ikuti Sistem (System Default)')),
                      ComboBoxItem(value: 'light', child: Text('Terang (Light Mode)')),
                      ComboBoxItem(value: 'dark', child: Text('Gelap (Dark Mode)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTheme = val);
                        _saveConfig();
                        _showRestartToast();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        
        // Tentang Aplikasi
        const Text('Tentang Ananta Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ananta Tools v1.2.1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                Text('"Da tua sunt, post mortem tune tua sunt"', style: TextStyle(fontStyle: FontStyle.italic)),
                SizedBox(height: 4),
                Text('"Berikan benda benda saat kamu masih memilikinya, saat kamu mati benda benda itu bukan milikmu lagi"', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
