// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/notif_service.dart';
import 'login_screen.dart';
import 'borrow_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      if (currentUser != null) {
        await DbService.syncBorrows(userId: currentUser!.uid);
        _borrows = await DbService.getBorrowsByUser(currentUser!.uid);
      }
    } catch (_) {
      _assets = await DbService.getAssets();
      if (currentUser != null) _borrows = await DbService.getBorrowsByUser(currentUser!.uid);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        _assetsTab(),
        _borrowsTab(),
        _profileTab(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Peminjaman'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // ─── Tab 1: Daftar Aset ───────────────────────────────
  Widget _assetsTab() {
    final active = _assets.where((a) => a.isActive).toList();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Halo, ${currentUser?.name ?? ''}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : active.isEmpty
                      ? const Center(child: Text('Belum ada aset'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            childAspectRatio: 0.8,
                            mainAxisSpacing: 10, 
                            crossAxisSpacing: 10,
                          ),
                          itemCount: active.length,
                          itemBuilder: (_, i) => _AssetCard(
                            asset: active[i],
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => BorrowFormScreen(asset: active[i])))
                                .then((_) => _load()),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Peminjaman Saya ───────────────────────────
  Widget _borrowsTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Peminjaman Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _borrows.isEmpty
                  ? const Center(child: Text('Belum ada peminjaman', style: TextStyle(color: Color(0xFF8892B0))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _borrows.length,
                      itemBuilder: (_, i) {
                        final b = _borrows[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(b.assetName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                  _StatusChip(b.status),
                                ]),
                                const SizedBox(height: 4),
                                Text('${_fmt.format(b.startDate)} - ${_fmt.format(b.endDate)}',
                                    style: const TextStyle(color: Color(0xFF8892B0), fontSize: 12)),
                                if (b.note != null && b.note!.isNotEmpty)
                                  Text('${b.note}', style: const TextStyle(color: Color(0xFF8892B0), fontSize: 12)),
                                if (b.rejectionReason != null)
                                  Text('${b.rejectionReason}',
                                      style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                                if (b.status == 'approved') ...[
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('Foto & Kembalikan'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      side: const BorderSide(color: Colors.green),
                                    ),
                                    onPressed: () => _returnWithCamera(b),
                                  ),
                                ],
                                if (b.returnProofPath != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(b.returnProofPath!),
                                        height: 70, width: double.infinity, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                  ),
                                ],
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

  Future<void> _returnWithCamera(BorrowModel b) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (!mounted) return;
    await DbService.confirmReturn(b.borrowId, proofPath: picked?.path);
    await NotifService.cancelReminder(b.borrowId);
    await NotifService.showStatusNotif('returned', b.assetName);
    _load();
  }

  // ─── Tab 3: Profil ────────────────────────────────────
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
              backgroundColor: const Color(0xFF4F8EF7),
              child: Text(u?.name.isNotEmpty == true ? u!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(u?.name ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(u?.email ?? '-', style: const TextStyle(color: Color(0xFF8892B0))),
            const SizedBox(height: 8),
            Chip(
              label: Text(u?.role == 'admin' ? 'Administrator' : 'User'),
              backgroundColor: const Color(0xFF4F8EF7).withOpacity(0.15),
              labelStyle: const TextStyle(color: Color(0xFF4F8EF7)),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                await AuthService.logout();
                currentUser = null;
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────

class _AssetCard extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;
  const _AssetCard({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: asset.imagePath != null
                  ? Image.file(File(asset.imagePath!), height: 100, width: double.infinity,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) => _iconBox())
                  : _iconBox(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(asset.category, style: const TextStyle(color: Color(0xFF8892B0), fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  asset.availableQty > 0 ? '${asset.availableQty} tersedia' : 'Tidak tersedia',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: asset.availableQty > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
    height: 100, width: double.infinity,
    color: const Color(0xFF4F8EF7).withOpacity(0.1),
    child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF4F8EF7)),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': Colors.orange, 'approved': Colors.green,
      'rejected': Colors.red, 'returned': Colors.blue,
    };
    final labels = {
      'pending': 'Menunggu', 'approved': 'Disetujui',
      'rejected': 'Ditolak', 'returned': 'Dikembalikan',
    };
    final c = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(labels[status] ?? status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
