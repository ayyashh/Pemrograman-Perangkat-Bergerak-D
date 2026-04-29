import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/notif_service.dart';
import 'login_screen.dart';
import 'asset_form_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  List<AssetModel> _assets = [];
  List<BorrowModel> _borrows = [];
  bool _loading = false;
  final _fmt = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _assets = await DbService.syncAssets();
      await DbService.syncBorrows();
      _borrows = await DbService.getAllBorrows();
    } catch (e) {
      debugPrint('Load error: $e');
      _assets = await DbService.getAssets();
      _borrows = await DbService.getAllBorrows();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _borrows.where((b) => b.status == 'pending').length;
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        _assetsTab(),
        _requestsTab(),
        _profileTab(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Aset',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.inbox_outlined),
            ),
            activeIcon: const Icon(Icons.inbox),
            label: 'Request',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssetFormScreen()),
              ).then((_) => _load()),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ─── Tab 1: Manajemen Aset ─────────────────────────
  Widget _assetsTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Manajemen Aset',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _assets.isEmpty
                      ? const Center(child: Text('Belum ada aset. Tap + untuk tambah.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _assets.length,
                          itemBuilder: (_, i) {
                            final a = _assets[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.inventory_2, color: Colors.blue),
                                title: Text(a.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${a.category} • ${a.isActive ? "Aktif" : "Nonaktif"}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => AssetFormScreen(asset: a)),
                                      ).then((_) => _load()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(a),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AssetModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Aset'),
        content: Text('Yakin ingin menghapus "${a.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DbService.deleteAsset(a);
      _load();
    }
  }

  // ─── Tab 2: Request Peminjaman ─────────────────────
  Widget _requestsTab() {
    final pending = _borrows.where((b) => b.status == 'pending').toList();
    final history = _borrows.where((b) => b.status != 'pending').toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Request (${pending.length} pending)',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _borrows.isEmpty
                      ? const Center(child: Text('Tidak ada request peminjaman'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            if (pending.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('Menunggu Persetujuan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                              ),
                              ...pending.map((b) => _RequestCard(
                                    borrow: b,
                                    fmt: _fmt,
                                    onApprove: () => _approve(b),
                                    onReject: () => _reject(b),
                                  )),
                            ],
                            if (history.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('Riwayat',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              ...history.map((b) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(b.assetName,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${b.userName} • ${_fmt.format(b.startDate)}'),
                                      trailing: _StatusChip(b.status),
                                    ),
                                  )),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BorrowModel b) async {
    await DbService.updateBorrowStatus(b.borrowId, 'approved');
    await NotifService.showStatusNotif('approved', b.assetName);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Request disetujui'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _reject(BorrowModel b) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tolak peminjaman "${b.assetName}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final reason = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
      await DbService.updateBorrowStatus(b.borrowId, 'rejected', reason: reason);
      await NotifService.showStatusNotif('rejected', b.assetName);
      _load();
    }
    reasonCtrl.dispose();
  }

  // ─── Tab 3: Profil Admin ────────────────────────────
  Widget _profileTab() {
    final u = currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                u?.name.isNotEmpty == true ? u!.name[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(u?.name ?? '-',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(u?.email ?? '-', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Chip(label: Text('Administrator')),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.logout();
                currentUser = null;
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final BorrowModel borrow;
  final DateFormat fmt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.borrow,
    required this.fmt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(borrow.assetName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Peminjam: ${borrow.userName}'),
            Text('Tanggal: ${fmt.format(borrow.startDate)} – ${fmt.format(borrow.endDate)}'),
            if (borrow.note != null && borrow.note!.isNotEmpty)
              Text('Catatan: ${borrow.note}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.green,
      'rejected': Colors.red,
      'returned': Colors.blue,
    };
    final labels = {
      'pending': 'Menunggu',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
      'returned': 'Dikembalikan',
    };
    final color = colors[status] ?? Colors.grey;
    return Chip(
      label: Text(labels[status] ?? status,
          style: TextStyle(color: color, fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      padding: EdgeInsets.zero,
    );
  }
}
