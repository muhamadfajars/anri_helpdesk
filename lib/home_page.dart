import 'dart:async';
import 'dart:convert';
import 'package:anri/models/ticket_model.dart';
import 'package:anri/pages/home/widgets/ticket_card.dart';
import 'package:anri/pages/login_page.dart';
import 'package:anri/pages/profile_page.dart';
import 'package:anri/providers/settings_provider.dart';
import 'package:anri/providers/ticket_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anri/config/api_config.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final String currentUserName;
  final String authToken;

  const HomePage({
    super.key,
    required this.currentUserName,
    required this.authToken,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _selectedStatus = 'New';
  String _selectedPriority = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  Timer? _autoRefreshTimer;
  List<String> _teamMembers = ['Unassigned'];

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerFilterKey = GlobalKey();
  bool _isFabVisible = false;

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

  final List<String> _statusHeaderFilters = [
    'Semua Status',
    'New',
    'Waiting Reply',
  ];
  final List<String> _statusDialogFilters = [
    'Semua Status',
    'New',
    'Waiting Reply',
    'Replied',
    'In Progress',
    'On Hold',
  ];

  final List<String> _priorityDialogFilters = [
    'All',
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSearch();
      _fetchTeamMembers();
      // Panggil timer saat pertama kali halaman dibuat
      _startAutoRefreshTimer();
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _triggerSearch);
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final headerContext = _headerFilterKey.currentContext;
        if (headerContext != null) {
          final headerHeight = headerContext.size?.height ?? 200.0;
          if (_scrollController.offset > headerHeight) {
            if (!_isFabVisible) setState(() => _isFabVisible = true);
          } else {
            if (_isFabVisible) setState(() => _isFabVisible = false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _autoRefreshTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<TicketProvider>().fetchTickets(
      status: _getStatusForAPI(),
      category: _selectedCategory,
      searchQuery: _searchController.text,
      priority: _selectedPriority,
      isRefresh: true,
    );
  }

  String _getStatusForAPI() {
    if (_selectedIndex == 1) return 'Resolved';
    if (_selectedStatus == 'Semua Status') return 'All';
    return _selectedStatus;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    if (token == null) {
      if (mounted) {
        _logout(context, message: 'Sesi tidak valid. Silakan login kembali.');
      }
      return {};
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _fetchTeamMembers() async {
    final headers = await _getAuthHeaders();
    if (headers.isEmpty && mounted) return;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/get_users.php');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) {
        if (mounted) _logout(context, message: 'Sesi tidak valid.');
        return;
      }
      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          final List<String> fetchedMembers = data
              .map((user) => user['name'].toString())
              .toList();

          setState(() {
            _teamMembers = fetchedMembers.isNotEmpty
                ? fetchedMembers
                : ['Unassigned'];
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil daftar tim: $e");
    }
  }

  Future<void> _logout(BuildContext context, {String? message}) async {
    if (!mounted) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    // Ambil provider di sini. Gunakan read karena kita tidak perlu me-rebuild widget ini jika interval berubah.
    // Perubahan akan diterapkan saat pengguna pindah tab.
    final settingsProvider = context.read<SettingsProvider>();

    // Jika interval adalah 0 (Mati), jangan jalankan timer
    if (settingsProvider.refreshInterval == Duration.zero) {
      debugPrint("Auto refresh is OFF");
      return;
    }

    debugPrint(
      "Starting auto refresh timer with interval: ${settingsProvider.refreshIntervalText}",
    );
    _autoRefreshTimer = Timer.periodic(
      // Gunakan durasi dari provider
      settingsProvider.refreshInterval,
      (timer) {
        if (_selectedIndex != 2 &&
            _searchController.text.isEmpty &&
            mounted &&
            context.read<TicketProvider>().listState != ListState.loading &&
            !context.read<TicketProvider>().isLoadingMore) {
          debugPrint(
            "Auto refreshing tickets (background)...",
          ); // diubah untuk logging
          context.read<TicketProvider>().fetchTickets(
            status: _getStatusForAPI(),
            category: _selectedCategory,
            searchQuery: _searchController.text,
            priority: _selectedPriority,
            isRefresh: true,
            isBackgroundRefresh: true,
          );
        }
      },
    );
  }

  String _getPriorityIconPath(String priority) {
    switch (priority) {
      case 'Critical':
        return 'assets/images/label-critical.png';
      case 'High':
        return 'assets/images/label-high.png';
      case 'Medium':
        return 'assets/images/label-medium.png';
      case 'Low':
        return 'assets/images/label-low.png';
      default:
        // Default icon jika tidak ada yang cocok
        return 'assets/images/label-medium.png';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red.shade400;
      case 'High':
        return Colors.orange.shade400;
      case 'Medium':
        return Colors.lightGreen.shade400;
      case 'Low':
        return Colors.lightBlue.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundDecoration = BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      gradient: isDarkMode
          ? null
          : const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFE0F2F7),
                Color(0xFFBBDEFB),
                Colors.blueAccent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
    );

    return Scaffold(
      // Hapus AppBar dari sini, karena kita akan menggunakan SliverAppBar
      body: Stack(
        children: [
          // Terapkan background hanya jika bukan di tab profil
          if (_selectedIndex != 2)
            Container(decoration: pageBackgroundDecoration),
          _buildBody(),
        ],
      ),
      // FloatingActionButton dan BottomNavigationBar tetap sama
      floatingActionButton: _selectedIndex != 2 && _isFabVisible
          ? FloatingActionButton(
              onPressed: _showFilterDialog,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.filter_list),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex != index) {
            _searchController.clear();
            setState(() {
              _selectedIndex = index;
              _selectedCategory = 'All';
              _selectedStatus = 'New';
            });
            if (index != 2) {
              _triggerSearch();
              _startAutoRefreshTimer();
            } else {
              _autoRefreshTimer?.cancel();
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
      case 1:
        return RefreshIndicator(
          onRefresh: () async => _triggerSearch(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                title: _buildAppBarTitle(),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0.5,
                pinned: true,
                floating: true,
                actions: _selectedIndex == 0
                    ? [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              'Hi, ${widget.currentUserName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : null,
              ),
              SliverToBoxAdapter(child: _buildHeaderFilterBar()),
              Consumer<TicketProvider>(
                builder: (context, provider, child) {
                  switch (provider.listState) {
                    case ListState.loading:
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    case ListState.error:
                      return SliverFillRemaining(
                        child: _buildErrorState(provider.errorMessage),
                      );
                    case ListState.empty:
                      return SliverFillRemaining(child: _buildEmptyState());

                    case ListState.hasData:
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < provider.tickets.length) {
                              final ticket = provider.tickets[index];
                              return TicketCard(
                                ticket: ticket,
                                allCategories: _categories.entries
                                    .where((e) => e.key != 'All')
                                    .map((e) => e.value)
                                    .toList(),
                                allTeamMembers: _teamMembers,
                                currentUserName: widget.currentUserName,
                                onRefresh: _triggerSearch,
                              );
                            } else {
                              return _buildPaginationControl(provider);
                            }
                          },
                          childCount:
                              provider.tickets.length +
                              (provider.hasMore ? 1 : 0),
                        ),
                      );
                  }
                },
              ),
            ],
          ),
        );
      case 2:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppBarTitle() {
    if (_selectedIndex == 2) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Image.asset(
          'assets/images/anri_logo.png',
          height: 36,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Help Desk',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderFilterBar() {
    return Container(
      key: _headerFilterKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Cari tiket...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) => _triggerSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.filter_list_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                onPressed: _showFilterDialog,
                tooltip: 'Filter Lanjutan',
              ),
            ],
          ),
          if (_selectedIndex == 0) ...[
            const SizedBox(height: 16),
            Text(
              'Status',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusHeaderFilters.map((status) {
                  final isSelected = _selectedStatus == status;
                  // BARU: Tambahkan pengecekan tema
                  final isDarkMode =
                      Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatus = status);
                          _triggerSearch();
                        }
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      // DIUBAH: Logika style label dibuat kondisional
                      labelStyle: TextStyle(
                        color: isSelected
                            // Jika terpilih:
                            ? isDarkMode
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected
                            // Jika terpilih:
                            ? isDarkMode
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer.withAlpha(
                                      150,
                                    ) // Gaya lama untuk tema gelap
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(
                                      0.5,
                                    ) // Gaya baru (biru) untuk tema terang
                            // Jika tidak terpilih:
                            : isDarkMode
                            ? Theme.of(context).colorScheme.outline.withAlpha(
                                50,
                              ) // Gaya lama untuk tema gelap
                            : Colors
                                  .grey
                                  .shade300, // Gaya baru (abu-abu) untuk tema terang
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    String tempCategory = _selectedCategory;
    String tempStatus = _selectedStatus;
    String tempPriority = _selectedPriority;

    Color getStatusColor(String status) {
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final buttonShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            );
            return AlertDialog(
              title: const Text('Filter Lanjutan'),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedIndex == 0) ...[
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: tempStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: _statusDialogFilters.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status,
                              style: status == 'Semua Status'
                                  ? null
                                  : TextStyle(
                                      color: getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null)
                            setDialogState(() => tempStatus = newValue);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Prioritas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: tempPriority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _priorityDialogFilters.map((priority) {
                        if (priority == 'All') {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: const Text('Semua Prioritas'),
                          );
                        }
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Row(
                            children: [
                              Image.asset(
                                _getPriorityIconPath(priority),
                                width: 16,
                                height: 16,
                                color: _getPriorityColor(priority),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priority,
                                style: TextStyle(
                                  color: _getPriorityColor(priority),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() => tempPriority = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Kategori',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: tempCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                          setDialogState(() => tempCategory = newValue);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedCategory = tempCategory;
                          _selectedStatus = tempStatus;
                          _selectedPriority = tempPriority;
                        });
                        _triggerSearch();
                      },
                      style: FilledButton.styleFrom(shape: buttonShape),
                      child: const Text('Terapkan'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          if (_selectedIndex == 0) {
                            final bool isHeaderFilterActive =
                                _statusHeaderFilters.contains(_selectedStatus);
                            tempStatus = isHeaderFilterActive
                                ? _selectedStatus
                                : 'New';
                          }

                          // Selalu reset prioritas dan kategori
                          tempPriority = 'All';
                          tempCategory = 'All';
                        });
                      },
                      style: OutlinedButton.styleFrom(shape: buttonShape),
                      child: const Text('Atur Ulang'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    bool isSearching = _searchController.text.isNotEmpty;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // DIUBAH: Ukuran ikon diperkecil
            Icon(
              isSearching ? Icons.search_off : Icons.inbox_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            // DIUBAH: Jarak vertikal dikurangi
            const SizedBox(height: 12),
            // DIUBAH: Ukuran font judul diperkecil
            Text(
              isSearching ? 'Tiket Tidak Ditemukan' : 'Tidak Ada Tiket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            // DIUBAH: Jarak vertikal dikurangi
            const SizedBox(height: 6),
            // DIUBAH: Ukuran font sub-judul diperkecil
            Text(
              isSearching
                  ? 'Tidak ada tiket yang cocok dengan pencarian "${_searchController.text}".'
                  : 'Belum ada tiket yang cocok dengan filter yang aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            if (isSearching) ...[
              // DIUBAH: Jarak vertikal dikurangi
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Hapus Pencarian'),
                onPressed: () => _searchController.clear(),
              ),
            ],
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _triggerSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControl(TicketProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: FilledButton.icon(
          onPressed: () {
            context.read<TicketProvider>().loadMoreTickets(
              status: _getStatusForAPI(),
              category: _selectedCategory,
              searchQuery: _searchController.text,
              priority: _selectedPriority,
            );
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tampilkan Lebih Banyak'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 1,
          ),
        ),
      ),
    );
  }
}
