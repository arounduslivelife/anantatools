import 'package:fluent_ui/fluent_ui.dart';

class DocumentationPage extends StatelessWidget {
  const DocumentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Contoh Penerapan Per Menu (Buku Panduan)'),
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Text(
            'Halaman ini berisi dokumentasi dan contoh kasus nyata di lapangan untuk setiap fitur Ananta Tools. '
            'Penjelasan dibuat sesederhana mungkin agar mudah dipahami oleh pengguna awam.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        _buildDocCard(
          icon: FluentIcons.network_tower,
          title: '1. Network Scanner (Pemindai Jaringan)',
          analogy: 'Seperti satpam yang mengecek KTP semua orang di dalam satu gedung.',
          caseStudy: 'Kasus di lapangan: Internet di kantor tiba-tiba sangat lambat. Anda curiga ada orang luar yang membobol WiFi atau ada karyawan yang membawa perangkat pribadi. Anda cukup menekan tombol "Mulai Pindai", dan aplikasi akan memunculkan semua IP beserta MAC Address perangkat yang sedang terhubung ke jaringan Anda saat ini.',
        ),
        _buildDocCard(
          icon: FluentIcons.heart,
          title: '2. Ping Monitor & Wake-on-LAN',
          analogy: 'Seperti alat pendeteksi detak jantung pasien di rumah sakit, lengkap dengan alat kejut jantung (Defibrillator).',
          caseStudy: 'Kasus di lapangan: Anda memiliki Server Database, mesin absen, dan PC Bos yang pantang mati. Masukkan IP mereka ke fitur ini. Jika tiba-tiba listrik turun dan PC Bos mati (indikator jadi merah), Anda tidak perlu jalan ke ruangannya. Cukup klik logo "Petir" (Wake-on-LAN) untuk menyalakan komputer beliau dari jarak jauh (via jaringan kabel).',
        ),
        _buildDocCard(
          icon: FluentIcons.lightbulb,
          title: '3. Smart IP Suggester (Pencari IP Kosong)',
          analogy: 'Seperti mencari tempat parkir kosong di sebuah mal yang sangat padat.',
          caseStudy: 'Kasus di lapangan: Anda ingin memasang mesin Printer Jaringan atau CCTV baru. Alat-alat ini wajib diberi "Alamat IP Statis" agar tidak berubah-ubah. Masalahnya, Anda tidak tahu alamat nomor berapa yang belum dipakai orang lain. Gunakan fitur ini, dan ia akan otomatis merekomendasikan alamat IP yang 100% kosong dan aman untuk dipakai alat baru Anda.',
        ),
        _buildDocCard(
          icon: FluentIcons.internet_sharing,
          title: '4. Quick IP Changer (Pengubah IP Cepat)',
          analogy: 'Seperti mengganti pelat nomor mobil Anda agar bisa masuk ke kompleks perumahan yang berbeda.',
          caseStudy: 'Kasus di lapangan: Anda adalah teknisi yang sering berpindah-pindah menyetting router, cctv, atau mesin fotokopi. Mengubah IP Address Windows secara manual lewat Control Panel sangatlah memakan waktu dan klik. Dengan fitur ini, Anda cukup mengetik IP baru dan klik "Simpan", sistem Windows Anda langsung berganti IP dalam hitungan detik.',
        ),
        _buildDocCard(
          icon: FluentIcons.search_and_apps,
          title: '5. Deep Port Scanner (Pemindai Celah)',
          analogy: 'Seperti mengecek pintu dan jendela mana saja yang tidak dikunci di sebuah rumah.',
          caseStudy: 'Kasus di lapangan: Anda ingin tahu apakah sebuah komputer sedang menjalankan aplikasi Web (port 80) atau Database (port 3306), atau Anda ingin mengecek apakah komputer tersebut rentan disusupi hacker lewat port remote (3389). Fitur ini akan mengetuk ribuan "pintu virtual" di komputer target untuk melihat pintu mana yang sedang terbuka.',
        ),
        _buildDocCard(
          icon: FluentIcons.info,
          title: '6. PC Profiler (Info Spesifikasi PC)',
          analogy: 'Seperti melihat rekam medis dan KTP lengkap dari sebuah komputer.',
          caseStudy: 'Kasus di lapangan: Anda diminta atasan untuk mendata spesifikasi laptop karyawan (Berapa GB RAM-nya? Apa nama prosesornya? Apakah Windows-nya asli?). Daripada membongkar laptop atau membuka banyak menu, cukup buka PC Profiler dan seluruh rahasia perangkat keras & lunak PC tersebut akan terpampang jelas.',
        ),
        _buildDocCard(
          icon: FluentIcons.shield,
          title: '7. Windows Security Manager',
          analogy: 'Seperti mengatur tembok pelindung (Firewall) dan anjing penjaga (Antivirus) di rumah Anda.',
          caseStudy: 'Kasus di lapangan: Anda baru saja menginstal sebuah program kasir, tapi komputer lain tidak bisa terhubung ke program tersebut karena diblokir oleh pelindung Windows. Melalui fitur ini, Anda bisa langsung membuat "Aturan Baru" agar Firewall membiarkan koneksi program kasir tersebut lewat, tanpa harus mematikan Firewall secara total.',
        ),
        _buildDocCard(
          icon: FluentIcons.settings,
          title: '8. Windows Services Manager',
          analogy: 'Seperti mengatur organ-organ tubuh bagian dalam Windows yang bekerja di balik layar.',
          caseStudy: 'Kasus di lapangan: Komputer Anda terasa lambat karena fitur "Windows Update" diam-diam mengunduh data di latar belakang. Dengan fitur ini, Anda bisa mencari "Windows Update" lalu menekan tombol "Stop" untuk mematikannya secara paksa. Kami juga sudah menyertakan terjemahan bahasa Indonesia agar Anda tahu fungsi asli dari organ-organ tersebut.',
        ),
        _buildDocCard(
          icon: FluentIcons.print,
          title: '9. Printer Troubleshooter (Perbengkelan Printer)',
          analogy: 'Seperti menyiram toilet yang mampet karena kebanyakan kertas.',
          caseStudy: 'Kasus di lapangan: Printer kantor tiba-tiba macet total. Di layar tertulis "Ada 15 dokumen nyangkut". Anda sudah mencoba menghapusnya tapi tetap gagal. Cukup buka fitur ini dan tekan tombol "Clear Print Queue (Force)". Fitur ini akan menggunakan akses tingkat tinggi untuk menghancurkan paksa dokumen yang menyumbat dan merestart mesin printer virtual Anda.',
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required IconData icon,
    required String title,
    required String analogy,
    required String caseStudy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Analogi Sederhana:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(analogy),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Kasus Penerapan (Di Lapangan):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(caseStudy, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
