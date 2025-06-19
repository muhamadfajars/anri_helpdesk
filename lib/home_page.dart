import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anri/pages/login_page.dart';
import 'package:anri/pages/ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// Kelas Model Data
class ProblemRequest {
  final String id;
  final String title;
  final String category;
  final String status;
  final String division;
  final String priority;
  final String lastUpdate;
  final String name;

  ProblemRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.division,
    required this.priority,
    required this.lastUpdate,
    required this.name,
  });

  factory ProblemRequest.fromJson(Map<String, dynamic> json) {
    return ProblemRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'Uncategorized',
      status: json['status'] ?? 'Unknown',
      division: json['division'] ?? 'N/A',
      priority: json['priority'] ?? 'Low',
      lastUpdate: json['lastUpdate'] ?? '',
      name: json['name'] ?? 'Unknown User',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Date formatter
  final dateFormat = DateFormat('d MMM yyyy, HH:mm');

  // State variables
  int _selectedIndex = 0;
  late Future<List<ProblemRequest>> _ticketsFuture;
  String _selectedCategory = 'All';
  String _selectedStatus = 'Semua';

  // Constants
  final Map<String, String> _categories = {
    'All': 'Semua Kategori',
    '1': 'Aplikasi Sistem Informasi',
    '2': 'SRIKANDI',
    '3': 'Layanan Kepegawaian',
    '4': 'Perangkat Lunak',
    '5': 'Perangkat Keras',
    '6': 'Jaringan Komputer',
    '7': 'Bangunan',
    '8': 'Mesin dan AC',
    '9': 'Listrik',
    '10': 'Kendaraan Dinas',
    '11': 'Pengembalian BMN',
    '12': 'Insiden Siber',
    '13': 'Pusat Data Nasional',
    '14': 'CCTV',
    '15': 'Email Dinas',
  };

  final List<String> _statusFilters = [
    'Semua',
    'New',
    'Waiting Reply',
    'Replied',
    'In Progress',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _fetchTickets();
  }

  // API Methods
  Future<List<ProblemRequest>> _fetchTickets() async {
    String statusForAPI = _selectedIndex == 1
        ? 'Resolved'
        : (_selectedStatus == 'Semua' ? 'All' : _selectedStatus);
    String categoryForAPI = _selectedIndex == 0 ? _selectedCategory : 'All';

    final baseUrl = 'http://10.8.0.89/anri_helpdesk_api/get_tickets.php';
    final url = Uri.parse(
      '$baseUrl?status=$statusForAPI&category=$categoryForAPI',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body
            .map(
              (item) => ProblemRequest.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Gagal memuat tiket (Kode: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  Future<void> _reloadData() async {
    setState(() {
      _ticketsFuture = _fetchTickets();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFFFF0000); // Merah
      case 'Waiting Reply':
        return const Color(0xFFd66404); // Oranye/Coklat
      case 'Replied':
        return const Color(0xFF0000FF); // Biru
      case 'In Progress':
        return const Color(0xFF8c55d4); // Ungu
      case 'On Hold':
        return const Color(0xFFdc2d89); // Pink/Magenta
      case 'Resolved':
        return const Color(0xFF008000); // Hijau
      default:
        return Colors.black;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return const Color(0xFFFF0000); // Merah
      case 'High':
        return Colors.orange.shade800; // Orange
      case 'Medium':
        return Colors.green.shade600; // Hijau
      case 'Low':
        return Colors.blue.shade600; // Biru
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Software') || category.contains('Aplikasi')) {
      return Icons.computer;
    }

    switch (category) {
      case 'Perangkat Keras':
        return Icons.print;
      case 'Jaringan Komputer':
        return Icons.wifi;
      case 'Bangunan':
      case 'Fasilitas':
        return Icons.business_outlined;
      case 'Listrik':
        return Icons.flash_on;
      case 'CCTV':
        return Icons.videocam;
      case 'Email Dinas':
        return Icons.email;
      default:
        return Icons.miscellaneous_services;
    }
  }

  String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inHours < 24) {
        // Jika kurang dari 24 jam, gunakan format "time ago"
        return timeago.format(dateTime, locale: 'id');
      } else {
        // Jika lebih dari 24 jam, gunakan format tanggal dan jam
        return dateFormat.format(dateTime);
      }
    } catch (e) {
      return dateString; // Kembalikan string asli jika parsing gagal
    }
  }

  // Widget Builders
  Widget _buildBody() {
    if (_selectedIndex == 2) {
      // Tab Pengaturan
      return const Center(
        child: Text(
          'Halaman Pengaturan',
          style: TextStyle(fontSize: 22, color: Colors.blueGrey),
        ),
      );
    }
    return _buildTicketListLayout();
  }

  Widget _buildTicketListLayout() {
    return Column(
      children: [
        if (_selectedIndex == 0)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryFilter(),
                const SizedBox(height: 8),
                _buildStatusFilterChips(),
              ],
            ),
          ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: FutureBuilder<List<ProblemRequest>>(
            future: _ticketsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada tiket ditemukan.'));
              }

              final tickets = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _reloadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) =>
                      _buildProblemCard(tickets[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Row(
      children: [
        const Icon(Icons.category_outlined, color: Colors.grey),
        const SizedBox(width: 8),
        const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCategory,
            underline: const SizedBox.shrink(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedCategory = newValue);
                _reloadData();
              }
            },
            items: _categories.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedStatus = status);
                  _reloadData();
                }
              },
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              side: isSelected
                  ? BorderSide(color: Colors.blue.shade700)
                  : BorderSide(color: Colors.grey.shade300),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProblemCard(ProblemRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas berisi ID, Status, dan Prioritas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tracking ID
                  Text(
                    request.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const Spacer(),
                  // Kolom untuk Status dan Prioritas di kanan
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            request.status,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.status,
                          style: TextStyle(
                            color: _getStatusColor(request.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Label Prioritas dengan warna
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            request.priority,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          request.priority,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(request.priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Nama Pelapor
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    request.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Judul Tiket
              Text(
                request.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 24),
              // Baris bawah berisi Kategori dan Waktu Update
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kategori
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(request.category),
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  // Waktu Update dengan format baru
                  Text(
                    _formatTimeAgo(request.lastUpdate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: Text(
          _selectedIndex == 0
              ? 'Dashboard'
              : (_selectedIndex == 1 ? 'Riwayat Selesai' : 'Pengaturan'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              _selectedCategory = 'All';
              _selectedStatus = 'Semua';
            }
            _reloadData();
          });
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
