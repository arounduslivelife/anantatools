class ServicesDictionary {
  /// Mendapatkan terjemahan berdasarkan nama Service.
  /// Karena beberapa service Windows memiliki akhiran acak (misal: AarSvc_2c0450e),
  /// kita menggunakan metode pencarian dinamis.
  static String? getTranslation(String serviceName) {
    String name = serviceName.toLowerCase();
    
    for (var key in _dictionary.keys) {
      if (name == key || name.startsWith('${key}_')) {
        return _dictionary[key];
      }
    }
    
    return null;
  }

  static const Map<String, String> _dictionary = {
    // A
    'aarsvc': 'Agent Activation Runtime: Layanan runtime untuk mengaktifkan aplikasi agen percakapan (Cortana/Voice Assistant).',
    'axinstsv': 'ActiveX Installer: Menyediakan validasi UAC untuk instalasi kontrol ActiveX dari internet.',
    'ajrouter': 'AllJoyn Router Service: Merutekan pesan AllJoyn untuk klien AllJoyn lokal.',
    'alg': 'Application Layer Gateway: Menyediakan dukungan plug-in pihak ketiga untuk Internet Connection Sharing.',
    'appidsvc': 'Application Identity: Menentukan dan memverifikasi identitas aplikasi.',
    'appinfo': 'Application Information: Memfasilitasi berjalannya aplikasi interaktif dengan hak administratif tambahan (UAC).',
    'appmgmt': 'Application Management: Memproses permintaan penginstalan, penghapusan, dan enumerasi perangkat lunak.',
    'audiosrv': 'Windows Audio: Mengelola perangkat suara/audio untuk seluruh program Windows.',
    'audioendpointbuilder': 'Windows Audio Endpoint Builder: Mengelola perangkat audio di Windows.',
    'autotimesvc': 'Cellular Time: Menyinkronkan waktu berdasarkan jaringan seluler.',

    // B
    'bfe': 'Base Filtering Engine: Mesin keamanan inti untuk Firewall dan IPsec.',
    'bits': 'Background Intelligent Transfer: Mentransfer file (seperti update) secara diam-diam di latar belakang.',
    'bdesvc': 'BitLocker Drive Encryption: Menyediakan layanan enkripsi drive yang aman.',
    'bthserv': 'Bluetooth Support Service: Mendukung penemuan dan penyandingan perangkat Bluetooth.',

    // C
    'cdpsvc': 'Connected Devices Platform: Digunakan untuk skenario perangkat terhubung dan Universal Windows Platform.',
    'cdpusersvc': 'Connected Devices Platform User Service: Layanan pengguna untuk perangkat terhubung.',
    'certpropsvc': 'Certificate Propagation: Menyalin sertifikat pengguna dan sertifikat root dari smart card.',
    'clipsvc': 'Client License Service: Menyediakan dukungan infrastruktur untuk Microsoft Store.',
    'coremessagingregistrar': 'CoreMessaging: Mengelola komunikasi antar komponen inti Windows.',
    'cryptsvc': 'Cryptographic Services: Mengelola sertifikat keamanan dan tanda tangan digital untuk file Windows.',

    // D
    'dcomlaunch': 'DCOM Server Process Launcher: Meluncurkan server COM dan DCOM.',
    'defragsvc': 'Optimize drives: Membantu sistem melakukan defragmentasi pada hardisk.',
    'dhcp': 'DHCP Client: Mengatur otomatisasi alamat IP dan koneksi jaringan komputer ini.',
    'dnscache': 'DNS Client: Menyimpan cache nama domain (DNS) untuk mempercepat akses internet.',
    'dps': 'Diagnostic Policy Service: Mendeteksi masalah dan memberikan opsi pemecahan masalah (Troubleshooting).',
    'dsmsvc': 'Device Setup Manager: Mengelola instalasi perangkat dan mengunduh driver dari Windows Update.',
    'dusmsvc': 'Data Usage: Melacak dan mengelola penggunaan data jaringan (kuota internet).',

    // E - F
    'efs': 'Encrypting File System: Menyediakan teknologi enkripsi file dasar.',
    'eventlog': 'Windows Event Log: Mencatat semua error, peringatan, dan aktivitas sistem ke Event Viewer.',
    'eventsystem': 'COM+ Event System: Mendukung layanan System Event Notification.',
    'fdphost': 'Function Discovery Provider Host: Mencari perangkat di jaringan (Network Discovery).',
    'fdrespub': 'Function Discovery Resource Publication: Menerbitkan status komputer ini agar terlihat di jaringan.',
    'fontcache': 'Windows Font Cache: Mengoptimalkan performa dengan menyimpan font di memori.',

    // I - K
    'ikeext': 'IKE and AuthIP IPsec Keying Modules: Layanan otentikasi kunci keamanan jaringan IPsec.',
    'iphlpsvc': 'IP Helper: Menyediakan konektivitas IPv6 di atas jaringan IPv4.',
    'keyiso': 'CNG Key Isolation: Melindungi kunci kriptografi milik sistem.',
    'ktmrm': 'KtmRm for Distributed Transaction Coordinator: Mengkoordinasikan transaksi antar database.',

    // L - M
    'lanmanserver': 'Server: Mendukung pembagian berkas (file sharing) dan printer antar komputer di jaringan.',
    'lanmanworkstation': 'Workstation: Mengizinkan PC ini terhubung ke komputer lain dalam jaringan (SMB).',
    'lfsvc': 'Geolocation Service: Melacak lokasi sistem saat ini (GPS/Wi-Fi positioning).',
    'lmhosts': 'TCP/IP NetBIOS Helper: Menyediakan dukungan NetBIOS over TCP/IP (NetBT) untuk jaringan.',
    'mpssvc': 'Windows Defender Firewall: Mencegah penyusup jaringan dan mengamankan port internet.',
    'msdtc': 'Distributed Transaction Coordinator: Mengkoordinasikan transaksi dari beberapa resource.',
    'msiserver': 'Windows Installer: Mengelola instalasi dan penghapusan software berekstensi .msi.',

    // N - O
    'netlogon': 'Netlogon: Memelihara saluran aman antara komputer ini dan domain controller.',
    'netman': 'Network Connections: Mengelola koneksi jaringan di folder Network and Dial-Up Connections.',
    'netprofm': 'Network List Service: Mengidentifikasi jaringan yang tersambung dan menyesuaikan profil keamanan.',
    'nlasvc': 'Network Location Awareness: Mengumpulkan dan menyimpan informasi konfigurasi jaringan.',
    'nsi': 'Network Store Interface: Layanan yang menyimpan rute dan pengaturan jaringan inti.',
    'onesyncsvc': 'Sync Host: Menyinkronkan kontak, kalender, dan email.',

    // P - R
    'pimindexmaintenancesvc': 'Contact Data: Mengindeks data kontak pengguna untuk pencarian cepat.',
    'plugplay': 'Plug and Play: Memungkinkan Windows mendeteksi otomatis perangkat USB/Hardware yang dicolokkan.',
    'policyagent': 'IPsec Policy Agent: Menerapkan kebijakan keamanan jaringan IPsec.',
    'profsvc': 'User Profile Service: Mengelola proses login dan memuat profil pengguna.',
    'rasman': 'Remote Access Connection Manager: Mengelola koneksi dial-up dan VPN.',
    'rpcss': 'Remote Procedure Call (RPC): Layanan komunikasi paling inti di Windows. JANGAN DIMATIKAN!',
    'rpcestimator': 'RPC Endpoint Mapper: Memetakan antarmuka RPC ke port jaringan.',

    // S
    'samss': 'Security Accounts Manager: Menyimpan informasi keamanan akun pengguna lokal.',
    'scardsvr': 'Smart Card: Mengelola akses ke pembaca kartu pintar (Smart Card Reader).',
    'schedule': 'Task Scheduler: Menjalankan tugas otomatis yang sudah dijadwalkan oleh pengguna atau sistem.',
    'sens': 'System Event Notification Service: Memantau kejadian sistem seperti login/logout dan baterai.',
    'seclogon': 'Secondary Logon: Memungkinkan memulai proses dengan kredensial user lain (Run As).',
    'sgrmbroker': 'System Guard Runtime Monitor: Memonitor integritas keamanan sistem.',
    'sharedaccess': 'Internet Connection Sharing (ICS): Menyediakan fitur hotspot dan berbagi internet.',
    'shellhwdetection': 'Shell Hardware Detection: Menyediakan notifikasi AutoPlay/AutoRun untuk USB atau CD.',
    'spooler': 'Print Spooler: Mengelola antrean cetak untuk printer lokal dan printer jaringan Anda.',
    'ssdpsrv': 'SSDP Discovery: Menemukan perangkat jaringan UPnP di rumah Anda (seperti Smart TV).',
    'stisvc': 'Windows Image Acquisition (WIA): Menyediakan layanan untuk Scanner dan Kamera.',
    'sysmain': 'SysMain (Superfetch): Mempelajari kebiasaan Anda untuk mempercepat peluncuran aplikasi.',

    // T - V
    'tapisrv': 'Telephony: Menyediakan layanan Telephony API untuk program yang butuh menelepon/dial.',
    'termservice': 'Remote Desktop Services: Memungkinkan komputer ini dikendalikan dari jarak jauh.',
    'themes': 'Themes: Mengelola tema visual (warna, wallpaper, gaya jendela) Windows.',
    'timebrokersvc': 'Time Broker: Mengoordinasikan eksekusi aplikasi UWP di latar belakang.',
    'trkwks': 'Distributed Link Tracking Client: Mempertahankan tautan (shortcut) file di jaringan NTFS.',
    'unistoresvc': 'User Data Storage: Menyimpan data terstruktur untuk aplikasi (kontak, kalender).',
    'upnphost': 'UPnP Device Host: Memungkinkan PC Anda bertindak sebagai perangkat UPnP di jaringan.',
    'usermanager': 'User Manager: Layanan yang mengelola identitas dan sesi pengguna.',
    'usosvc': 'Update Orchestrator Service: Mengelola pengunduhan pembaruan (Windows Update).',
    'vds': 'Virtual Disk: Menyediakan layanan manajemen disk, volume, dan partisi.',
    'vss': 'Volume Shadow Copy: Komponen vital untuk keperluan Backup, System Restore, dan pemulihan data.',

    // W
    'w32time': 'Windows Time: Menyamakan jam komputer ini dengan server waktu global di internet.',
    'wcmsvc': 'Windows Connection Manager: Memutuskan koneksi jaringan mana yang terbaik saat ini.',
    'wcncsvc': 'Windows Connect Now: Digunakan untuk menyambungkan perangkat nirkabel (WPS).',
    'wdiservicehost': 'Diagnostic Service Host: Host untuk memecahkan masalah (Diagnostics).',
    'wdisystemhost': 'Diagnostic System Host: Host sistem untuk memecahkan masalah lokal.',
    'windefend': 'Windows Defender: Membantu melindungi sistem dari malware, virus, dan perangkat lunak jahat.',
    'winhttpautoproxysvc': 'WinHTTP Web Proxy Auto-Discovery: Mengatur proxy secara otomatis.',
    'winmgmt': 'WMI: Layanan inti untuk menyajikan data manajemen sistem (yang dipakai oleh aplikasi kita ini).',
    'wlansvc': 'WLAN AutoConfig: Mengelola konfigurasi dan koneksi Wi-Fi Anda.',
    'wmiaprv': 'WMI Performance Adapter: Menyediakan data performa dari penyedia WMI.',
    'workfolderssvc': 'Work Folders: Menyinkronkan file dengan server Work Folders perusahaan.',
    'wpnservice': 'Windows Push Notifications: Menyediakan dukungan notifikasi push dari aplikasi.',
    'wsearch': 'Windows Search: Menyediakan fitur pencarian cepat file dan email (Indexing).',
    'wuauserv': 'Windows Update: Mengaktifkan deteksi, pengunduhan, dan penginstalan pembaruan otomatis.',
  };
}
