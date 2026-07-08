import 'package:fluent_ui/fluent_ui.dart';
import '../services/printer_service.dart';

class PrinterManagerPage extends StatefulWidget {
  const PrinterManagerPage({super.key});

  @override
  State<PrinterManagerPage> createState() => _PrinterManagerPageState();
}

class _PrinterManagerPageState extends State<PrinterManagerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  bool _isActionRunning = false;
  List<PrinterInfo> _printers = [];
  int _queueCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var printers = await PrinterService.getPrinters();
    int queues = await PrinterService.getQueuedJobsCount();
    
    if (mounted) {
      setState(() {
        _printers = printers;
        _queueCount = queues;
        _isLoading = false;
      });
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

  void _setDefault(PrinterInfo printer) async {
    setState(() => _isActionRunning = true);
    bool success = await PrinterService.setDefaultPrinter(printer.name);
    
    if (success) {
      _showToast('${printer.name} berhasil disetel sebagai Default.', severity: InfoBarSeverity.success);
      _fetchData();
    } else {
      _showToast('Gagal menyetel printer default.', severity: InfoBarSeverity.error);
    }
    setState(() => _isActionRunning = false);
  }

  void _runNuclearClear() async {
    setState(() => _isActionRunning = true);
    _showToast('Meminta otorisasi UAC untuk membersihkan antrean...', severity: InfoBarSeverity.warning);
    
    bool success = await PrinterService.nuclearClearQueue();
    if (success) {
      await Future.delayed(const Duration(seconds: 3));
      _fetchData();
      _showToast('Antrean cetak berhasil dibersihkan. Print Spooler telah direstart.', severity: InfoBarSeverity.success);
    } else {
      _showToast('Gagal memproses aksi atau UAC ditolak.', severity: InfoBarSeverity.error);
    }
    setState(() => _isActionRunning = false);
  }

  void _restartSpooler() async {
    setState(() => _isActionRunning = true);
    _showToast('Meminta otorisasi UAC untuk me-restart Spooler...', severity: InfoBarSeverity.info);
    
    bool success = await PrinterService.restartSpooler();
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      _fetchData();
      _showToast('Print Spooler berhasil direstart.', severity: InfoBarSeverity.success);
    } else {
      _showToast('Gagal me-restart Spooler atau UAC ditolak.', severity: InfoBarSeverity.error);
    }
    setState(() => _isActionRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Printer & Queue Troubleshooter'),
        commandBar: _isLoading || _isActionRunning
            ? const ProgressRing()
            : FilledButton(
                onPressed: _fetchData,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(FluentIcons.refresh), SizedBox(width: 8), Text('Refresh Data')],
                ),
              ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(FluentIcons.print, size: 24),
                              SizedBox(width: 8),
                              Text('Total Printer Terdeteksi', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${_printers.length} Printer', style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(FluentIcons.list, size: 24),
                              SizedBox(width: 8),
                              Text('Antrean Dokumen (Print Queue)', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('$_queueCount Dokumen', style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Danger Zone Actions
            const Text('Manajemen Spooler (Membutuhkan Hak Akses UAC)', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _isActionRunning ? null : _runNuclearClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.delete),
                        SizedBox(width: 8),
                        Text('Clear Print Queue (Force)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: _isActionRunning ? null : _restartSpooler,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.refresh),
                        SizedBox(width: 8),
                        Text('Restart Print Spooler'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Printer List
            const Text('Daftar Printer Tersedia', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: Text('Memindai Printer...'))
                  : ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (context, index) {
                        return _buildPrinterCard(_printers[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard(PrinterInfo printer) {
    bool isError = printer.status == 7;
    bool isReady = printer.status == 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Printer
            Icon(
              printer.isShared ? FluentIcons.internet_sharing : FluentIcons.print,
              size: 32,
              color: printer.isDefault ? Colors.blue : (isError ? Colors.red : Colors.grey),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(printer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (printer.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Status: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(printer.statusText, style: TextStyle(
                        color: isError ? Colors.red : (isReady ? Colors.green : Colors.orange),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Port: ${printer.portName}  |  Driver: ${printer.driverName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            // Actions
            if (!printer.isDefault)
              Button(
                onPressed: _isActionRunning ? null : () => _setDefault(printer),
                child: const Text('Set Default'),
              ),
          ],
        ),
      ),
    );
  }
}
