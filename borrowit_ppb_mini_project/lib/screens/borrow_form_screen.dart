import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/notif_service.dart';

class BorrowFormScreen extends StatefulWidget {
  final AssetModel asset;
  const BorrowFormScreen({super.key, required this.asset});
  @override
  State<BorrowFormScreen> createState() => _BorrowFormScreenState();
}

class _BorrowFormScreenState extends State<BorrowFormScreen> {
  DateTime? _start;
  DateTime? _end;
  final _note = TextEditingController();
  bool _loading = false;
  final _fmt = DateFormat('dd MMM yyyy, HH:mm');

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_start ?? now),
      firstDate: isStart ? now : (_start ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4F8EF7), surface: Color(0xFF1A1E2E)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? now : (_start ?? now)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4F8EF7), surface: Color(0xFF1A1E2E)),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final picked = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) { _start = picked; if (_end != null && _end!.isBefore(_start!)) _end = null; }
      else _end = picked;
    });
  }

  Future<void> _submit() async {
    if (currentUser == null) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih waktu mulai dan selesai')));
      return;
    }
    setState(() => _loading = true);
    try {
      final conflict = await DbService.hasConflict(widget.asset.assetId, _start!, _end!);
      if (!mounted) return;
      if (conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal bentrok! Pilih waktu lain.'),
                backgroundColor: Colors.red));
        setState(() => _loading = false);
        return;
      }
      final user = await DbService.getUser(currentUser!.uid);
      final asset = await DbService.getAssetById(widget.asset.assetId);
      if (user == null || asset == null) return;

      final borrowId = await DbService.createBorrow(
        user: user, asset: asset,
        start: _start!, end: _end!,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      await NotifService.scheduleReminder(borrowId, widget.asset.name, _end!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan berhasil diajukan!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Tempat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tempat info
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F8EF7)),
                title: Text(widget.asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${widget.asset.category} • ${widget.asset.availableQty} tersedia'),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _DateBtn('Mulai', _start, () => _pickDate(true), _fmt)),
                const SizedBox(width: 12),
                Expanded(child: _DateBtn('Selesai', _end, () => _pickDate(false), _fmt)),
              ],
            ),
            if (_start != null && _end != null) ...[
              const SizedBox(height: 8),
              Text('Durasi: ${_end!.difference(_start!).inHours} jam ${_end!.difference(_start!).inMinutes % 60} menit',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', prefixIcon: Icon(Icons.notes)),
            ),
            const SizedBox(height: 28),
            _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F8EF7)))
                : ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Permintaan'),
                    onPressed: _submit,
                  ),
          ],
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final DateFormat fmt;
  const _DateBtn(this.label, this.date, this.onTap, this.fmt);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: date != null ? const Color(0xFF4F8EF7) : const Color(0xFF252A3A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8892B0), fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              date != null ? fmt.format(date!) : 'Pilih',
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13,
                color: date != null ? Colors.white : const Color(0xFF8892B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
