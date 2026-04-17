import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/data/country_defaults.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/services/energy_calculator.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/energy_setup_screen.dart';
import 'package:carbon_tracker/widgets/screen_shell.dart';
import 'package:carbon_tracker/widgets/voetje_button.dart';

class AddEnergyScreen extends StatefulWidget {
  const AddEnergyScreen({super.key});

  @override
  State<AddEnergyScreen> createState() => _AddEnergyScreenState();
}

class _AddEnergyScreenState extends State<AddEnergyScreen> {
  final _electricKwhCtrl = TextEditingController();
  final _electricCostCtrl = TextEditingController();
  bool _useElectricCost = false;
  final _gasKwhCtrl = TextEditingController();
  final _gasCostCtrl = TextEditingController();
  bool _useGasCost = false;
  late DateTime _billingMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to last month — handle January explicitly to avoid month=0 ambiguity.
    _billingMonth = now.month == 1
        ? DateTime(now.year - 1, 12)
        : DateTime(now.year, now.month - 1);
  }

  @override
  void dispose() {
    _electricKwhCtrl.dispose();
    _electricCostCtrl.dispose();
    _gasKwhCtrl.dispose();
    _gasCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<EmissionProvider>();
    final profile = provider.energyProfile;

    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Energy not set up yet.')),
        );
      }
      return;
    }

    final entries = <EmissionEntry>[];
    final monthStr =
        '${_billingMonth.year}/${_billingMonth.month.toString().padLeft(2, '0')}';

    // Electricity entry
    double electricKwh = 0;
    if (_useElectricCost && _electricCostCtrl.text.isNotEmpty) {
      final costValue = double.tryParse(_electricCostCtrl.text) ?? 0.0;
      if (costValue > 0) {
        electricKwh = EnergyCalculator.costToKwh(
          cost: costValue,
          countryCode: profile.countryCode,
        );
      }
    } else if (!_useElectricCost && _electricKwhCtrl.text.isNotEmpty) {
      electricKwh = double.tryParse(_electricKwhCtrl.text) ?? 0.0;
    }

    if (electricKwh > 0) {
      final householdCO2 = EnergyCalculator.electricityCO2(
        kWh: electricKwh,
        countryCode: profile.countryCode,
        stateCode: profile.stateCode,
      );
      final personalCO2 = EnergyCalculator.personalCO2(
        householdCO2: householdCO2,
        householdSize: profile.householdSize,
      );
      entries.add(EmissionEntry(
        date: _billingMonth,
        category: EmissionCategory.energy,
        subCategory: 'electricity',
        value: electricKwh,
        co2Kg: personalCO2,
        note: 'Electricity — $monthStr',
      ));
    }

    // Gas entry
    double gasKwh = 0;
    if (_useGasCost && _gasCostCtrl.text.isNotEmpty) {
      final costValue = double.tryParse(_gasCostCtrl.text) ?? 0.0;
      if (costValue > 0) {
        gasKwh = EnergyCalculator.costToKwh(
          cost: costValue,
          countryCode: profile.countryCode,
          isGas: true,
        );
      }
    } else if (!_useGasCost && _gasKwhCtrl.text.isNotEmpty) {
      gasKwh = double.tryParse(_gasKwhCtrl.text) ?? 0.0;
    }

    if (gasKwh > 0) {
      final householdCO2 = EnergyCalculator.gasCO2(kWh: gasKwh);
      final personalCO2 = EnergyCalculator.personalCO2(
        householdCO2: householdCO2,
        householdSize: profile.householdSize,
      );
      entries.add(EmissionEntry(
        date: _billingMonth,
        category: EmissionCategory.energy,
        subCategory: 'gas',
        value: gasKwh,
        co2Kg: personalCO2,
        note: 'Gas — $monthStr',
      ));
    }

    // Validate that at least one valid entry was created.
    if (entries.isEmpty) {
      if (mounted) {
        final hasInput = _electricKwhCtrl.text.isNotEmpty ||
            _electricCostCtrl.text.isNotEmpty ||
            _gasKwhCtrl.text.isNotEmpty ||
            _gasCostCtrl.text.isNotEmpty;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasInput
                  ? 'Please enter valid numbers.'
                  : 'Please enter at least one energy value.',
            ),
          ),
        );
      }
      return;
    }

    // Check for existing entries for this billing month and prompt to replace.
    final billingMonthEnd =
        DateTime(_billingMonth.year, _billingMonth.month + 1);
    final existingForMonth = await provider.db.getEntries(
      startDate: _billingMonth,
      endDate: billingMonthEnd,
      category: EmissionCategory.energy,
    );
    final existingSubCats =
        existingForMonth.map((e) => e.subCategory).toSet();
    final conflicts =
        entries.where((e) => existingSubCats.contains(e.subCategory)).toList();

    if (conflicts.isNotEmpty) {
      if (!mounted) return;
      final monthStr =
          '${_billingMonth.year}/${_billingMonth.month.toString().padLeft(2, '0')}';
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace existing entry?'),
          content: Text(
            'You already have ${conflicts.map((e) => e.subCategory).join(' & ')} data for $monthStr. Replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    final idsToDelete = conflicts.isEmpty
        ? <int>[]
        : existingForMonth
            .where((e) =>
                conflicts.any((c) => c.subCategory == e.subCategory) &&
                e.id != null)
            .map((e) => e.id!)
            .toList();

    await provider.batchReplace(
      idsToDelete: idsToDelete,
      entriesToInsert: entries,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmissionProvider>();
    final profile = provider.energyProfile;

    if (profile == null) {
      return VoetjeScreenShell(
        title: 'Enter Energy Bill',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F3E0}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Set up Energy tracking',
                  style: VoetjeTypography.sectionHeader(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer 4 quick questions about your home to start.',
                  textAlign: TextAlign.center,
                  style: VoetjeTypography.body(),
                ),
                const SizedBox(height: 24),
                VoetjeButton(
                  label: 'Set up now',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EnergySetupScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final country = CountryDefaults.forCode(profile.countryCode);
    final currencyLabel = 'Cost (${country.currencySymbol})';

    return VoetjeScreenShell(
      title: 'Enter Energy Bill',
      child: ListView(
        padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
        children: [
          // Month selector card
          Container(
            decoration: BoxDecoration(
              color: VoetjeColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(VoetjeRadius.card),
              boxShadow: const [
                BoxShadow(
                  color: VoetjeColors.shadowLight,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                )
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.calendar_month,
                  color: VoetjeColors.primaryMediumOf(context)),
              title: Text(
                'Billing month: ${_billingMonth.year}/${_billingMonth.month.toString().padLeft(2, '0')}',
                style: VoetjeTypography.body(),
              ),
              trailing: Icon(Icons.edit,
                  size: 18, color: VoetjeColors.textMutedOf(context)),
              onTap: _pickMonth,
            ),
          ),
          const SizedBox(height: 20),

          // Electricity section
          Text('ELECTRICITY', style: VoetjeTypography.sectionLabel().copyWith(
            color: VoetjeColors.labelColorOf(context),
          )),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: VoetjeColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(VoetjeRadius.card),
              boxShadow: const [
                BoxShadow(
                  color: VoetjeColors.shadowLight,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                )
              ],
            ),
            padding: const EdgeInsets.all(VoetjeSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _useElectricCost
                          ? _buildInput(
                              controller: _electricCostCtrl,
                              labelText: currencyLabel,
                            )
                          : _buildInput(
                              controller: _electricKwhCtrl,
                              labelText: 'kWh used',
                            ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(
                          () => _useElectricCost = !_useElectricCost),
                      child: Text(
                        _useElectricCost ? 'Use kWh' : 'Use cost',
                        style: VoetjeTypography.caption().copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VoetjeColors.primaryMediumOf(context),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  icon: Icon(Icons.help_outline,
                      size: 14, color: VoetjeColors.textMutedOf(context)),
                  label: Text(
                    'Where do I find kWh on my bill?',
                    style: VoetjeTypography.caption().copyWith(
                          fontSize: 12,
                          color: VoetjeColors.textMutedOf(context),
                        ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showKwhHelp(context),
                ),
              ],
            ),
          ),

          // Gas section — only shown for countries with gas heating data
          if (country.hasGas) ...[
            const SizedBox(height: 20),
            Text('GAS', style: VoetjeTypography.sectionLabel().copyWith(
              color: VoetjeColors.labelColorOf(context),
            )),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: VoetjeColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(VoetjeRadius.card),
                boxShadow: const [
                  BoxShadow(
                    color: VoetjeColors.shadowLight,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              padding: const EdgeInsets.all(VoetjeSpacing.cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _useGasCost
                        ? _buildInput(
                            controller: _gasCostCtrl,
                            labelText: currencyLabel,
                          )
                        : _buildInput(
                            controller: _gasKwhCtrl,
                            labelText: 'kWh used',
                          ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() => _useGasCost = !_useGasCost),
                    child: Text(
                      _useGasCost ? 'Use kWh' : 'Use cost',
                      style: VoetjeTypography.caption().copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VoetjeColors.primaryMediumOf(context),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          VoetjeButton(label: 'Save Bill', onPressed: _save),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextField(
      controller: controller,
      style: VoetjeTypography.body(),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: VoetjeTypography.caption().copyWith(
              fontSize: 13,
              color: VoetjeColors.textMutedOf(context),
            ),
        filled: true,
        fillColor: VoetjeColors.surfaceOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          borderSide:
              BorderSide(color: VoetjeColors.borderOf(context), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          borderSide:
              BorderSide(color: VoetjeColors.borderOf(context), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          borderSide: BorderSide(
              color: VoetjeColors.primaryMediumOf(context), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
    );
  }

  Future<void> _pickMonth() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _MonthPickerDialog(
        initialMonth: _billingMonth,
        onConfirm: (month) => setState(() => _billingMonth = month),
      ),
    );
  }

  void _showKwhHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finding kWh on your bill',
              style: VoetjeTypography.sectionHeader(),
            ),
            const SizedBox(height: 8),
            Text(
              'Look for one of these on your bill:\n'
              '\u2022 "Units used: 350 kWh"\n'
              '\u2022 "Consumption: 350"\n'
              '\u2022 "kWh this period: 350"\n\n'
              "It's usually near the middle of your bill.\n\n"
              "Can't find it? Enter your total cost instead \u2014 we'll estimate.",
              style: VoetjeTypography.body(),
            ),
            const SizedBox(height: 12),
            VoetjeButton(
              label: 'Got it',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final void Function(DateTime) onConfirm;

  const _MonthPickerDialog(
      {required this.initialMonth, required this.onConfirm});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
  }

  void _shift(int months) {
    final newMonth = DateTime(_month.year, _month.month + months);
    final now = DateTime.now();
    // Don't go beyond current month
    if (newMonth.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent =
        _month.year == now.year && _month.month == now.month;

    return AlertDialog(
      title: const Text('Select billing month'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Text(
                '${_month.year}/${_month.month.toString().padLeft(2, '0')}',
                style: VoetjeTypography.pageQuestion().copyWith(fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          if (isCurrent)
            Text(
              'Current month',
              style: VoetjeTypography.caption().copyWith(
                    fontSize: 12,
                    color: VoetjeColors.textMutedOf(context),
                  ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_month);
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
