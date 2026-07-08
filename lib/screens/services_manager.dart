import 'package:fluent_ui/fluent_ui.dart';
import '../services/services_service.dart';

class ServicesManagerPage extends StatefulWidget {
  const ServicesManagerPage({super.key});

  @override
  State<ServicesManagerPage> createState() => _ServicesManagerPageState();
}

class _ServicesManagerPageState extends State<ServicesManagerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  List<WindowsServiceInfo> _allServices = [];
  List<WindowsServiceInfo> _filteredServices = [];
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  void _fetchServices() async {
    setState(() => _isLoading = true);
    var services = await ServicesService.getServices();
    if (mounted) {
      setState(() {
        _allServices = services;
        _filterServices(_searchCtrl.text);
        _isLoading = false;
      });
    }
  }

  void _filterServices(String query) {
    if (query.isEmpty) {
      _filteredServices = List.from(_allServices);
    } else {
      String q = query.toLowerCase();
      _filteredServices = _allServices.where((s) {
        return s.displayName.toLowerCase().contains(q) || 
               s.name.toLowerCase().contains(q) ||
               s.description.toLowerCase().contains(q);
      }).toList();
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

  void _changeState(WindowsServiceInfo service, String actionName, String psAction) async {
    _showToast('Meminta otorisasi UAC untuk $actionName ${service.name}...', severity: InfoBarSeverity.info);
    bool success = await ServicesService.changeServiceState(service.name, psAction);
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      _fetchServices(); // Refresh data
      _showToast('Berhasil $actionName ${service.name}', severity: InfoBarSeverity.success);
    } else {
      _showToast('Gagal memodifikasi layanan atau UAC ditolak.', severity: InfoBarSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Windows Services Manager'),
        commandBar: _isLoading
            ? const ProgressRing()
            : FilledButton(
                onPressed: _fetchServices,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(FluentIcons.refresh), SizedBox(width: 8), Text('Refresh Data')],
                ),
              ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextBox(
              controller: _searchCtrl,
              placeholder: 'Cari layanan berdasarkan nama atau deskripsi...',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FluentIcons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _filterServices(value);
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: Text('Memindai ratusan Service Windows...'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    itemCount: _filteredServices.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(_filteredServices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(WindowsServiceInfo service) {
    bool isRunning = service.state.toLowerCase() == 'running';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isRunning ? Colors.green : Colors.grey),
                  ),
                  child: Text(
                    service.state,
                    style: TextStyle(
                      color: isRunning ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Name: ${service.name}  |  Startup: ${service.startMode}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            
            if (service.isSystemCore) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(FluentIcons.shield, size: 14),
                  const SizedBox(width: 4),
                  Text('Dilindungi oleh Sabuk Pengaman Inti Windows', style: TextStyle(color: Colors.blue.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Text(service.description, style: const TextStyle(fontSize: 13)),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Button(
                  onPressed: service.isSystemCore || isRunning ? null : () => _changeState(service, 'Start', 'Start-Service'),
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: service.isSystemCore || !isRunning ? null : () => _changeState(service, 'Stop', 'Stop-Service'),
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: service.isSystemCore || !isRunning ? null : () => _changeState(service, 'Restart', 'Restart-Service'),
                  child: const Text('Restart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
