import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/tender_provider.dart';
import '../../services/tender_service.dart';
import '../../models/material_item.dart';
import '../../core/theme/app_colors.dart';

class CreateTenderScreen extends StatefulWidget {
  const CreateTenderScreen({super.key});
  @override State<CreateTenderScreen> createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Steel Transport');
  final _pickupCtrl = TextEditingController(text: 'Gwalior');
  final _dropCtrl = TextEditingController(text: 'Raipur');
  final _priceDiffCtrl = TextEditingController(text: '25');

  DateTime _delivStart = DateTime.now().add(const Duration(days: 3));
  DateTime _delivEnd = DateTime.now().add(const Duration(days: 5));
  final DateTime _closingDate = DateTime.now().add(const Duration(days: 2));
  final DateTime _bidStart = DateTime.now().add(const Duration(hours: 1));
  final DateTime _softEnd = DateTime.now().add(const Duration(hours: 1, minutes: 30));
  final DateTime _hardStop = DateTime.now().add(const Duration(hours: 2));

  final List<MaterialItem> _materials = [
    MaterialItem(hsnCode: '7208', description: 'Steel Sheets', quantity: 25, unit: 'MT', remarks: 'Handle with care')
  ];

  List<Map<String, dynamic>> _transporters = [];
  final Set<int> _selectedTransporters = {};
  bool _loadingTransporters = false;

  @override
  void initState() {
    super.initState();
    _loadTransporters();
  }

  Future<void> _loadTransporters() async {
    setState(() => _loadingTransporters = true);
    try {
      final list = await TenderService().getApprovedTransporters();
      setState(() {
        _transporters = list;
        for (var t in list) {
          _selectedTransporters.add(t['id'] as int);
        }
      });
    } catch (_) {}
    setState(() => _loadingTransporters = false);
  }

  void _addMaterialDialog() {
    final hsnCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String unit = 'MT';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Add Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN Code (e.g. 7208)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Material Description')),
                const SizedBox(height: 12),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unit,
                  items: const [
                    DropdownMenuItem(value: 'MT', child: Text('MT (Metric Ton)')),
                    DropdownMenuItem(value: 'KG', child: Text('KG (Kilogram)')),
                    DropdownMenuItem(value: 'TONS', child: Text('TONS')),
                    DropdownMenuItem(value: 'PCS', child: Text('Pieces')),
                  ],
                  onChanged: (v) => setDState(() => unit = v ?? 'MT'),
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  setState(() {
                    _materials.add(MaterialItem(
                      hsnCode: hsnCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      quantity: double.tryParse(qtyCtrl.text) ?? 1,
                      unit: unit,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildTenderPayload(String status) {
    return {
      'title': _titleCtrl.text.trim(),
      'pickup_location': _pickupCtrl.text.trim(),
      'drop_location': _dropCtrl.text.trim(),
      'delivery_start': DateFormat('yyyy-MM-dd').format(_delivStart),
      'delivery_end': DateFormat('yyyy-MM-dd').format(_delivEnd),
      'tender_closing_date': _closingDate.toIso8601String(),
      'bidding_start_time': _bidStart.toIso8601String(),
      'soft_end_time': _softEnd.toIso8601String(),
      'hard_stop_time': _hardStop.toIso8601String(),
      'price_difference': double.tryParse(_priceDiffCtrl.text) ?? 25.0,
      'status': status,
      'materials': _materials.map((m) => m.toJson()).toList(),
      'participant_ids': _selectedTransporters.toList(),
    };
  }

  Future<void> _saveDraft() async {
    final tp = context.read<TenderProvider>();
    final payload = _buildTenderPayload('DRAFT');
    final res = await tp.createTender(payload);
    if (!mounted) return;
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tender saved as draft')));
      context.pop();
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least 1 material')));
      return;
    }
    if (_selectedTransporters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 approved transporter')));
      return;
    }
    final tp = context.read<TenderProvider>();
    final payload = _buildTenderPayload('DRAFT');
    final tender = await tp.createTender(payload);
    if (!mounted) return;
    if (tender != null) {
      final ok = await tp.publishTender(tender.id);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Tender Published Successfully!'), backgroundColor: AppColors.success));
        context.go('/user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tender Requirement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tender Title', prefixIcon: Icon(Icons.description)),
              validator: (v) => v!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            // Route
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pickupCtrl,
                    decoration: const InputDecoration(labelText: 'Pickup Location', prefixIcon: Icon(Icons.location_on, color: AppColors.primary)),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward)),
                Expanded(
                  child: TextFormField(
                    controller: _dropCtrl,
                    decoration: const InputDecoration(labelText: 'Drop Location', prefixIcon: Icon(Icons.flag, color: AppColors.accent)),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Delivery window
            const Text('Delivery Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _delivStart, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) setState(() => _delivStart = picked);
                    },
                    child: Text('From: ${dateFormat.format(_delivStart)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _delivEnd, firstDate: _delivStart, lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) setState(() => _delivEnd = picked);
                    },
                    child: Text('To: ${dateFormat.format(_delivEnd)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bidding Config & Price Difference
            const Text('Bidding Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceDiffCtrl,
              decoration: const InputDecoration(labelText: 'Minimum Decrement (Price Difference)', prefixText: '₹ ', helperText: 'Default: ₹25. Each new bid must beat L1 by at least this amount.'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Materials
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Materials to Transport', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(onPressed: _addMaterialDialog, icon: const Icon(Icons.add), label: const Text('ADD MATERIAL')),
              ],
            ),
            ..._materials.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                    title: Text('${m.description} — ${m.quantity} ${m.unit}'),
                    subtitle: Text('HSN: ${m.hsnCode ?? "N/A"} ${m.remarks != null ? "• ${m.remarks!}" : ""}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => setState(() => _materials.remove(m)),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            // Transporters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Transporters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedTransporters.length == _transporters.length) {
                        _selectedTransporters.clear();
                      } else {
                        for (var t in _transporters) {
                          _selectedTransporters.add(t['id'] as int);
                        }
                      }
                    });
                  },
                  child: Text(_selectedTransporters.length == _transporters.length ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
            if (_loadingTransporters)
              const Center(child: CircularProgressIndicator())
            else
              ..._transporters.map((t) => CheckboxListTile(
                    value: _selectedTransporters.contains(t['id']),
                    title: Text(t['company_name'] ?? t['name'] ?? 'Transporter'),
                    subtitle: Text('GST: ${t['gst_number'] ?? "Verified"}'),
                    onChanged: (chk) {
                      setState(() {
                        if (chk == true) {
                          _selectedTransporters.add(t['id'] as int);
                        } else {
                          _selectedTransporters.remove(t['id'] as int);
                        }
                      });
                    },
                  )),
            const SizedBox(height: 24),
            // Bottom Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveDraft,
                    child: const Text('SAVE AS DRAFT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _publish,
                    child: const Text('PUBLISH TENDER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}