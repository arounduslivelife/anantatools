import 'package:fluent_ui/fluent_ui.dart';
import 'screens/network_scanner.dart';
import 'screens/smart_ip_suggester.dart';
import 'screens/quick_ip_changer.dart';
import 'screens/port_scanner.dart';
import 'screens/pc_profiler.dart';
import 'screens/firewall_manager.dart';
import 'screens/services_manager.dart';
import 'screens/printer_manager.dart';
import 'screens/ping_monitor.dart';
import 'screens/documentation_page.dart';
import 'screens/settings_page.dart';
import 'services/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const AnantaToolsApp());
}

class AnantaToolsApp extends StatelessWidget {
  const AnantaToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.themeNotifier,
      builder: (context, themeValue, child) {
        ThemeMode mode = ThemeMode.system;
        if (themeValue == 'light') mode = ThemeMode.light;
        if (themeValue == 'dark') mode = ThemeMode.dark;

        return FluentApp(
          title: 'Ananta Tools',
          themeMode: mode,
          theme: FluentThemeData(
            brightness: Brightness.light,
            accentColor: Colors.blue,
          ),
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: Colors.blue,
          ),
          home: const MainPage(),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int topIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      paneBodyBuilder: (item, body) {
        return IndexedStack(
          index: topIndex,
          children: const [
            NetworkScannerPage(),
            PingMonitorPage(),
            SmartIPSuggesterPage(),
            QuickIpChangerPage(),
            PortScannerPage(),
            PcProfilerPage(),
            FirewallManagerPage(),
            ServicesManagerPage(),
            PrinterManagerPage(),
            DocumentationPage(),
            SettingsPage(),
          ],
        );
      },
      pane: NavigationPane(
        toggleButton: const SizedBox.shrink(),
        header: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Ananta Tools v1.2.1',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.expanded,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.network_tower),
            title: const Text('Network Scanner'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.heart),
            title: const Text('Ping Monitor & WoL'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.lightbulb),
            title: const Text('Smart IP Suggester'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.internet_sharing),
            title: const Text('Quick IP Changer'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.search_and_apps),
            title: const Text('Deep Port Scanner'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.info),
            title: const Text('PC Profiler'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.shield),
            title: const Text('Windows Security Manager'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Windows Services Manager'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.print),
            title: const Text('Printer Troubleshooter'),
            body: const SizedBox.shrink(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.reading_mode),
            title: const Text('Buku Panduan'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text(title)),
      content: Center(
        child: Text('Halaman $title akan diimplementasikan di sini.'),
      ),
    );
  }
}
