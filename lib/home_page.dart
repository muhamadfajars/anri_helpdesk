import 'package:flutter/material.dart';

// Dummy data for Problem Requests
class ProblemRequest {
  final String id;
  final String title;
  final String category;
  final String status;
  final String division;
  final String priority; // e.g., 'High', 'Medium', 'Low'
  final String lastUpdate; // e.g., '2 days ago'

  ProblemRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.division,
    required this.priority,
    required this.lastUpdate,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Current selected filter (e.g., 'All', 'New', 'In Progress', 'IT Division')
  String _selectedFilter = 'Semua Keluhan';

  // Dummy list of problem requests
  final List<ProblemRequest> _allProblemRequests = [
    ProblemRequest(id: 'PR-001', title: 'Laptop butuh perbaikan software', category: 'Software', status: 'Baru', division: 'IT', priority: 'Tinggi', lastUpdate: 'Baru'),
    ProblemRequest(id: 'PR-002', title: 'Printer Ruang A tidak berfungsi', category: 'Hardware', status: 'Diproses', division: 'Umum', priority: 'Sedang', lastUpdate: '1 jam lalu'),
    ProblemRequest(id: 'PR-003', title: 'Akses jaringan lambat', category: 'Jaringan', status: 'Selesai', division: 'IT', priority: 'Tinggi', lastUpdate: 'Kemarin'),
    ProblemRequest(id: 'PR-004', title: 'AC Ruang Server Panas', category: 'Fasilitas', status: 'Baru', division: 'Fasilitas', priority: 'Darurat', lastUpdate: '10 menit lalu'),
    ProblemRequest(id: 'PR-005', title: 'Permintaan instalasi software baru', category: 'Software', status: 'Diproses', division: 'IT', priority: 'Sedang', lastUpdate: '2 jam lalu'),
    ProblemRequest(id: 'PR-006', title: 'Penerangan koridor lantai 2 mati', category: 'Listrik', status: 'Selesai', division: 'Umum', priority: 'Rendah', lastUpdate: '3 hari lalu'),
    ProblemRequest(id: 'PR-007', title: 'Mouse kantor tidak responsif', category: 'Hardware', status: 'Baru', division: 'IT', priority: 'Sedang', lastUpdate: '25 menit lalu'),
  ];

  // Filtered list based on selected filter
  List<ProblemRequest> _filteredProblemRequests = [];

  @override
  void initState() {
    super.initState();
    _filterRequests(); // Initialize filtered list
  }

  void _filterRequests() {
    setState(() {
      if (_selectedFilter == 'Semua Keluhan') {
        _filteredProblemRequests = _allProblemRequests;
      } else if (_selectedFilter == 'Baru') {
        _filteredProblemRequests = _allProblemRequests.where((req) => req.status == 'Baru').toList();
      } else if (_selectedFilter == 'Diproses') {
        _filteredProblemRequests = _allProblemRequests.where((req) => req.status == 'Diproses').toList();
      } else if (_selectedFilter == 'Selesai') {
        _filteredProblemRequests = _allProblemRequests.where((req) => req.status == 'Selesai').toList();
      } else if (_selectedFilter == 'Divisi IT') {
        _filteredProblemRequests = _allProblemRequests.where((req) => req.division == 'IT').toList();
      }
      // Add more filter conditions as needed
    });
  }

  // Helper to get color based on status/priority
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Baru':
        return Colors.red.shade700;
      case 'Diproses':
        return Colors.orange.shade700;
      case 'Selesai':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Software':
        return Icons.computer;
      case 'Hardware':
        return Icons.print;
      case 'Jaringan':
        return Icons.wifi;
      case 'Fasilitas':
        return Icons.lightbulb_outline;
      case 'Listrik':
        return Icons.flash_on;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'ANRI Helpdesk Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications), // Notification icon
            onPressed: () {
              print('Notifications pressed');
              // TODO: Navigate to Notification Page
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle), // Profile icon
            onPressed: () {
              print('Profile pressed');
              // TODO: Navigate to Profile Page
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFE0F2F7),
              Color(0xFFBBDEFB),
              Colors.blueAccent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Filter / Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  _buildFilterChip('Semua Keluhan'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Baru'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Diproses'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Selesai'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Divisi IT'),
                  // Add more chips as needed
                ],
              ),
            ),
            
            Expanded(
              child: _filteredProblemRequests.isEmpty
                  ? const Center(child: Text('Tidak ada keluhan untuk filter ini.', style: TextStyle(fontSize: 16, color: Colors.blueGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: _filteredProblemRequests.length,
                      itemBuilder: (context, index) {
                        final request = _filteredProblemRequests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: InkWell( // Make the card tappable
                            onTap: () {
                              print('Tapped on: ${request.title}');
                              // TODO: Navigate to Problem Request Detail Page
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        request.id,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(request.status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
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
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    request.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(_getCategoryIcon(request.category), size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${request.division} - ${request.category}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Prioritas: ${request.priority}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueGrey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        request.lastUpdate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Tambah Keluhan Baru pressed');
          // TODO: Navigate to Add New Problem Request Page
        },
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Assuming Home is the first tab
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        onTap: (index) {
          // Handle navigation here
          print('Bottom bar item $index tapped');
          // TODO: Implement navigation to other pages (History, Profile/Settings)
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // Or Icons.person
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          _filterRequests();
        });
      },
      selectedColor: Colors.blue.shade100, // Light blue when selected
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
        width: 1.5,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: Colors.blue.shade50,
    );
  }
}
