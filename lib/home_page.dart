import 'dart:async';
import 'dart:convert';
import 'package:anri/pages/login_page.dart';
import 'package:anri/pages/ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProblemRequest {
  final String id;
  final String title;
  final String category;
  final String status;
  final String priority;
  final String lastUpdate;
  final String name; // Ini adalah Requester
  final String assignedTo;
  final String lastReplied;

  ProblemRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.priority,
    required this.lastUpdate,
    required this.name,
    required this.assignedTo,
    required this.lastReplied,
  });

  factory ProblemRequest.fromJson(Map<String, dynamic> json) {
    return ProblemRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'Uncategorized',
      status: json['status'] ?? 'Unknown',
      priority: json['priority'] ?? 'Low',
      lastUpdate: json['lastUpdate'] ?? '',
      name: json['name'] ?? 'Unknown User',
      assignedTo: json['assignedTo'] ?? 'Unassigned',
      lastReplied: json['lastReplied'] ?? '-',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _selectedStatus = 'Semua';

  List<ProblemRequest> _tickets = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = false;
  Timer? _autoRefreshTimer;

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
    _fetchInitialTickets();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 200) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      } else {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      }
    });
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_selectedIndex == 0 && mounted) {
        _fetchLatestTicketsInBackground();
      }
    });
  }

  Future<void> _fetchLatestTicketsInBackground() async {
    if (_isLoading || _isLoadingMore) return;
    String statusForAPI = _selectedStatus == 'Semua' ? 'All' : _selectedStatus;
    String categoryForAPI = _selectedCategory;
    final baseUrl = 'http://localhost/anri_helpdesk_api/get_tickets.php';
    final url = Uri.parse(
      '$baseUrl?status=$statusForAPI&category=$categoryForAPI&page=1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<ProblemRequest> fetchedTickets = body
            .map(
              (item) => ProblemRequest.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (mounted) {
          final existingTicketIds = _tickets.map((ticket) => ticket.id).toSet();
          final newUniqueTickets = fetchedTickets
              .where((ticket) => !existingTicketIds.contains(ticket.id))
              .toList();
          if (newUniqueTickets.isNotEmpty) {
            setState(() {
              _tickets.insertAll(0, newUniqueTickets);
            });
          }
        }
      }
    } catch (e) {
      // Auto-refresh failed silently in the background
    }
  }

  Future<void> _fetchInitialTickets() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _tickets = [];
      _hasMore = true;
      _error = null;
    });
    await _fetchTickets(page: 1);
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreTickets() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _fetchTickets(page: _currentPage);
    setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchTickets({required int page}) async {
    String statusForAPI = _selectedIndex == 1
        ? 'Resolved'
        : (_selectedStatus == 'Semua' ? 'All' : _selectedStatus);
    String categoryForAPI = _selectedIndex == 0 ? _selectedCategory : 'All';
    final baseUrl = 'http://localhost/anri_helpdesk_api/get_tickets.php';
    final url = Uri.parse(
      '$baseUrl?status=$statusForAPI&category=$categoryForAPI&page=$page',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        final List<ProblemRequest> newTickets = body
            .map(
              (item) => ProblemRequest.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (mounted) {
          setState(() {
            if (page == 1)
              _tickets = newTickets;
            else
              _tickets.addAll(newTickets);
            if (newTickets.length < 10) _hasMore = false;
          });
        }
      } else {
        throw Exception('Gagal memuat tiket (Kode: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted)
        setState(
          () =>
              _error = 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFFD32F2F);
      case 'Waiting Reply':
        return const Color(0xFFE65100);
      case 'Replied':
        return const Color(0xFF1976D2);
      case 'In Progress':
        return const Color(0xFF673AB7);
      case 'On Hold':
        return const Color(0xFFC2185B);
      case 'Resolved':
        return const Color(0xFF388E3C);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return const Color(0xFFD32F2F);
      case 'High':
        return const Color(0xFFEF6C00);
      case 'Medium':
        return const Color(0xFF689F38);
      case 'Low':
        return const Color(0xFF0288D1);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Software') ||
        category.contains('Aplikasi') ||
        category.contains('SRIKANDI'))
      return Icons.widgets_outlined;
    switch (category) {
      case 'Perangkat Keras':
        return Icons.print_outlined;
      case 'Jaringan Komputer':
        return Icons.wifi_outlined;
      case 'Bangunan':
        return Icons.business_outlined;
      case 'Listrik':
        return Icons.flash_on_outlined;
      case 'CCTV':
        return Icons.videocam_outlined;
      case 'Email Dinas':
        return Icons.email_outlined;
      case 'Insiden Siber':
        return Icons.security_outlined;
      default:
        return Icons.support_agent_outlined;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (context.mounted)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
  }

  Widget _buildBody() {
    if (_selectedIndex == 2) {
      return const Center(
        child: Text(
          'Halaman Pengaturan',
          style: TextStyle(fontSize: 22, color: Colors.blueGrey),
        ),
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState(_error!);
    }
    if (_tickets.isEmpty && _selectedIndex != 0) {
      return _buildEmptyState();
    }
    return _buildTicketList();
  }

  Widget _buildHeaderFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            items: _categories.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedCategory = newValue);
                _fetchInitialTickets();
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = status);
                        _fetchInitialTickets();
                      }
                    },
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.15),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    bool isHomePage = _selectedIndex == 0;
    int itemCount =
        (isHomePage ? 1 : 0) +
        _tickets.length +
        (_hasMore || _isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _fetchInitialTickets,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (isHomePage && index == 0) {
            return _buildHeaderFilterBar();
          }
          final ticketIndex = isHomePage ? index - 1 : index;
          if (ticketIndex < _tickets.length) {
            return _buildProblemCard(_tickets[ticketIndex]);
          } else if (_tickets.isEmpty && isHomePage) {
            return _buildEmptyState();
          } else {
            if (_hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: OutlinedButton(
                          onPressed: _loadMoreTickets,
                          child: const Text('Muat Lebih Banyak'),
                        ),
                      ),
              );
            } else if (_tickets.isNotEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    '-- Anda telah mencapai akhir daftar --',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _selectedIndex == 1
        ? 'Belum ada tiket yang diselesaikan.'
        : 'Tidak ada tiket yang cocok dengan filter Anda.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedIndex == 1
                  ? Icons.history_toggle_off_outlined
                  : Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedIndex == 1 ? 'Riwayat Kosong' : 'Tidak Ada Tiket',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Oops, Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchInitialTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatCardDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildProblemCard(ProblemRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${request.id}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            request.status,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(width: 8),
                      Icon(
                        Icons.flag,
                        color: _getPriorityColor(request.priority),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kategori: ${request.category}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 24, thickness: 1),
              _buildDetailRow('Requester', request.name),
              const SizedBox(height: 6),
              _buildDetailRow('Assigned to', request.assignedTo),
              const SizedBox(height: 6),
              _buildDetailRow('Last Replied', request.lastReplied),
              const SizedBox(height: 6),
              _buildDetailRow('Update', _formatCardDate(request.lastUpdate)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    String tempCategory = _selectedCategory;
    String tempStatus = _selectedStatus;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Tiket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      items: _categories.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null)
                          setModalState(() => tempCategory = newValue);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _statusFilters.map((status) {
                        final isSelected = tempStatus == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) =>
                              setModalState(() => tempStatus = status),
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = tempCategory;
                                _selectedStatus = tempStatus;
                              });
                              _fetchInitialTickets();
                              Navigator.pop(context);
                            },
                            child: const Text('Terapkan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget appBarTitle;
    if (_selectedIndex == 0) {
      appBarTitle = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/anri_logo.png', height: 32),
          const SizedBox(width: 12),
          const Text(
            'Help Desk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      );
    } else if (_selectedIndex == 1) {
      appBarTitle = const Text(
        'Riwayat Selesai',
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      appBarTitle = const Text(
        'Pengaturan',
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isFabVisible && _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list),
              label: const Text('Filter'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
              _selectedCategory = 'All';
              _selectedStatus = 'Semua';
              _isFabVisible = false;
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
            });
            _fetchInitialTickets();
          }
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 4,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
