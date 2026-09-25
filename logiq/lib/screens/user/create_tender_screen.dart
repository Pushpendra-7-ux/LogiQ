import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/draft_timer_provider.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/data/mock/hsn_data.dart';

class CreateTenderScreen extends StatefulWidget {
  final Tender? editingTender;

  const CreateTenderScreen({super.key, this.editingTender});

  @override
  State<CreateTenderScreen> createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _basePriceController = TextEditingController();
  final _minDecrementController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime? _pickupDate;
  DateTime? _dropDate;
  HsnEntry? _selectedHsn;
  String _selectedUnit = 'MT';
  String? _selectedVehicleType;
  bool _selectAllTransporters = true;
  List<int> _selectedTransporterIds = [];
  bool _isSubmitting = false;

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _materialUnits = const ['MT', 'Tons', 'Kg', 'Quintal', 'Bags'];
  final _vehicleTypes = const ['Truck', 'Trailer', 'Container', 'Other'];
  final _vehicleSubtitles = const {
    'Truck': 'Open / Closed body',
    'Trailer': 'Flatbed / Semi-low',
    'Container': '20ft / 40ft',
    'Other': 'Specialized vehicles',
  };

  bool _startNow = true;
  DateTime _biddingStartDate = DateTime.now();
  TimeOfDay _biddingStartTime = TimeOfDay.now();
  late DateTime _biddingEndDate;
  late TimeOfDay _biddingEndTime;
  final _dateTimeFormat = DateFormat('EEE, dd MMM yyyy, hh:mm a');
  final _timeFormat = DateFormat('hh:mm a');

  String _formatDurationDiff(Duration d) {
    if (d.inDays >= 1) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      return hours > 0 ? '$days d $hours h' : '$days ${days == 1 ? "Day" : "Days"}';
    }
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m > 0 ? '$h h $m m' : '$h ${h == 1 ? "Hour" : "Hours"}';
    }
    return '${d.inMinutes} Mins';
  }

  void _toggleStartNow(bool nowVal) {
    setState(() {
      _startNow = nowVal;
      final current = DateTime.now();
      if (nowVal) {
        _biddingStartDate = current;
        _biddingStartTime = TimeOfDay.fromDateTime(current);
        if (_biddingEndDate.isBefore(current) || _biddingEndDate.isAtSameMomentAs(current)) {
          final newEnd = current.add(const Duration(hours: 2));
          _biddingEndDate = newEnd;
          _biddingEndTime = TimeOfDay.fromDateTime(newEnd);
        }
      } else {
        if (_biddingStartDate.isBefore(current) || _biddingStartDate.isAtSameMomentAs(current)) {
          final scheduledStart = current.add(const Duration(minutes: 15));
          _biddingStartDate = scheduledStart;
          _biddingStartTime = TimeOfDay.fromDateTime(scheduledStart);
          final newEnd = scheduledStart.add(const Duration(hours: 2));
          _biddingEndDate = newEnd;
          _biddingEndTime = TimeOfDay.fromDateTime(newEnd);
        }
      }
    });
  }

  void _onScheduleTap() {
    if (!_startNow) {
      _pickBiddingStart();
    } else {
      _toggleStartNow(false);
    }
  }

  Future<void> _pickBiddingStart() async {
    final now = DateTime.now();
    final initialDate = _biddingStartDate.isBefore(now) ? now : _biddingStartDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.logiqGreen,
            onPrimary: AppColors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _biddingStartTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.logiqGreen,
            onPrimary: AppColors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final combinedStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combinedStart.isBefore(now.subtract(const Duration(minutes: 1)))) {
      _showError('Start time cannot be in the past');
      return;
    }

    setState(() {
      _startNow = false;
      _biddingStartDate = combinedStart;
      _biddingStartTime = pickedTime;
      if (_biddingEndDate.isBefore(combinedStart) || _biddingEndDate.isAtSameMomentAs(combinedStart)) {
        final newEnd = combinedStart.add(const Duration(hours: 2));
        _biddingEndDate = newEnd;
        _biddingEndTime = TimeOfDay.fromDateTime(newEnd);
      }
    });
  }

  Future<void> _pickBiddingEnd() async {
    final currentStart = _startNow ? DateTime.now() : _biddingStartDate;
    final initialDate = _biddingEndDate.isBefore(currentStart) ? currentStart : _biddingEndDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentStart,
      lastDate: currentStart.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.logiqGreen,
            onPrimary: AppColors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _biddingEndTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.logiqGreen,
            onPrimary: AppColors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final combinedEnd = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combinedEnd.isBefore(currentStart) || combinedEnd.isAtSameMomentAs(currentStart)) {
      _showError('Ending date and time must be after starting date and time');
      return;
    }

    setState(() {
      _biddingEndDate = combinedEnd;
      _biddingEndTime = pickedTime;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _biddingStartDate = now;
    _biddingStartTime = TimeOfDay.fromDateTime(now);
    final initialEnd = now.add(const Duration(hours: 2));
    _biddingEndDate = initialEnd;
    _biddingEndTime = TimeOfDay.fromDateTime(initialEnd);
    _initFromEditingTender();
  }

  @override
  void didUpdateWidget(covariant CreateTenderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingTender?.id != oldWidget.editingTender?.id) {
      _initFromEditingTender();
    }
  }

  void _initFromEditingTender() {
    if (widget.editingTender != null) {
      final t = widget.editingTender!;
      _pickupController.text = t.pickup;
      _dropController.text = t.drop;
      _pickupDate = t.deliveryStart;
      _dropDate = t.deliveryEnd;
      _basePriceController.text = t.ceilingBid.toInt().toString();
      _minDecrementController.text = t.minDecrement.toInt().toString();
      _remarksController.text = t.remarks;
      _selectedVehicleType = t.vehicleType;

      final now = DateTime.now();
      _biddingStartDate = t.biddingStart;
      _biddingStartTime = TimeOfDay.fromDateTime(t.biddingStart);
      _biddingEndDate = t.softEnd;
      _biddingEndTime = TimeOfDay.fromDateTime(t.softEnd);
      _startNow = t.biddingStart.isBefore(now) || t.status == TenderStatus.stage1;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || t.id == null) return;
        final tenderProvider = context.read<TenderProvider>();
        final mats = await tenderProvider.materialsFor(t.id!);
        final parts = await tenderProvider.participantsFor(t.id!);
        if (mounted) {
          setState(() {
            if (mats.isNotEmpty) {
              _qtyController.text = mats.first.quantity.toInt().toString();
              _selectedUnit = mats.first.unit;
              _selectedHsn = HsnData.entries.firstWhere(
                (h) => h.code == mats.first.hsnCode,
                orElse: () => HsnEntry(code: mats.first.hsnCode, name: mats.first.description, unit: mats.first.unit),
              );
            }
            if (parts.isNotEmpty) {
              _selectAllTransporters = false;
              _selectedTransporterIds = parts;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _qtyController.dispose();
    _basePriceController.dispose();
    _minDecrementController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPickup) async {
    final initial = isPickup ? (_pickupDate ?? DateTime.now()) : (_dropDate ?? (_pickupDate ?? DateTime.now()));
    final first = isPickup ? DateTime.now() : (_pickupDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.logiqGreen,
            onPrimary: AppColors.white,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          if (_dropDate != null && _dropDate!.isBefore(picked)) _dropDate = picked;
        } else {
          _dropDate = picked;
        }
      });
    }
  }

  void _showHsnPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _HsnSheet(onSelected: (hsn) {
        setState(() => _selectedHsn = hsn);
        Navigator.pop(ctx);
      }),
    );
  }

  Future<void> _selectTransporters() async {
    final result = await context.push<List<int>>('/transporter-selection');
    if (result != null) setState(() => _selectedTransporterIds = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null || _dropDate == null) return _showError('Please select pickup and drop dates');
    if (_selectedHsn == null) return _showError('Please select a material/HSN');
    if (_selectedVehicleType == null) return _showError('Please select a vehicle type');
    if (!_selectAllTransporters && _selectedTransporterIds.isEmpty) return _showError('Please choose transporters');

    setState(() => _isSubmitting = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.id ?? 0;
      final ceilingBid = double.tryParse(_basePriceController.text) ?? 75000;
      final minDecrement = double.tryParse(_minDecrementController.text) ?? 500;
      final qty = double.tryParse(_qtyController.text) ?? 1;

      final materials = <MaterialItem>[
        MaterialItem(
          hsnCode: _selectedHsn?.code ?? '',
          description: _selectedHsn?.name ?? 'General Cargo',
          quantity: qty,
          unit: _selectedUnit,
        ),
      ];

      final pickupCity = _pickupController.text.split(',').first.trim();
      final dropCity = _dropController.text.split(',').first.trim();
      final now = DateTime.now();
      final effectiveStart = _startNow ? now : _biddingStartDate;
      final effectiveEnd = _biddingEndDate.isAfter(effectiveStart)
          ? _biddingEndDate
          : effectiveStart.add(const Duration(hours: 2));

      if (!_startNow && effectiveStart.isBefore(now.subtract(const Duration(minutes: 2)))) {
        return _showError('Start time for scheduled auction cannot be in the past');
      }

      if (effectiveEnd.isBefore(effectiveStart) || effectiveEnd.isAtSameMomentAs(effectiveStart)) {
        return _showError('Ending date and time must be after starting date and time');
      }

      if (widget.editingTender != null) {
        final updatedTender = widget.editingTender!.copyWith(
          title: '${_selectedHsn?.name ?? "Freight"} — $pickupCity to $dropCity',
          pickup: _pickupController.text.trim(),
          drop: _dropController.text.trim(),
          deliveryStart: _pickupDate!,
          deliveryEnd: _dropDate!,
          biddingStart: effectiveStart,
          softEnd: effectiveEnd,
          hardStop: effectiveEnd.add(const Duration(minutes: 5)),
          closingDate: effectiveEnd,
          ceilingBid: ceilingBid,
          minDecrement: minDecrement,
          remarks: _remarksController.text.trim(),
          vehicleType: _selectedVehicleType ?? 'Truck',
        );

        final success = await context.read<TenderProvider>().updateDraft(
          tenderId: widget.editingTender!.id!,
          tender: updatedTender,
          materials: materials,
          transporterIds: _selectAllTransporters ? [] : _selectedTransporterIds,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tender updated successfully'),
              backgroundColor: AppColors.logiqGreen,
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/active-tenders');
          }
        }
      } else {
        final result = await context.read<TenderProvider>().createTenderAsDraft(
          title: '${_selectedHsn?.name ?? "Freight"} — $pickupCity to $dropCity',
          pickup: _pickupController.text.trim(),
          drop: _dropController.text.trim(),
          deliveryStart: _pickupDate!,
          deliveryEnd: _dropDate!,
          materials: materials,
          transporterIds: _selectAllTransporters ? [] : _selectedTransporterIds,
          ceilingBid: ceilingBid,
          minDecrement: minDecrement,
          createdBy: userId,
          remarks: _remarksController.text.trim(),
          vehicleType: _selectedVehicleType ?? 'Truck',
          biddingStart: effectiveStart,
          biddingEnd: effectiveEnd,
          startNow: _startNow,
          biddingDuration: effectiveEnd.difference(effectiveStart),
        );

        if (result != null && mounted) {
          final publishAt = DateTime.now().add(const Duration(minutes: 3));
          try {
            context.read<DraftTimerProvider>().registerDraft(result, publishAt);
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tender saved to Drafts (3-min review window)'),
              backgroundColor: AppColors.logiqGreen,
            ),
          );
          context.go('/drafts');
        }
      }
    } catch (e) {
      _showError('Failed to save tender: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _inputDecor(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.logiqGreen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingTender != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Tender Draft' : 'Create Tender',
                      style: AppTextStyles.h2,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.logiqGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.logiqGreenLight),
                          const SizedBox(width: 4),
                          Text(
                            isEditing ? 'Draft' : 'Reverse',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.logiqGreenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Update freight tender specifications' : 'Spot reverse auction',
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 16),

                      _sectionHeader('ROUTE & SCHEDULE'),
                      TextFormField(
                        controller: _pickupController,
                        decoration: _inputDecor('Pickup (Origin)', suffix: const Icon(Icons.location_on, color: AppColors.inkSoft)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dropController,
                        decoration: _inputDecor('Drop (Destination)', suffix: const Icon(Icons.location_on_outlined, color: AppColors.inkSoft)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _dateTile('Pickup Date', _pickupDate, () => _pickDate(true))),
                          const SizedBox(width: 16),
                          Expanded(child: _dateTile('Drop Date', _dropDate, () => _pickDate(false))),
                        ],
                      ),

                      _sectionHeader('MATERIAL & WEIGHT'),
                      _hsnSelector(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecor('Quantity'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _materialUnits.map((unit) {
                                  final sel = _selectedUnit == unit;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(unit),
                                      selected: sel,
                                      onSelected: (s) { if (s) setState(() => _selectedUnit = unit); },
                                      selectedColor: AppColors.logiqGreenBg,
                                      backgroundColor: AppColors.white,
                                      labelStyle: AppTextStyles.body.copyWith(
                                        color: sel ? AppColors.logiqGreenDark : AppColors.ink,
                                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      side: BorderSide(color: sel ? AppColors.logiqGreen : AppColors.outline),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      _sectionHeader('VEHICLE TYPE REQUIRED'),
                      _vehicleGrid(),

                      _sectionHeader('PRICING CAP & BID RULES'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _basePriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecor('Ceiling Bid (Max)', suffix: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('₹', style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
                              )),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minDecrementController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecor('Min Decrement', suffix: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('₹', style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
                              )),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Transporters bid downwards from the ceiling in reverse auction.', style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),

                      _sectionHeader('BIDDING SCHEDULE & TIMING (ROUND 1)'),
                      _biddingTimingSection(),

                      _sectionHeader('REMARKS'),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _inputDecor('Special Instructions').copyWith(
                          hintText: 'Tarpaulin cover mandatory. Loading: 08:00 AM - 04:00 PM...',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkFaint),
                        ),
                      ),

                      _sectionHeader('VERIFIED TRANSPORTERS'),
                      _transporterSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.logiqGreen,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.outline,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : Text(isEditing ? 'Save Changes' : 'Create Tender', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(title, style: AppTextStyles.labelBold.copyWith(color: AppColors.inkSoft, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 4),
            Text(
              date == null ? 'Select Date' : _dateFormat.format(date),
              style: AppTextStyles.body.copyWith(color: date == null ? AppColors.inkFaint : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hsnSelector() {
    return InkWell(
      onTap: _showHsnPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commodity / HSN', style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedHsn == null ? 'Search HSN or commodity...' : 'HSN ${_selectedHsn!.code} – ${_selectedHsn!.name}',
                    style: AppTextStyles.body.copyWith(color: _selectedHsn == null ? AppColors.inkFaint : AppColors.ink),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _vehicleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.5),
      itemCount: _vehicleTypes.length,
      itemBuilder: (_, i) {
        final type = _vehicleTypes[i];
        final sel = _selectedVehicleType == type;
        return InkWell(
          onTap: () => setState(() => _selectedVehicleType = type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: sel ? AppColors.logiqGreen : AppColors.outline, width: sel ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? AppColors.logiqGreen : AppColors.inkFaint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type, style: AppTextStyles.body.copyWith(fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                      if (_vehicleSubtitles[type] != null)
                        Text(_vehicleSubtitles[type]!, style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _transporterSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.logiqGreen, size: 20),
                const SizedBox(width: 8),
                Text('Admin-Approved Only', style: AppTextStyles.labelBold.copyWith(color: AppColors.logiqGreenDark)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          _transporterOption(
            selected: _selectAllTransporters,
            title: 'Select All Transporters',
            subtitle: 'All admin-approved transporters can participate.',
            onTap: () => setState(() => _selectAllTransporters = true),
          ),
          const Divider(height: 1, color: AppColors.outline),
          _transporterOption(
            selected: !_selectAllTransporters,
            title: 'Choose Specific Transporters',
            subtitle: 'Handpick approved transporters for this tender.',
            onTap: () => setState(() => _selectAllTransporters = false),
            showPicker: !_selectAllTransporters,
          ),
        ],
      ),
    );
  }

  Widget _transporterOption({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showPicker = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? AppColors.logiqGreen : AppColors.inkFaint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
                  if (showPicker) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectTransporters,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.logiqGreenBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.logiqGreenBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.logiqGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTransporterIds.isEmpty
                                    ? 'No transporters selected'
                                    : '✓ ${_selectedTransporterIds.length} transporters selected',
                                style: AppTextStyles.body.copyWith(color: AppColors.logiqGreenDark, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text('Change →', style: AppTextStyles.caption.copyWith(color: AppColors.logiqGreen, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _biddingTimingSection() {
    final now = DateTime.now();
    final effectiveStart = _startNow ? now : _biddingStartDate;
    final effectiveEnd = _biddingEndDate.isAfter(effectiveStart)
        ? _biddingEndDate
        : effectiveStart.add(const Duration(hours: 2));
    final totalDiff = effectiveEnd.difference(effectiveStart);
    final durationLabel = _formatDurationDiff(totalDiff);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.logiqGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Round 1 Bidding Window',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.ink),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.logiqGreenBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.logiqGreenBorder),
                ),
                child: Text(
                  _startNow ? 'STARTS NOW' : 'SCHEDULED',
                  style: const TextStyle(
                    color: AppColors.logiqGreenDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure starting and ending date & time for carrier reverse auction.',
            style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),

          Text(
            'STARTING DATE & TIME',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.inkSoft, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _toggleStartNow(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _startNow ? AppColors.logiqGreenBg : AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _startNow ? AppColors.logiqGreen : AppColors.outline,
                        width: _startNow ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 18,
                          color: _startNow ? AppColors.logiqGreenDark : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Now (Immediate)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _startNow ? FontWeight.w700 : FontWeight.w500,
                            color: _startNow ? AppColors.logiqGreenDark : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _onScheduleTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: !_startNow ? AppColors.logiqGreenBg : AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_startNow ? AppColors.logiqGreen : AppColors.outline,
                        width: !_startNow ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: !_startNow ? AppColors.logiqGreenDark : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Schedule Date/Time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !_startNow ? FontWeight.w700 : FontWeight.w500,
                            color: !_startNow ? AppColors.logiqGreenDark : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _startNow ? null : _pickBiddingStart,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    _startNow ? Icons.bolt : Icons.calendar_today,
                    size: 20,
                    color: AppColors.logiqGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _startNow ? 'Starts Immediately' : 'Starts At',
                          style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _startNow
                              ? 'Now (Upon tender creation)'
                              : _dateTimeFormat.format(_biddingStartDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _startNow ? AppColors.logiqGreenDark : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_startNow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_calendar, size: 14, color: AppColors.logiqGreen),
                          SizedBox(width: 4),
                          Text('Pick Date/Time', style: TextStyle(color: AppColors.logiqGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.logiqGreenBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.logiqGreenBorder),
                      ),
                      child: const Text('Immediate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.logiqGreenDark)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'ENDING DATE & TIME',
            style: AppTextStyles.labelBold.copyWith(color: AppColors.inkSoft, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickBiddingEnd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: AppColors.logiqGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Closes At', style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
                        const SizedBox(height: 2),
                        Text(
                          _dateTimeFormat.format(effectiveEnd),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_calendar, size: 14, color: AppColors.logiqGreen),
                        SizedBox(width: 4),
                        Text('Pick Date/Time', style: TextStyle(color: AppColors.logiqGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.logiqGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Round 1 Timeline & Information',
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.ink, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _startNow
                      ? 'Round 1 will be from Now until ${_dateTimeFormat.format(effectiveEnd)} ($durationLabel).'
                      : 'Round 1 will be from ${_dateTimeFormat.format(effectiveStart)} to ${_dateTimeFormat.format(effectiveEnd)} ($durationLabel).',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.logiqGreenDark,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _startNow
                      ? 'Participating carriers can bid immediately upon tender creation. When the timer closes at ${_timeFormat.format(effectiveEnd)}, top 5 carriers (L1–L5) qualify for Round 2 Blind Auction.'
                      : 'Bidding remains locked until the scheduled start time. Carriers then submit reverse auction bids until ${_dateTimeFormat.format(effectiveEnd)}, when top 5 carriers (L1–L5) qualify for Round 2 Blind Auction.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HsnSheet extends StatefulWidget {
  final Function(HsnEntry) onSelected;
  const _HsnSheet({required this.onSelected});

  @override
  State<_HsnSheet> createState() => _HsnSheetState();
}

class _HsnSheetState extends State<_HsnSheet> {
  final _controller = TextEditingController();
  List<HsnEntry> _entries = HsnData.entries;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _entries = HsnData.search(_controller.text)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Commodity / HSN', style: AppTextStyles.h2),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search by name or HSN code...',
              prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _entries.isEmpty
                ? Center(child: Text('No commodities found.', style: AppTextStyles.bodyMuted))
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.outline),
                    itemBuilder: (_, i) {
                      final hsn = _entries[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('HSN ${hsn.code}', style: AppTextStyles.labelBold),
                        subtitle: Text(hsn.name, style: AppTextStyles.bodyMuted),
                        onTap: () => widget.onSelected(hsn),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
