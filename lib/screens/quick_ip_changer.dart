import 'package:fluent_ui/fluent_ui.dart';
import '../services/ip_changer_service.dart';

class QuickIpChangerPage extends StatefulWidget {
  const QuickIpChangerPage({super.key});

  @override
  State<QuickIpChangerPage> createState() => _QuickIpChangerPageState();
}

class _QuickIpChangerPageState extends State<QuickIpChangerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> _adapters = [];
  String? _selectedAdapter;
  Map<String, dynamic>? _adapterInfo;
  
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _maskController = TextEditingController(text: '255.255.255.0');
  final TextEditingController _gatewayController = TextEditingController();

  bool _isLoading = true;
  bool _isFetchingInfo = false;

  @override
  void initState() {
    super.initState();
    _loadAdapters();
  }

  void _loadAdapters() async {
    var adapters = await IpChangerService.getAdapters();
    setState(() {
      _adapters = adapters;
      _isLoading = false;
    });
    
    if (adapters.isNotEmpty) {
      _selectAdapter(adapters.first);
    }
  }

  void _selectAdapter(String adapter) async {
    setState(() {
      _selectedAdapter = adapter;
      _isFetchingInfo = true;
    });

    var info = await IpChangerService.getAdapterInfo(adapter);
    
    if (mounted) {
      setState(() {
        _adapterInfo = info;
        _isFetchingInfo = false;
        
        if (info != null) {
          if (info['ip'] != '') _ipController.text = info['ip'];
          if (info['mask'] != '') _maskController.text = info['mask'];
          if (info['gateway'] != '') _gatewayController.text = info['gateway'];
        }
      });
    }
  }

  void _setDhcp() async {
    if (_selectedAdapter == null) return;
    
    // Tampilkan notifikasi
    _showToast('Meminta akses Administrator (UAC) untuk mengubah ke DHCP...');
    
    bool success = await IpChangerService.setDhcp(_selectedAdapter!);
    if (success) {
      _showToast('Berhasil mengubah $_selectedAdapter ke DHCP (Otomatis).', severity: InfoBarSeverity.success);
    } else {
      _showToast('Gagal mengubah ke DHCP atau dibatalkan.', severity: InfoBarSeverity.error);
    }
  }

  void _setStatic() async {
    if (_selectedAdapter == null) return;
    if (_ipController.text.isEmpty || _maskController.text.isEmpty) {
      _showToast('IP dan Subnet Mask tidak boleh kosong!', severity: InfoBarSeverity.warning);
      return;
    }

    _showToast('Meminta akses Administrator (UAC) untuk memasang Static IP...');
    
    bool success = await IpChangerService.setStatic(
      _selectedAdapter!,
      _ipController.text,
      _maskController.text,
      _gatewayController.text.isEmpty ? '0.0.0.0' : _gatewayController.text,
    );
    
    if (success) {
      _showToast('Berhasil memasang Static IP.', severity: InfoBarSeverity.success);
    } else {
      _showToast('Gagal memasang Static IP atau dibatalkan.', severity: InfoBarSeverity.error);
    }
  }

  void _showToast(String message, {InfoBarSeverity severity = InfoBarSeverity.info}) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: Text(severity == InfoBarSeverity.error ? 'Error' : 'Informasi'),
          content: Text(message),
          severity: severity,
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
        title: Text('Quick IP Changer'),
      ),
      children: [
        if (_isLoading)
          const Center(child: ProgressRing())
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Pilih Adapter Jaringan', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      if (_isFetchingInfo)
                        const ProgressRing(strokeWidth: 2.5)
                      else if (_adapterInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _adapterInfo!['isDhcp'] ? Colors.blue : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _adapterInfo!['isDhcp'] ? 'Status: Otomatis (DHCP)' : 'Status: Manual (Static)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ComboBox<String>(
                    value: _selectedAdapter,
                    items: _adapters.map((e) {
                      return ComboBoxItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _selectAdapter(val);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Opsi 1: Otomatis (DHCP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: (_adapterInfo != null && _adapterInfo!['isDhcp']) ? null : _setDhcp,
                    child: const Text('Ubah ke DHCP'),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(),
                  ),
                  
                  const Text('Opsi 2: Manual (Static IP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  InfoLabel(
                    label: 'IP Address',
                    child: TextBox(controller: _ipController, placeholder: 'Contoh: 192.168.1.50'),
                  ),
                  const SizedBox(height: 16),
                  
                  InfoLabel(
                    label: 'Subnet Mask',
                    child: TextBox(controller: _maskController),
                  ),
                  const SizedBox(height: 16),
                  
                  InfoLabel(
                    label: 'Default Gateway (Opsional)',
                    child: TextBox(controller: _gatewayController, placeholder: 'Contoh: 192.168.1.1'),
                  ),
                  const SizedBox(height: 24),
                  
                  Button(
                    onPressed: _setStatic,
                    child: const Text('Apply Static IP'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
