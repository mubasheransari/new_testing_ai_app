import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Bloc/global_bloc.dart';
import '../../Repository/bmi_repository.dart';

const _hint = Color(0xFF8E8E93);

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});
  @override
  State<BmiPage> createState() => _BmiPageState();
}

enum HeightUnit { cm, ftin }

enum WeightUnit { kg, lb }

class _BmiPageState extends State<BmiPage> {
  // THEME
  static const _accent = Color(0xFFFF7A3D);
  static const _header = Color(0xFFFF9156);

  // STATE
  bool _isMale = true;
  HeightUnit _hUnit = HeightUnit.cm;
  WeightUnit _wUnit = WeightUnit.kg;

  // Controllers (no hardcoded defaults)
  final _ageCtrl = TextEditingController();
  final _cmCtrl = TextEditingController();
  final _ftCtrl = TextEditingController();
  final _inCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  final _lbCtrl = TextEditingController();

  // Local result (overrides API once calculated)
  double? _bmi;
  String? _category;
  Color _catColor = Colors.transparent;

  // API result (shown until local result exists)
  double? _apiBmi;
  String? _apiCategory;
  Color _apiCatColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    // No local persistence. Directly seed from BLoC.
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromBloc());
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _cmCtrl.dispose();
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _kgCtrl.dispose();
    _lbCtrl.dispose();
    super.dispose();
  }

  // ---------- Seed from GlobalBloc (API values) ----------
  void _seedFromBloc() {
    final state = context.read<GlobalBloc>().state;
    final apiItem = state.loginModel?.bmi.last;
    if (apiItem == null) return;

    // Try to read API BMI number
    final apiBmiVal = _toDoubleOrNull(apiItem.bmi?.toString());
    if (apiBmiVal != null && apiBmiVal > 0) {
      _apiBmi = double.parse(apiBmiVal.toStringAsFixed(1));
      _apiCategory = _categoryFor(_apiBmi!);
      _apiCatColor = _colorForBmi(_apiBmi!);
    }

    // AGE
    _maybeSet(_ageCtrl, _digitsOrNull(apiItem.age?.toString()));

    // GENDER — if your model contains gender, wire it here; default 'male'
    final g = 'male';
    if (g.isNotEmpty) {
      _isMale = g.trim().toLowerCase().startsWith('m');
    }

    // HEIGHT — prefer ft/in, then cm, then raw number
    final feetStr = _digitsOrNull(apiItem.ft?.toString());
    final inchStr = _digitsOrNull(apiItem.inches?.toString());
    final cmStr = _digitsOrNull(apiItem.height?.toString());
    final anyHeight = apiItem.height?.toString();

    if ((feetStr ?? '').isNotEmpty || (inchStr ?? '').isNotEmpty) {
      _applyHeightFromFeetInches(feetStr, inchStr);
    } else if ((cmStr ?? '').isNotEmpty) {
      _applyHeightFromCm(cmStr!);
    } else if (anyHeight != null && anyHeight.trim().isNotEmpty) {
      _applyHeight(anyHeight);
    }

    // WEIGHT — try explicit then raw
    final kgStr = _digitsOrNull(apiItem.weight?.toString());
    final lbStr =
        _digitsOrNull(apiItem.weight?.toString()); // if you had lb separately
    final anyWeight = apiItem.weight?.toString();

    if ((kgStr ?? '').isNotEmpty) {
      _applyWeight('${kgStr}kg');
    } else if ((lbStr ?? '').isNotEmpty) {
      _applyWeight('${lbStr}lb');
    } else if (anyWeight != null && anyWeight.trim().isNotEmpty) {
      _applyWeight(anyWeight);
    }

    setState(() {});
  }

  // ---------- Helpers ----------
  void _maybeSet(TextEditingController c, String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return;
    if (c.text.trim().isEmpty) c.text = t;
  }

  String? _digitsOrNull(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(',', '.');
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    return m?.group(1);
  }

  double? _toDoubleOrNull(String? s) {
    if (s == null) return null;
    return double.tryParse(s.trim());
  }

  String _categoryFor(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _colorForBmi(double bmi) => _colorForCategory(_categoryFor(bmi));

  Color _colorForCategory(String? cat) {
    switch (cat) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  // ---------- HEIGHT APPLY ----------
  void _applyHeightFromFeetInches(String? feet, String? inches) {
    final ft = double.tryParse(feet ?? '') ?? 0;
    final inVal = double.tryParse(inches ?? '') ?? 0;
    if (ft <= 0 && inVal <= 0) return;

    _hUnit = HeightUnit.ftin;

    final totalIn = ft * 12 + inVal;
    final normFt = totalIn ~/ 12;
    final normIn = totalIn - normFt * 12;

    _maybeSet(_ftCtrl, normFt.toStringAsFixed(0));
    _maybeSet(
        _inCtrl,
        (normIn % 1 == 0)
            ? normIn.toStringAsFixed(0)
            : normIn.toStringAsFixed(1));

    _syncHeightTo(HeightUnit.ftin); // back-fill cm
    setState(() {});
  }

  void _applyHeightFromCm(String cmStr) {
    final cm = double.tryParse(cmStr) ?? 0;
    if (cm <= 0) return;
    _hUnit = HeightUnit.cm;
    _maybeSet(_cmCtrl, cm.toStringAsFixed(0));
    _syncHeightTo(HeightUnit.cm); // back-fill ft/in
    setState(() {});
  }

  /// Accepts "170", "170cm", "5ft7in", `5'7"`, etc.
  void _applyHeight(String raw) {
    final s = raw.toLowerCase();

    final ftIn =
        RegExp(r'''^(\d+)\s*(?:ft|')\s*(\d+(?:\.\d+)?)?\s*(?:in|")?$''')
            .firstMatch(s);
    if (ftIn != null) {
      final ft = ftIn.group(1);
      final inches = ftIn.group(2) ?? '0';
      _applyHeightFromFeetInches(ft, inches);
      return;
    }

    final cmStr = _digitsOrNull(s);
    if (cmStr != null) _applyHeightFromCm(cmStr);
  }

  // ---------- WEIGHT APPLY ----------
  /// Accepts "55", "55kg", "121lb"
  void _applyWeight(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '');
    final numStr = _digitsOrNull(s);
    if (numStr == null) return;

    final val = double.tryParse(numStr) ?? 0;
    if (val <= 0) return;

    if (s.contains('lb')) {
      _wUnit = WeightUnit.lb;
      _maybeSet(_lbCtrl,
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1));
      _syncWeightTo(WeightUnit.lb); // back-fill kg
    } else {
      _wUnit = WeightUnit.kg;
      _maybeSet(_kgCtrl,
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1));
      _syncWeightTo(WeightUnit.kg); // back-fill lb
    }
    setState(() {});
  }

  // ---------- PERSISTENCE (disabled: keep signatures so UI code unchanged) ----------
  Future<void> _loadPrefs() async {/* no-op */}

  // ---------- CONVERSIONS ----------
  double _cmFromCurrent() {
    if (_hUnit == HeightUnit.cm) {
      return double.tryParse(_cmCtrl.text.trim()) ?? 0;
    }
    final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
    final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
    final totalIn = (ft * 12) + inches;
    return totalIn * 2.54;
  }

  double _kgFromCurrent() {
    if (_wUnit == WeightUnit.kg) {
      return double.tryParse(_kgCtrl.text.trim()) ?? 0;
    }
    final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
    return lb * 0.45359237;
  }

  void _syncHeightTo(HeightUnit to) {
    final cm = _cmFromCurrent();
    if (cm <= 0) return;
    final safeCm = cm.clamp(30, 272);
    if (to == HeightUnit.cm) {
      _cmCtrl.text = safeCm.toStringAsFixed(0);
    } else {
      final totalIn = safeCm / 2.54;
      final ft = totalIn ~/ 12;
      final inches = totalIn - ft * 12;
      _ftCtrl.text = ft.toStringAsFixed(0);
      _inCtrl.text = inches.toStringAsFixed(1);
    }
  }

  void _syncWeightTo(WeightUnit to) {
    final kg = _kgFromCurrent();
    if (kg <= 0) return;
    final safeKg = kg.clamp(10, 350);
    if (to == WeightUnit.kg) {
      _kgCtrl.text = (safeKg % 1 == 0)
          ? safeKg.toStringAsFixed(0)
          : safeKg.toStringAsFixed(1);
    } else {
      final lb = safeKg / 0.45359237;
      _lbCtrl.text =
          (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    }
  }

  // ---------- CALC (only updates when button pressed) ----------
  void _calculate() async {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final cm = _cmFromCurrent();
    final kg = _kgFromCurrent();

    if (age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age.')),
      );
      return;
    }
    if (cm <= 0 || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid height and weight.')),
      );
      return;
    }

    // Calculate BMI perfectly from inputs
    final m = cm / 100.0;
    final bmi = kg / (m * m);

    // Derive ft/in for API (even if user entered cm)
    final totalInches = cm / 2.54;
    final ft = totalInches ~/ 12;
    final inches = (totalInches - ft * 12).round(); // nearest whole inch

    final cat = _categoryFor(bmi);
    final col = _colorForBmi(bmi);

    setState(() {
      _bmi = double.parse(bmi.toStringAsFixed(1)); // show 1 decimal in UI
      _category = cat;
      _catColor = col;
    });

    // === API CALL (token from BLoC) ===
    final state = context.read<GlobalBloc>().state;
    final token = state.loginModel?.accessToken ?? '';

    try {
      final res = await BmiRepository().createBmi(
        age: age,
        height: m, // meters (e.g., 1.75)
        weight: kg, // kg
        ft: ft,
        inches: inches,
        result: bmi, // sent as string
      );

      // Terminal output already printed inside repository.
      // If you want to reflect server-confirmed BMI when local result is cleared:
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final srvBmi =
            (data['bmi'] is num) ? (data['bmi'] as num).toDouble() : null;
        if (_bmi == null && srvBmi != null) {
          setState(() {
            _apiBmi = double.parse(srvBmi.toStringAsFixed(1));
            _apiCategory = _categoryFor(_apiBmi!);
            _apiCatColor = _colorForBmi(_apiBmi!);
          });
        }
      }

      // OPTIONAL: If you want to push this new BMI into BLoC state, add your own event here.
      // context.read<GlobalBloc>().add(AddBmiFromApi(Bmi.fromJson(data)));
    } catch (e) {
      // error already printed by repo; show a mild toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _reset() {
    setState(() {
      _ageCtrl.clear();
      _cmCtrl.clear();
      _ftCtrl.clear();
      _inCtrl.clear();
      _kgCtrl.clear();
      _lbCtrl.clear();

      _bmi = null;
      _category = null;
      _catColor = Colors.transparent;
      // After reset, UI falls back to API BMI (if present).
    });
  }

  // Step helpers for numeric fields (no live recalc; updates only on button)
  void _step(TextEditingController c, double delta,
      {required double min,
      required double max,
      bool roundInt = false,
      double step = 1}) {
    final v = double.tryParse(c.text.trim()) ?? 0;
    final next = (v + delta * step).clamp(min, max);
    c.text = roundInt
        ? next.toStringAsFixed(0)
        : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
  }

  // ---- Render helpers for showing both units in result ----
  String _formatHeightBoth() {
    final cm = _cmFromCurrent();
    if (cm <= 0) return '--';
    final totalIn = (cm / 2.54);
    final ft = totalIn ~/ 12;
    final inches = totalIn - (ft * 12);
    final ftIn = "$ft' ${inches.toStringAsFixed(1)}\"";
    return "${cm.toStringAsFixed(0)} cm  •  $ftIn";
  }

  String _formatWeightBoth() {
    final kg = _kgFromCurrent();
    if (kg <= 0) return '--';
    final lb = kg / 0.45359237;
    final kgStr = (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    final lbStr = (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    return "$kgStr kg  •  $lbStr lb";
  }

  @override
  Widget build(BuildContext context) {
    // What to display? Prefer local result if available; otherwise show API result
    final displayedBmi = _bmi ?? _apiBmi;
    final displayedCategory = _bmi != null ? _category : _apiCategory;
    final displayedColor = _bmi != null ? _catColor : _apiCatColor;

    return Scaffold(
      body: Stack(children: [
        // Header gradient
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _header],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'BMI Calculator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // RESULT DIAL CARD
                _Card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _BmiDial(bmi: displayedBmi, color: displayedColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayedBmi == null
                                      ? 'No result'
                                      : '${displayedBmi.toStringAsFixed(1)} kg/m²',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayedBmi == null
                                      ? 'Enter your details and tap Calculate.'
                                      : (displayedCategory ?? ''),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: displayedBmi == null
                                        ? _hint
                                        : displayedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (displayedBmi != null)
                                  _HealthyRangeLine(
                                      cm: _cmFromCurrent(), wUnit: _wUnit),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (displayedBmi != null) ...[
                        const SizedBox(height: 14),
                        _BmiRangeBar(bmi: displayedBmi!),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LabelValue(
                                  label: 'Height', value: _formatHeightBoth()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabelValue(
                                  label: 'Weight', value: _formatWeightBoth()),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // INPUT CARD
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age
                      const Text('Age',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      _NumberField(
                        controller: _ageCtrl,
                        unit: 'years',
                        onStep: (d) => _step(_ageCtrl, d,
                            min: 1, max: 120, roundInt: true),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      const Text('Gender',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Choice(
                            label: 'Male',
                            selected: _isMale,
                            onTap: () {
                              setState(() => _isMale = true);
                            },
                          ),
                          const SizedBox(width: 10),
                          _Choice(
                            label: 'Female',
                            selected: !_isMale,
                            onTap: () {
                              setState(() => _isMale = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Height
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Height',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<HeightUnit>(
                              options: const {
                                HeightUnit.cm: 'cm',
                                HeightUnit.ftin: 'ft+in',
                              },
                              selected: _hUnit,
                              onChanged: (v) {
                                setState(() {
                                  _hUnit = v; // set unit FIRST
                                  _syncHeightTo(v); // then sync
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_hUnit == HeightUnit.cm)
                        _NumberField(
                          controller: _cmCtrl,
                          unit: 'cm',
                          onStep: (d) => _step(_cmCtrl, d,
                              min: 30, max: 272, roundInt: true),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _MiniNumberField(
                                label: 'ft',
                                controller: _ftCtrl,
                                onStep: (d) => _step(_ftCtrl, d,
                                    min: 1, max: 8, roundInt: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniNumberField(
                                label: 'in',
                                controller: _inCtrl,
                                onStep: (d) => _step(_inCtrl, d,
                                    min: 0, max: 11.9, step: .5),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Weight
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Weight',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<WeightUnit>(
                              options: const {
                                WeightUnit.kg: 'kg',
                                WeightUnit.lb: 'lb',
                              },
                              selected: _wUnit,
                              onChanged: (v) {
                                setState(() {
                                  _wUnit = v; // set unit FIRST
                                  _syncWeightTo(v); // then sync
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_wUnit == WeightUnit.kg)
                        _NumberField(
                          controller: _kgCtrl,
                          unit: 'kg',
                          onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
                        )
                      else
                        _NumberField(
                          controller: _lbCtrl,
                          unit: 'lb',
                          onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
                        ),

                      const SizedBox(height: 16),

                      // Buttons
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: _calculate, // ONLY here we update result
                          child: const Text('Calculate BMI',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child:
                            const Text('Reset', style: TextStyle(color: _hint)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- UI BUILDING BLOCKS (unchanged) ----------
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.male : Icons.female,
                size: 18,
                color: selected
                    ? const Color(0xFFFF7A3D)
                    : const Color(0xFFBDBDBD)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : const Color(0xFF6B6B6B))),
          ],
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const _Segmented(
      {required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: List.generate(keys.length, (i) {
          final k = keys[i];
          final isSel = k == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
                ),
                child: Text(
                  options[k]!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.black : const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final void Function(double delta) onStep;

  final String? initialValue;
  final int fractionDigits;
  final void Function(String value)? onChanged;

  const _NumberField({
    required this.controller,
    required this.unit,
    required this.onStep,
    this.initialValue,
    this.fractionDigits = 0,
    this.onChanged,
    super.key,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  @override
  void initState() {
    super.initState();
    if ((widget.controller.text).trim().isEmpty &&
        widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => widget.onStep(-1),
            splashRadius: 22,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: const TextStyle(color: _hint),
                suffixText: widget.unit,
                suffixStyle:
                    const TextStyle(color: _hint, fontWeight: FontWeight.w600),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => widget.onStep(1),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

class _MiniNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(double delta) onStep;

  const _MiniNumberField(
      {required this.label, required this.controller, required this.onStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onStep(-1),
                  splashRadius: 22),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: _hint)),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onStep(1),
                  splashRadius: 22),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BmiDial extends StatelessWidget {
  final double? bmi;
  final Color color;
  const _BmiDial({required this.bmi, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.red,
            Colors.blue
          ],
          stops: [0.0, .46, .70, .90, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: bmi == null
                ? const Text('--',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _hint))
                : Text(
                    bmi!.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color:
                            color == Colors.transparent ? Colors.black : color),
                  ),
          ),
        ),
      ),
    );
  }
}

class _HealthyRangeLine extends StatelessWidget {
  final double cm;
  final WeightUnit wUnit;
  const _HealthyRangeLine({required this.cm, required this.wUnit});

  @override
  Widget build(BuildContext context) {
    final m = cm / 100.0;
    final minKg = 18.5 * m * m;
    final maxKg = 24.9 * m * m;

    String render(double kg) {
      if (wUnit == WeightUnit.kg) return '${kg.toStringAsFixed(1)} kg';
      final lb = kg / 0.45359237;
      return '${lb.toStringAsFixed(0)} lb';
    }

    return Text(
      'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
      style: const TextStyle(fontSize: 12, color: _hint),
    );
  }
}

class _BmiRangeBar extends StatelessWidget {
  final double bmi;
  const _BmiRangeBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    const maxBmi = 40.0;
    final clamp = bmi.clamp(0, maxBmi);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final x = (clamp / maxBmi) * w;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: const [
                  _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
                  _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
                  _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
                  _RangeSegment(color: Colors.red, flex: 100), // 30–40
                ],
              ),
            ),
            Positioned(
              left: x - 8,
              child: Column(
                children: [
                  Icon(Icons.arrow_drop_down,
                      color: Colors.black.withOpacity(.65)),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black.withOpacity(.2)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _TickLabel('0'),
                    _TickLabel('18.5'),
                    _TickLabel('25'),
                    _TickLabel('30'),
                    _TickLabel('40'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RangeSegment extends StatelessWidget {
  final Color color;
  final int flex; // scale out of 399
  const _RangeSegment({required this.color, required this.flex});
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(height: 16, color: color.withOpacity(.25)));
  }
}

class _TickLabel extends StatelessWidget {
  final String text;
  const _TickLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
  }
}


/*class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

enum HeightUnit { cm, ftin }

enum WeightUnit { kg, lb }

class _BmiPageState extends State<BmiPage> {
  // THEME
  static const _accent = Color(0xFFFF7A3D);
  static const _header = Color(0xFFFF9156);

  // STATE
  bool _isMale = true;
  HeightUnit _hUnit = HeightUnit.cm;
  WeightUnit _wUnit = WeightUnit.kg;

  // Controllers (no hardcoded defaults)
  final _ageCtrl = TextEditingController();
  final _cmCtrl = TextEditingController();
  final _ftCtrl = TextEditingController();
  final _inCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  final _lbCtrl = TextEditingController();

  // Local result (overrides API once calculated)
  double? _bmi;
  String? _category;
  Color _catColor = Colors.transparent;

  // API result (shown until local result exists)
  double? _apiBmi;
  String? _apiCategory;
  Color _apiCatColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromBloc());
    });
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _cmCtrl.dispose();
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _kgCtrl.dispose();
    _lbCtrl.dispose();
    super.dispose();
  }

  // ---------- Seed from GlobalBloc (API values) ----------
  void _seedFromBloc() {
    final state = context.read<GlobalBloc>().state;
    final apiItem = state.loginModel?.bmi.last;
    if (apiItem == null) return;

    // Try to read API BMI number
    final apiBmiVal = _toDoubleOrNull(apiItem.bmi?.toString());
    if (apiBmiVal != null && apiBmiVal > 0) {
      _apiBmi = double.parse(apiBmiVal.toStringAsFixed(1));
      _apiCategory = _categoryFor(_apiBmi!);
      _apiCatColor = _colorForBmi(_apiBmi!);
    }

    // AGE
    _maybeSet(_ageCtrl, _digitsOrNull(apiItem.age?.toString()));

    // GENDER (if available)
    final g = 'male';
    //apiItem.gender?.toString().trim().toLowerCase();
    if (g != null && g.isNotEmpty) {
      _isMale = g.startsWith('m'); // "male"/"m" => true
    }

    // HEIGHT — prefer ft/in, then cm, then raw text
    final feetStr = _digitsOrNull(apiItem.ft?.toString());
    final inchStr = _digitsOrNull(apiItem.inches?.toString());
    final cmStr = _digitsOrNull(apiItem.height?.toString());
    final anyHeight = apiItem.height?.toString();

    if ((feetStr ?? '').isNotEmpty || (inchStr ?? '').isNotEmpty) {
      _applyHeightFromFeetInches(feetStr, inchStr);
    } else if ((cmStr ?? '').isNotEmpty) {
      _applyHeightFromCm(cmStr!);
    } else if (anyHeight != null && anyHeight.trim().isNotEmpty) {
      _applyHeight(anyHeight);
    }

    // WEIGHT — try explicit then raw
    final kgStr = _digitsOrNull(apiItem.weight?.toString());
    final lbStr = _digitsOrNull(
        apiItem.weight?.toString()); // if your model has lb separately
    final anyWeight = apiItem.weight?.toString();

    if ((kgStr ?? '').isNotEmpty) {
      _applyWeight('${kgStr}kg');
    } else if ((lbStr ?? '').isNotEmpty) {
      _applyWeight('${lbStr}lb');
    } else if (anyWeight != null && anyWeight.trim().isNotEmpty) {
      _applyWeight(anyWeight);
    }
    setState(() {});
    _savePrefs();
  }

  // ---------- Helpers ----------
  void _maybeSet(TextEditingController c, String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return;
    if (c.text.trim().isEmpty) c.text = t;
  }

  String? _digitsOrNull(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(',', '.');
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    return m?.group(1);
  }

  double? _toDoubleOrNull(String? s) {
    if (s == null) return null;
    return double.tryParse(s.trim());
  }

  String _categoryFor(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _colorForBmi(double bmi) => _colorForCategory(_categoryFor(bmi));

  Color _colorForCategory(String? cat) {
    switch (cat) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  // ---------- HEIGHT APPLY ----------
  void _applyHeightFromFeetInches(String? feet, String? inches) {
    final ft = double.tryParse(feet ?? '') ?? 0;
    final inVal = double.tryParse(inches ?? '') ?? 0;
    if (ft <= 0 && inVal <= 0) return;

    _hUnit = HeightUnit.ftin;

    double totalIn = ft * 12 + inVal;
    final normFt = totalIn ~/ 12;
    final normIn = totalIn - normFt * 12;

    _maybeSet(_ftCtrl, normFt.toStringAsFixed(0));
    _maybeSet(
      _inCtrl,
      (normIn % 1 == 0) ? normIn.toStringAsFixed(0) : normIn.toStringAsFixed(1),
    );

    _syncHeightTo(HeightUnit.ftin); // back-fill cm
    setState(() {});
  }

  void _applyHeightFromCm(String cmStr) {
    final cm = double.tryParse(cmStr) ?? 0;
    if (cm <= 0) return;
    _hUnit = HeightUnit.cm;
    _maybeSet(_cmCtrl, cm.toStringAsFixed(0));
    _syncHeightTo(HeightUnit.cm); // back-fill ft/in
    setState(() {});
  }

  /// Accepts "170", "170cm", "5ft7in", `5'7"`, etc.
  void _applyHeight(String raw) {
    final s = raw.toLowerCase();

    final ftIn =
        RegExp(r'''^(\d+)\s*(?:ft|')\s*(\d+(?:\.\d+)?)?\s*(?:in|")?$''')
            .firstMatch(s);
    if (ftIn != null) {
      final ft = ftIn.group(1);
      final inches = ftIn.group(2) ?? '0';
      _applyHeightFromFeetInches(ft, inches);
      return;
    }

    final cmStr = _digitsOrNull(s);
    if (cmStr != null) _applyHeightFromCm(cmStr);
  }

  // ---------- WEIGHT APPLY ----------
  /// Accepts "55", "55kg", "121lb"
  void _applyWeight(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '');
    final numStr = _digitsOrNull(s);
    if (numStr == null) return;

    final val = double.tryParse(numStr) ?? 0;
    if (val <= 0) return;

    if (s.contains('lb')) {
      _wUnit = WeightUnit.lb;
      _maybeSet(_lbCtrl,
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1));
      _syncWeightTo(WeightUnit.lb); // back-fill kg
    } else {
      _wUnit = WeightUnit.kg;
      _maybeSet(_kgCtrl,
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1));
      _syncWeightTo(WeightUnit.kg); // back-fill lb
    }
    setState(() {});
  }

  // ---------- PERSISTENCE ----------
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _isMale = p.getBool('bmi_isMale') ?? _isMale;
      _hUnit = HeightUnit.values[p.getInt('bmi_hUnit') ?? _hUnit.index];
      _wUnit = WeightUnit.values[p.getInt('bmi_wUnit') ?? _wUnit.index];

      _maybeSet(_ageCtrl, p.getString('bmi_age'));
      _maybeSet(_cmCtrl, p.getString('bmi_cm'));
      _maybeSet(_ftCtrl, p.getString('bmi_ft'));
      _maybeSet(_inCtrl, p.getString('bmi_in'));
      _maybeSet(_kgCtrl, p.getString('bmi_kg'));
      _maybeSet(_lbCtrl, p.getString('bmi_lb'));

      // Load previous local result if any (this will override API display)
      final savedBmi = p.getDouble('bmi_result');
      final savedCat = p.getString('bmi_category');
      if (savedBmi != null && savedBmi > 0) {
        _bmi = double.parse(savedBmi.toStringAsFixed(1));
        _category = savedCat ?? _categoryFor(_bmi!);
        _catColor = _colorForCategory(_category);
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('bmi_isMale', _isMale);
    await p.setInt('bmi_hUnit', _hUnit.index);
    await p.setInt('bmi_wUnit', _wUnit.index);

    await p.setString('bmi_age', _ageCtrl.text.trim());
    await p.setString('bmi_cm', _cmCtrl.text.trim());
    await p.setString('bmi_ft', _ftCtrl.text.trim());
    await p.setString('bmi_in', _inCtrl.text.trim());
    await p.setString('bmi_kg', _kgCtrl.text.trim());
    await p.setString('bmi_lb', _lbCtrl.text.trim());

    if (_bmi != null) {
      await p.setDouble('bmi_result', _bmi!);
      await p.setString('bmi_category', _category ?? _categoryFor(_bmi!));
    } else {
      await p.remove('bmi_result');
      await p.remove('bmi_category');
    }
  }

  // ---------- CONVERSIONS ----------
  double _cmFromCurrent() {
    if (_hUnit == HeightUnit.cm) {
      return double.tryParse(_cmCtrl.text.trim()) ?? 0;
    }
    final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
    final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
    final totalIn = (ft * 12) + inches;
    return totalIn * 2.54;
  }

  double _kgFromCurrent() {
    if (_wUnit == WeightUnit.kg) {
      return double.tryParse(_kgCtrl.text.trim()) ?? 0;
    }
    final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
    return lb * 0.45359237;
  }

  void _syncHeightTo(HeightUnit to) {
    final cm = _cmFromCurrent();
    if (cm <= 0) return;
    final safeCm = cm.clamp(30, 272);
    if (to == HeightUnit.cm) {
      _cmCtrl.text = safeCm.toStringAsFixed(0);
    } else {
      final totalIn = safeCm / 2.54;
      final ft = totalIn ~/ 12;
      final inches = totalIn - ft * 12;
      _ftCtrl.text = ft.toStringAsFixed(0);
      _inCtrl.text = inches.toStringAsFixed(1);
    }
    _savePrefs();
  }

  void _syncWeightTo(WeightUnit to) {
    final kg = _kgFromCurrent();
    if (kg <= 0) return;
    final safeKg = kg.clamp(10, 350);
    if (to == WeightUnit.kg) {
      _kgCtrl.text = (safeKg % 1 == 0)
          ? safeKg.toStringAsFixed(0)
          : safeKg.toStringAsFixed(1);
    } else {
      final lb = safeKg / 0.45359237;
      _lbCtrl.text =
          (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    }
    _savePrefs();
  }

  // ---------- CALC (only updates when button pressed) ----------
  void _calculate() async {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final cm = _cmFromCurrent();
    final kg = _kgFromCurrent();

    if (age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age.')),
      );
      return;
    }
    if (cm <= 0 || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid height and weight.')),
      );
      return;
    }

    final m = cm / 100.0;
    final bmi = kg / (m * m);

    final cat = _categoryFor(bmi);
    final col = _colorForBmi(bmi);

    setState(() {
      _bmi = double.parse(bmi.toStringAsFixed(1));
      _category = cat;
      _catColor = col;
      // Local BMI now overrides any API BMI in the UI.
    });
    await BmiRepository().createBmi(
      age: int.parse(_ageCtrl.text.trim()),
      height: 1.75,
      weight: 88,
      ft: 5,
      inches: 11,
      result: 35, // will be sent as "35"
    );

    _savePrefs();
  }

  void _reset() {
    setState(() {
      _ageCtrl.clear();
      _cmCtrl.clear();
      _ftCtrl.clear();
      _inCtrl.clear();
      _kgCtrl.clear();
      _lbCtrl.clear();

      _bmi = null;
      _category = null;
      _catColor = Colors.transparent;
      // After reset, UI falls back to API BMI (if present).
    });
    _savePrefs();
  }

  // Step helpers for numeric fields (no live recalc; updates only on button)
  void _step(TextEditingController c, double delta,
      {required double min,
      required double max,
      bool roundInt = false,
      double step = 1}) {
    final v = double.tryParse(c.text.trim()) ?? 0;
    final next = (v + delta * step).clamp(min, max);
    c.text = roundInt
        ? next.toStringAsFixed(0)
        : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
    _savePrefs();
  }

  // ---- Render helpers for showing both units in result ----
  String _formatHeightBoth() {
    final cm = _cmFromCurrent();
    if (cm <= 0) return '--';
    final totalIn = (cm / 2.54);
    final ft = totalIn ~/ 12;
    final inches = totalIn - (ft * 12);
    final ftIn = "$ft' ${inches.toStringAsFixed(1)}\"";
    return "${cm.toStringAsFixed(0)} cm  •  $ftIn";
  }

  String _formatWeightBoth() {
    final kg = _kgFromCurrent();
    if (kg <= 0) return '--';
    final lb = kg / 0.45359237;
    final kgStr = (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    final lbStr = (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    return "$kgStr kg  •  $lbStr lb";
  }

  @override
  Widget build(BuildContext context) {
    // What to display? Prefer local result if available; otherwise show API result
    final displayedBmi = _bmi ?? _apiBmi;
    final displayedCategory = _bmi != null ? _category : _apiCategory;
    final displayedColor = _bmi != null ? _catColor : _apiCatColor;

    return Scaffold(
      body: Stack(children: [
        // Header gradient
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _header],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'BMI Calculator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // RESULT DIAL CARD
                _Card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _BmiDial(bmi: displayedBmi, color: displayedColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayedBmi == null
                                      ? 'No result'
                                      : '${displayedBmi.toStringAsFixed(1)} kg/m²',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayedBmi == null
                                      ? 'Enter your details and tap Calculate.'
                                      : (displayedCategory ?? ''),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: displayedBmi == null
                                        ? _hint
                                        : displayedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (displayedBmi != null)
                                  _HealthyRangeLine(
                                      cm: _cmFromCurrent(), wUnit: _wUnit),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (displayedBmi != null) ...[
                        const SizedBox(height: 14),
                        _BmiRangeBar(bmi: displayedBmi!),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LabelValue(
                                  label: 'Height', value: _formatHeightBoth()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabelValue(
                                  label: 'Weight', value: _formatWeightBoth()),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // INPUT CARD
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age
                      const Text('Age',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      _NumberField(
                        controller: _ageCtrl,
                        unit: 'years',
                        onStep: (d) => _step(_ageCtrl, d,
                            min: 1, max: 120, roundInt: true),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      const Text('Gender',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Choice(
                            label: 'Male',
                            selected: _isMale,
                            onTap: () {
                              setState(() => _isMale = true);
                              _savePrefs();
                            },
                          ),
                          const SizedBox(width: 10),
                          _Choice(
                            label: 'Female',
                            selected: !_isMale,
                            onTap: () {
                              setState(() => _isMale = false);
                              _savePrefs();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Height
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Height',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<HeightUnit>(
                              options: const {
                                HeightUnit.cm: 'cm',
                                HeightUnit.ftin: 'ft+in',
                              },
                              selected: _hUnit,
                              onChanged: (v) {
                                setState(() {
                                  _hUnit = v; // set unit FIRST
                                  _syncHeightTo(v); // then sync
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_hUnit == HeightUnit.cm)
                        _NumberField(
                          controller: _cmCtrl,
                          unit: 'cm',
                          onStep: (d) => _step(_cmCtrl, d,
                              min: 30, max: 272, roundInt: true),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _MiniNumberField(
                                label: 'ft',
                                controller: _ftCtrl,
                                onStep: (d) => _step(_ftCtrl, d,
                                    min: 1, max: 8, roundInt: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniNumberField(
                                label: 'in',
                                controller: _inCtrl,
                                onStep: (d) => _step(_inCtrl, d,
                                    min: 0, max: 11.9, step: .5),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Weight
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Weight',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<WeightUnit>(
                              options: const {
                                WeightUnit.kg: 'kg',
                                WeightUnit.lb: 'lb',
                              },
                              selected: _wUnit,
                              onChanged: (v) {
                                setState(() {
                                  _wUnit = v; // set unit FIRST
                                  _syncWeightTo(v); // then sync
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_wUnit == WeightUnit.kg)
                        _NumberField(
                          controller: _kgCtrl,
                          unit: 'kg',
                          onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
                        )
                      else
                        _NumberField(
                          controller: _lbCtrl,
                          unit: 'lb',
                          onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
                        ),

                      const SizedBox(height: 16),

                      // Buttons
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: _calculate, // ONLY here we update result
                          child: const Text('Calculate BMI',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child:
                            const Text('Reset', style: TextStyle(color: _hint)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- UI BUILDING BLOCKS ----------
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.male : Icons.female,
                size: 18,
                color: selected
                    ? const Color(0xFFFF7A3D)
                    : const Color(0xFFBDBDBD)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : const Color(0xFF6B6B6B))),
          ],
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const _Segmented(
      {required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: List.generate(keys.length, (i) {
          final k = keys[i];
          final isSel = k == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
                ),
                child: Text(
                  options[k]!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.black : const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final void Function(double delta) onStep;

  final String? initialValue;
  final int fractionDigits;
  final void Function(String value)? onChanged;

  const _NumberField({
    required this.controller,
    required this.unit,
    required this.onStep,
    this.initialValue,
    this.fractionDigits = 0,
    this.onChanged,
    super.key,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  @override
  void initState() {
    super.initState();
    if ((widget.controller.text).trim().isEmpty &&
        widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => widget.onStep(-1),
            splashRadius: 22,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: const TextStyle(color: _hint),
                suffixText: widget.unit,
                suffixStyle:
                    const TextStyle(color: _hint, fontWeight: FontWeight.w600),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => widget.onStep(1),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

class _MiniNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(double delta) onStep;

  const _MiniNumberField({
    required this.label,
    required this.controller,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onStep(-1),
                  splashRadius: 22),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: _hint)),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onStep(1),
                  splashRadius: 22),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BmiDial extends StatelessWidget {
  final double? bmi;
  final Color color;
  const _BmiDial({required this.bmi, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.red,
            Colors.blue
          ],
          stops: [0.0, .46, .70, .90, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: bmi == null
                ? const Text('--',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _hint))
                : Text(
                    bmi!.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color:
                            color == Colors.transparent ? Colors.black : color),
                  ),
          ),
        ),
      ),
    );
  }
}

class _HealthyRangeLine extends StatelessWidget {
  final double cm;
  final WeightUnit wUnit;
  const _HealthyRangeLine({required this.cm, required this.wUnit});

  @override
  Widget build(BuildContext context) {
    final m = cm / 100.0;
    final minKg = 18.5 * m * m;
    final maxKg = 24.9 * m * m;

    String render(double kg) {
      if (wUnit == WeightUnit.kg) return '${kg.toStringAsFixed(1)} kg';
      final lb = kg / 0.45359237;
      return '${lb.toStringAsFixed(0)} lb';
    }

    return Text(
      'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
      style: const TextStyle(fontSize: 12, color: _hint),
    );
  }
}

class _BmiRangeBar extends StatelessWidget {
  final double bmi;
  const _BmiRangeBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    const maxBmi = 40.0;
    final clamp = bmi.clamp(0, maxBmi);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final x = (clamp / maxBmi) * w;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: const [
                  _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
                  _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
                  _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
                  _RangeSegment(color: Colors.red, flex: 100), // 30–40
                ],
              ),
            ),
            Positioned(
              left: x - 8,
              child: Column(
                children: [
                  Icon(Icons.arrow_drop_down,
                      color: Colors.black.withOpacity(.65)),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black.withOpacity(.2)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _TickLabel('0'),
                    _TickLabel('18.5'),
                    _TickLabel('25'),
                    _TickLabel('30'),
                    _TickLabel('40'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RangeSegment extends StatelessWidget {
  final Color color;
  final int flex; // scale out of 399
  const _RangeSegment({required this.color, required this.flex});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 16,
        color: color.withOpacity(.25),
      ),
    );
  }
}

class _TickLabel extends StatelessWidget {
  final String text;
  const _TickLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
  }
}*/


/// Shared hint color used across widgets
/*const _hint = Color(0xFF8E8E93);

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

enum HeightUnit { cm, ftin }

enum WeightUnit { kg, lb }

class _BmiPageState extends State<BmiPage> {
  // THEME
  static const _accent = Color(0xFFFF7A3D);
  static const _header = Color(0xFFFF9156);

  // STATE
  bool _isMale = true;
  HeightUnit _hUnit = HeightUnit.cm;
  WeightUnit _wUnit = WeightUnit.kg;

  // Controllers (both unit sets to allow seamless toggles)
  final _ageCtrl = TextEditingController();

  final _cmCtrl = TextEditingController();
  final _ftCtrl = TextEditingController();
  final _inCtrl = TextEditingController(); // ~170 cm

  final _kgCtrl = TextEditingController();
  final _lbCtrl = TextEditingController(); // ~55 kg

  // Result
  double? _bmi;
  String? _category;
  Color _catColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // Seed from GlobalBloc after first frame (context ready)
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromBloc());
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _cmCtrl.dispose();
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _kgCtrl.dispose();
    _lbCtrl.dispose();
    super.dispose();
  }

  // -------- SEED FROM GlobalBloc (Strings) --------

  void _seedFromBloc() {
    final bmi = context.read<GlobalBloc>().state.loginModel?.bmi.last;
    if (bmi == null) return;

    // AGE
    final ageStr = _digitsOrNull(bmi.age?.toString());
    if (ageStr != null && ageStr.isNotEmpty) {
      _ageCtrl.text = ageStr;
    }

    // GENDER //bmi.gender ??
    final g = ('Male').toString().trim().toLowerCase();
    if (g.isNotEmpty) {
      _isMale = g.startsWith('m'); // "male"/"m" => true; others => false
    }

    // HEIGHT — prefer separate ft/in if present
    final feetStr = _digitsOrNull(bmi.ft?.toString());
    final inchStr = _digitsOrNull(bmi.inches?.toString());
    final cmStr = _digitsOrNull(bmi.height?.toString());
    final anyHeight = (bmi.height?.toString());

    if (feetStr != null || inchStr != null) {
      _applyHeightFromFeetInches(feetStr, inchStr);
    } else if (cmStr != null) {
      _applyHeightFromCm(cmStr);
    } else if (anyHeight != null && anyHeight.trim().isNotEmpty) {
      _applyHeight(anyHeight);
    }

    // WEIGHT — prefer explicit kg/lb fields
    final kgStr = _digitsOrNull(bmi.weight?.toString());
    final lbStr = _digitsOrNull(bmi.weight?.toString());
    final anyWeight = (bmi.weight?.toString());

    if (kgStr != null) {
      _applyWeight(kgStr + 'kg');
    } else if (lbStr != null) {
      _applyWeight(lbStr + 'lb');
    } else if (anyWeight != null && anyWeight.trim().isNotEmpty) {
      _applyWeight(anyWeight);
    }

    setState(() {});
    _savePrefs();
  }

  /// Extract "123" or "123.4" from any string
  String? _digitsOrNull(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(',', '.');
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    return m?.group(1);
  }

  /// Set from separate feet & inches (strings like "5" and "7" or nulls)
  void _applyHeightFromFeetInches(String? feet, String? inches) {
    final ft = double.tryParse(feet ?? '0') ?? 0;
    final inVal = double.tryParse(inches ?? '0') ?? 0;
    if (ft <= 0 && inVal <= 0) return;

    _hUnit = HeightUnit.ftin;
    _ftCtrl.text = ft.toStringAsFixed(0);

    // normalize inches into 0–11.9 range if someone passes 15, etc.
    double totalIn = ft * 12 + inVal;
    final normFt = totalIn ~/ 12;
    final normIn = totalIn - normFt * 12;

    _ftCtrl.text = normFt.toStringAsFixed(0);
    _inCtrl.text = (normIn % 1 == 0)
        ? normIn.toStringAsFixed(0)
        : normIn.toStringAsFixed(1);

    _syncHeightTo(HeightUnit.ftin); // back-fill cm
  }

  /// Set from cm number-string
  void _applyHeightFromCm(String cmStr) {
    final cm = double.tryParse(cmStr) ?? 0;
    if (cm <= 0) return;
    _hUnit = HeightUnit.cm;
    _cmCtrl.text = cm.toStringAsFixed(0);
    _syncHeightTo(HeightUnit.cm); // back-fill ft/in
  }

  /// Accepts "170", "170cm", "5ft7in", `5'7"`, etc.
  void _applyHeight(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '');

    // ft + in patterns
    final ftIn =
        RegExp(r'''^(\d+)\s*(?:ft|')\s*(\d+(?:\.\d+)?)?\s*(?:in|")?$''')
            .firstMatch(s);

    if (ftIn != null) {
      final ft = double.parse(ftIn.group(1)!);
      final inches = double.parse((ftIn.group(2) ?? '0'));
      _applyHeightFromFeetInches(ft.toString(), inches.toString());
      return;
    }

    // treat as cm
    final cmStr = _digitsOrNull(s);
    if (cmStr != null) {
      _applyHeightFromCm(cmStr);
    }
  }

  /// Accepts "55", "55kg", "121lb"
  void _applyWeight(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '');
    final numStr = _digitsOrNull(s);
    if (numStr == null) return;

    final val = double.tryParse(numStr) ?? 0;
    if (val <= 0) return;

    if (s.contains('lb')) {
      _wUnit = WeightUnit.lb;
      _lbCtrl.text =
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1);
      _syncWeightTo(WeightUnit.lb); // back-fill kg
    } else {
      _wUnit = WeightUnit.kg;
      _kgCtrl.text =
          (val % 1 == 0) ? val.toStringAsFixed(0) : val.toStringAsFixed(1);
      _syncWeightTo(WeightUnit.kg); // back-fill lb
    }
  }

  // -------- PERSISTENCE --------

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _isMale = p.getBool('bmi_isMale') ?? _isMale;
      _hUnit = HeightUnit.values[p.getInt('bmi_hUnit') ?? _hUnit.index];
      _wUnit = WeightUnit.values[p.getInt('bmi_wUnit') ?? _wUnit.index];

      _ageCtrl.text = p.getString('bmi_age') ?? _ageCtrl.text;
      _cmCtrl.text = p.getString('bmi_cm') ?? _cmCtrl.text;
      _ftCtrl.text = p.getString('bmi_ft') ?? _ftCtrl.text;
      _inCtrl.text = p.getString('bmi_in') ?? _inCtrl.text;
      _kgCtrl.text = p.getString('bmi_kg') ?? _kgCtrl.text;
      _lbCtrl.text = p.getString('bmi_lb') ?? _lbCtrl.text;

      final savedBmi = p.getDouble('bmi_result');
      final savedCat = p.getString('bmi_category');
      if (savedBmi != null && savedBmi > 0) {
        _bmi = double.parse(savedBmi.toStringAsFixed(1));
        _category = savedCat;
        _catColor = _colorForCategory(savedCat);
      } else {
        _bmi = null;
        _category = null;
        _catColor = Colors.transparent;
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('bmi_isMale', _isMale);
    await p.setInt('bmi_hUnit', _hUnit.index);
    await p.setInt('bmi_wUnit', _wUnit.index);

    await p.setString('bmi_age', _ageCtrl.text.trim());
    await p.setString('bmi_cm', _cmCtrl.text.trim());
    await p.setString('bmi_ft', _ftCtrl.text.trim());
    await p.setString('bmi_in', _inCtrl.text.trim());
    await p.setString('bmi_kg', _kgCtrl.text.trim());
    await p.setString('bmi_lb', _lbCtrl.text.trim());

    if (_bmi != null) {
      await p.setDouble('bmi_result', _bmi!);
      await p.setString('bmi_category', _category ?? '');
    } else {
      await p.remove('bmi_result');
      await p.remove('bmi_category');
    }
  }

  Color _colorForCategory(String? cat) {
    switch (cat) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  // --- CONVERSIONS ---
  double _cmFromCurrent() {
    if (_hUnit == HeightUnit.cm) {
      return double.tryParse(_cmCtrl.text.trim()) ?? 0;
    }
    final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
    final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
    final totalIn = (ft * 12) + inches;
    return totalIn * 2.54;
  }

  double _kgFromCurrent() {
    if (_wUnit == WeightUnit.kg) {
      return double.tryParse(_kgCtrl.text.trim()) ?? 0;
    }
    final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
    return lb * 0.45359237;
  }

  void _syncHeightTo(HeightUnit to) {
    final cm = _cmFromCurrent().clamp(30, 272); // safe range
    if (to == HeightUnit.cm) {
      _cmCtrl.text = cm.toStringAsFixed(0);
    } else {
      final totalIn = cm / 2.54;
      final ft = totalIn ~/ 12;
      final inches = totalIn - ft * 12;
      _ftCtrl.text = ft.toStringAsFixed(0);
      _inCtrl.text = inches.toStringAsFixed(1);
    }
    _savePrefs();
  }

  void _syncWeightTo(WeightUnit to) {
    final kg = _kgFromCurrent().clamp(10, 350);
    if (to == WeightUnit.kg) {
      _kgCtrl.text =
          (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    } else {
      final lb = kg / 0.45359237;
      _lbCtrl.text =
          (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    }
    _savePrefs();
  }

  // --- CALC ---
  void _calculate() {
    // Age is stored but not used by BMI formula
    final cm = _cmFromCurrent();
    final kg = _kgFromCurrent();
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    if (age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age.')),
      );
      return;
    }
    if (cm <= 0 || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid height and weight.')),
      );
      return;
    }

    final m = cm / 100.0;
    final bmi = kg / (m * m);

    String cat;
    Color col;
    if (bmi < 18.5) {
      cat = 'Underweight';
      col = Colors.blue;
    } else if (bmi < 25) {
      cat = 'Normal';
      col = Colors.green;
    } else if (bmi < 30) {
      cat = 'Overweight';
      col = Colors.orange;
    } else {
      cat = 'Obese';
      col = Colors.red;
    }

    setState(() {
      _bmi = double.parse(bmi.toStringAsFixed(1));
      _category = cat;
      _catColor = col;
    });

    _savePrefs();
  }

  void _reset() {
    setState(() {
      _isMale = true;
      _hUnit = HeightUnit.cm;
      _wUnit = WeightUnit.kg;

      _ageCtrl.text = '25';

      _cmCtrl.text = '170';
      _ftCtrl.text = '5';
      _inCtrl.text = '7';

      _kgCtrl.text = '55';
      _lbCtrl.text = '121';

      _bmi = null;
      _category = null;
      _catColor = Colors.transparent;
    });
    _savePrefs();
  }

  // Step helpers for numeric fields
  void _step(TextEditingController c, double delta,
      {required double min,
      required double max,
      bool roundInt = false,
      double step = 1}) {
    final v = double.tryParse(c.text.trim()) ?? 0;
    final next = (v + delta * step).clamp(min, max);
    c.text = roundInt
        ? next.toStringAsFixed(0)
        : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
    if (_bmi != null) _calculate(); // live recalc if result already shown
    _savePrefs();
  }

  // ---- Render helpers for showing both units in result ----
  String _formatHeightBoth() {
    final cm = _cmFromCurrent();
    if (cm <= 0) return '--';
    final totalIn = (cm / 2.54);
    final ft = totalIn ~/ 12;
    final inches = totalIn - (ft * 12);
    final ftIn = "$ft' ${inches.toStringAsFixed(1)}\"";
    return "${cm.toStringAsFixed(0)} cm  •  $ftIn";
  }

  String _formatWeightBoth() {
    final kg = _kgFromCurrent();
    if (kg <= 0) return '--';
    final lb = kg / 0.45359237;
    final kgStr = (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
    final lbStr = (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
    return "$kgStr kg  •  $lbStr lb";
  }

  @override
  Widget build(BuildContext context) {
    double? bmi = double.tryParse(
        context.read<GlobalBloc>().state.loginModel!.bmi.last.bmi.toString());
    return Scaffold(
      body: Stack(children: [
        // Header gradient
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _header],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'BMI Calculator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // RESULT DIAL CARD
                _Card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    children: [
                      Row(
                        //double.parse(context.read<GlobalBloc>().state.loginModel!.bmi.last.result.toString())
                        children: [
                          _BmiDial(bmi: bmi, color: _catColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bmi == null
                                      ? 'No result'
                                      : '${bmi.toStringAsFixed(1)} kg/m²',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  bmi == null
                                      ? 'Enter your details and tap Calculate.'
                                      : (_category ?? ''),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: bmi == null ? _hint : _catColor,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                if (bmi != null)
                                  _HealthyRangeLine(
                                      cm: _cmFromCurrent(), wUnit: _wUnit),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 14),
                        _BmiRangeBar(bmi: bmi),
                        const SizedBox(height: 12),
                        // Height & Weight display (both units)
                        Row(
                          children: [
                            Expanded(
                              child: _LabelValue(
                                  label: 'Height', value: _formatHeightBoth()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabelValue(
                                  label: 'Weight', value: _formatWeightBoth()),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age
                      const Text('Age',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      _NumberField(
                        initialValue: '25',
                        controller: _ageCtrl,
                        unit: 'years',
                        onStep: (d) => _step(_ageCtrl, d,
                            min: 1, max: 120, roundInt: true),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      const Text('Gender',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Choice(
                            label: 'Male',
                            selected: _isMale,
                            onTap: () {
                              setState(() => _isMale = true);
                              _savePrefs();
                            },
                          ),
                          const SizedBox(width: 10),
                          _Choice(
                            label: 'Female',
                            selected: !_isMale,
                            onTap: () {
                              setState(() => _isMale = false);
                              _savePrefs();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Height
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Height',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<HeightUnit>(
                              options: const {
                                HeightUnit.cm: 'cm',
                                HeightUnit.ftin: 'ft+in',
                              },
                              selected: _hUnit,
                              onChanged: (v) {
                                setState(() {
                                  _syncHeightTo(v);
                                  _hUnit = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_hUnit == HeightUnit.cm)
                        _NumberField(
                          initialValue: '170',
                          controller: _cmCtrl,
                          unit: 'cm',
                          onStep: (d) => _step(_cmCtrl, d,
                              min: 30, max: 272, roundInt: true),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _MiniNumberField(
                                label: 'ft',
                                controller: _ftCtrl,
                                onStep: (d) => _step(_ftCtrl, d,
                                    min: 1, max: 8, roundInt: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniNumberField(
                                label: 'in',
                                controller: _inCtrl,
                                onStep: (d) => _step(_inCtrl, d,
                                    min: 0, max: 11.9, step: .5),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Weight
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Weight',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: _Segmented<WeightUnit>(
                              options: const {
                                WeightUnit.kg: 'kg',
                                WeightUnit.lb: 'lb',
                              },
                              selected: _wUnit,
                              onChanged: (v) {
                                setState(() {
                                  _syncWeightTo(v);
                                  _wUnit = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_wUnit == WeightUnit.kg)
                        _NumberField(
                          initialValue: '55',
                          controller: _kgCtrl,
                          unit: 'kg',
                          onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
                        )
                      else
                        _NumberField(
                          initialValue: '121',
                          controller: _lbCtrl,
                          unit: 'lb',
                          onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
                        ),

                      const SizedBox(height: 16),

                      // Buttons
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: _calculate,
                          child: const Text('Calculate BMI',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child: Text('Reset', style: TextStyle(color: _hint)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- UI BUILDING BLOCKS ----------

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card(
      {required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.male : Icons.female,
                size: 18,
                color: selected
                    ? const Color(0xFFFF7A3D)
                    : const Color(0xFFBDBDBD)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : const Color(0xFF6B6B6B))),
          ],
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  const _Segmented(
      {required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: List.generate(keys.length, (i) {
          final k = keys[i];
          final isSel = k == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
                ),
                child: Text(
                  options[k]!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.black : const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final void Function(double delta) onStep;

  /// Optional: set once if controller.text is empty
  final String? initialValue;

  /// Optional: decimals (not used here but handy)
  final int fractionDigits;

  /// Optional: onChanged
  final void Function(String value)? onChanged;

  const _NumberField({
    required this.controller,
    required this.unit,
    required this.onStep,
    this.initialValue,
    this.fractionDigits = 0,
    this.onChanged,
    super.key,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  @override
  void initState() {
    super.initState();
    if ((widget.controller.text).trim().isEmpty &&
        widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => widget.onStep(-1),
            splashRadius: 22,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: const TextStyle(color: _hint),
                suffixText: widget.unit,
                suffixStyle:
                    const TextStyle(color: _hint, fontWeight: FontWeight.w600),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => widget.onStep(1),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

class _MiniNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(double delta) onStep;

  const _MiniNumberField({
    required this.label,
    required this.controller,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onStep(-1),
                  splashRadius: 22),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: _hint)),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onStep(1),
                  splashRadius: 22),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BmiDial extends StatelessWidget {
  final double? bmi;
  final Color color;
  const _BmiDial({required this.bmi, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.red,
            Colors.blue
          ],
          stops: [0.0, .46, .70, .90, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: bmi == null
                ? const Text('--',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _hint))
                : Text(
                    bmi!.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color:
                            color == Colors.transparent ? Colors.black : color),
                  ),
          ),
        ),
      ),
    );
  }
}

class _HealthyRangeLine extends StatelessWidget {
  final double cm;
  final WeightUnit wUnit;
  const _HealthyRangeLine({required this.cm, required this.wUnit});

  @override
  Widget build(BuildContext context) {
    final m = cm / 100.0;
    final minKg = 18.5 * m * m;
    final maxKg = 24.9 * m * m;

    String render(double kg) {
      if (wUnit == WeightUnit.kg) return '${kg.toStringAsFixed(1)} kg';
      final lb = kg / 0.45359237;
      return '${lb.toStringAsFixed(0)} lb';
    }

    return Text(
      'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
      style: const TextStyle(fontSize: 12, color: _hint),
    );
  }
}

class _BmiRangeBar extends StatelessWidget {
  final double bmi;
  const _BmiRangeBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    const maxBmi = 40.0;
    final clamp = bmi.clamp(0, maxBmi);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final x = (clamp / maxBmi) * w;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: const [
                  _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
                  _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
                  _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
                  _RangeSegment(color: Colors.red, flex: 100), // 30–40
                ],
              ),
            ),
            Positioned(
              left: x - 8,
              child: Column(
                children: [
                  Icon(Icons.arrow_drop_down,
                      color: Colors.black.withOpacity(.65)),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black.withOpacity(.2)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _TickLabel('0'),
                    _TickLabel('18.5'),
                    _TickLabel('25'),
                    _TickLabel('30'),
                    _TickLabel('40'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RangeSegment extends StatelessWidget {
  final Color color;
  final int flex; // scale out of 399
  const _RangeSegment({required this.color, required this.flex});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 16,
        color: color.withOpacity(.25),
      ),
    );
  }
}

class _TickLabel extends StatelessWidget {
  final String text;
  const _TickLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
  }
}
*/


// const _hint = Color(0xFF8E8E93);

// class BmiPage extends StatefulWidget {
//   const BmiPage({super.key});

//   @override
//   State<BmiPage> createState() => _BmiPageState();
// }

// enum HeightUnit { cm, ftin }

// enum WeightUnit { kg, lb }

// class _BmiPageState extends State<BmiPage> {
//   // THEME
//   static const _accent = Color(0xFFFF7A3D);
//   static const _header = Color(0xFFFF9156);

//   // STATE
//   bool _isMale = true;
//   HeightUnit _hUnit = HeightUnit.cm;
//   WeightUnit _wUnit = WeightUnit.kg;

//   // Controllers (keep both sets to allow seamless unit toggles)
//   final _ageCtrl = TextEditingController(text: '25');

//   final _cmCtrl = TextEditingController(text: '170');
//   final _ftCtrl = TextEditingController(text: '5');
//   final _inCtrl = TextEditingController(text: '7'); // ~170 cm

//   final _kgCtrl = TextEditingController(text: '55');
//   final _lbCtrl = TextEditingController(text: '121'); // ~55 kg

//   // Result
//   double? _bmi;
//   String? _category;
//   Color _catColor = Colors.transparent;

//   @override
//   void initState() {
//     super.initState();
//     _loadPrefs();
//   }

//   @override
//   void dispose() {
//     _ageCtrl.dispose();
//     _cmCtrl.dispose();
//     _ftCtrl.dispose();
//     _inCtrl.dispose();
//     _kgCtrl.dispose();
//     _lbCtrl.dispose();
//     super.dispose();
//   }

//   // -------- PERSISTENCE --------

//   Future<void> _loadPrefs() async {
//     final p = await SharedPreferences.getInstance();
//     setState(() {
//       _isMale = p.getBool('bmi_isMale') ?? true;
//       _hUnit = HeightUnit.values[p.getInt('bmi_hUnit') ?? 0];
//       _wUnit = WeightUnit.values[p.getInt('bmi_wUnit') ?? 0];

//       _ageCtrl.text = p.getString('bmi_age') ?? '25';
//       _cmCtrl.text = p.getString('bmi_cm') ?? '170';
//       _ftCtrl.text = p.getString('bmi_ft') ?? '5';
//       _inCtrl.text = p.getString('bmi_in') ?? '7';
//       _kgCtrl.text = p.getString('bmi_kg') ?? '55';
//       _lbCtrl.text = p.getString('bmi_lb') ?? '121';

//       final savedBmi = p.getDouble('bmi_result');
//       final savedCat = p.getString('bmi_category');
//       if (savedBmi != null && savedBmi > 0) {
//         _bmi = double.parse(savedBmi.toStringAsFixed(1));
//         _category = savedCat;
//         _catColor = _colorForCategory(savedCat);
//       } else {
//         _bmi = null;
//         _category = null;
//         _catColor = Colors.transparent;
//       }
//     });
//   }

//   Future<void> _savePrefs() async {
//     final p = await SharedPreferences.getInstance();
//     await p.setBool('bmi_isMale', _isMale);
//     await p.setInt('bmi_hUnit', _hUnit.index);
//     await p.setInt('bmi_wUnit', _wUnit.index);

//     await p.setString('bmi_age', _ageCtrl.text.trim());
//     await p.setString('bmi_cm', _cmCtrl.text.trim());
//     await p.setString('bmi_ft', _ftCtrl.text.trim());
//     await p.setString('bmi_in', _inCtrl.text.trim());
//     await p.setString('bmi_kg', _kgCtrl.text.trim());
//     await p.setString('bmi_lb', _lbCtrl.text.trim());

//     if (_bmi != null) {
//       await p.setDouble('bmi_result', _bmi!);
//       await p.setString('bmi_category', _category ?? '');
//     } else {
//       await p.remove('bmi_result');
//       await p.remove('bmi_category');
//     }
//   }

//   Color _colorForCategory(String? cat) {
//     switch (cat) {
//       case 'Underweight':
//         return Colors.blue;
//       case 'Normal':
//         return Colors.green;
//       case 'Overweight':
//         return Colors.orange;
//       case 'Obese':
//         return Colors.red;
//       default:
//         return Colors.transparent;
//     }
//   }

//   // --- CONVERSIONS ---
//   double _cmFromCurrent() {
//     if (_hUnit == HeightUnit.cm) {
//       return double.tryParse(_cmCtrl.text.trim()) ?? 0;
//     }
//     final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
//     final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
//     final totalIn = (ft * 12) + inches;
//     return totalIn * 2.54;
//   }

//   double _kgFromCurrent() {
//     if (_wUnit == WeightUnit.kg) {
//       return double.tryParse(_kgCtrl.text.trim()) ?? 0;
//     }
//     final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
//     return lb * 0.45359237;
//   }

//   void _syncHeightTo(HeightUnit to) {
//     final cm = _cmFromCurrent().clamp(30, 272); // 1ft–8ft11in safe range
//     if (to == HeightUnit.cm) {
//       _cmCtrl.text = cm.toStringAsFixed(0);
//     } else {
//       final totalIn = cm / 2.54;
//       final ft = totalIn ~/ 12;
//       final inches = totalIn - ft * 12;
//       _ftCtrl.text = ft.toStringAsFixed(0);
//       _inCtrl.text = inches.toStringAsFixed(1);
//     }
//     _savePrefs();
//   }

//   void _syncWeightTo(WeightUnit to) {
//     final kg = _kgFromCurrent().clamp(10, 350);
//     if (to == WeightUnit.kg) {
//       _kgCtrl.text =
//           (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
//     } else {
//       final lb = kg / 0.45359237;
//       _lbCtrl.text =
//           (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
//     }
//     _savePrefs();
//   }

//   // --- CALC ---
//   void _calculate() {
//     // Age is captured & stored, but BMI formula does not use age by definition.
//     final cm = _cmFromCurrent();
//     final kg = _kgFromCurrent();
//     final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
//     if (age <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter a valid age.')),
//       );
//       return;
//     }
//     if (cm <= 0 || kg <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter valid height and weight.')),
//       );
//       return;
//     }

//     final m = cm / 100.0;
//     final bmi = kg / (m * m);

//     String cat;
//     Color col;
//     if (bmi < 18.5) {
//       cat = 'Underweight';
//       col = Colors.blue;
//     } else if (bmi < 25) {
//       cat = 'Normal';
//       col = Colors.green;
//     } else if (bmi < 30) {
//       cat = 'Overweight';
//       col = Colors.orange;
//     } else {
//       cat = 'Obese';
//       col = Colors.red;
//     }

//     setState(() {
//       _bmi = double.parse(bmi.toStringAsFixed(1));
//       _category = cat;
//       _catColor = col;
//     });

//     _savePrefs(); // persist inputs + result
//   }

//   void _reset() {
//     setState(() {
//       _isMale = true;
//       _hUnit = HeightUnit.cm;
//       _wUnit = WeightUnit.kg;

//       _ageCtrl.text = '25';

//       _cmCtrl.text = '170';
//       _ftCtrl.text = '5';
//       _inCtrl.text = '7';

//       _kgCtrl.text = '55';
//       _lbCtrl.text = '121';

//       _bmi = null;
//       _category = null;
//       _catColor = Colors.transparent;
//     });
//     _savePrefs();
//   }

//   // Step helpers for numeric fields
//   void _step(TextEditingController c, double delta,
//       {required double min,
//       required double max,
//       bool roundInt = false,
//       double step = 1}) {
//     final v = double.tryParse(c.text.trim()) ?? 0;
//     final next = (v + delta * step).clamp(min, max);
//     c.text = roundInt
//         ? next.toStringAsFixed(0)
//         : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
//     if (_bmi != null) _calculate(); // live recalc if result already shown
//     _savePrefs();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(children: [
//         // Header gradient
//         Container(
//           height: 230,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [_accent, _header],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//         ),
//         SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.only(bottom: 28),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 12),
//                 const Center(
//                   child: Text(
//                     'BMI Calculator',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // RESULT DIAL CARD
//                 _Card(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           _BmiDial(bmi: _bmi, color: _catColor),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _bmi == null
//                                       ? 'No result'
//                                       : '${_bmi!.toStringAsFixed(1)} kg/m²',
//                                   style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w700),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   _bmi == null
//                                       ? 'Enter your details and tap Calculate.'
//                                       : (_category ?? ''),
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       color: _bmi == null ? _hint : _catColor,
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 if (_bmi != null)
//                                   _HealthyRangeLine(
//                                       cm: _cmFromCurrent(), wUnit: _wUnit),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (_bmi != null) ...[
//                         const SizedBox(height: 14),
//                         _BmiRangeBar(bmi: _bmi!),
//                       ],
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // INPUT CARD
//                 _Card(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Age
//                       const Text('Age',
//                           style: TextStyle(
//                               fontWeight: FontWeight.w700, fontSize: 16)),
//                       const SizedBox(height: 8),
//                       _NumberField(
//                         initialValue: '35',
//                         controller: _ageCtrl,
//                         unit: 'years',
//                         onStep: (d) => _step(_ageCtrl, d,
//                             min: 1, max: 120, roundInt: true),
//                       ),
//                       const SizedBox(height: 16),

//                       // Gender (kept for parity with profile style)
//                       const Text('Gender',
//                           style: TextStyle(
//                               fontWeight: FontWeight.w700, fontSize: 16)),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           _Choice(
//                             label: 'Male',
//                             selected: _isMale,
//                             onTap: () {
//                               setState(() => _isMale = true);
//                               _savePrefs();
//                             },
//                           ),
//                           const SizedBox(width: 10),
//                           _Choice(
//                             label: 'Female',
//                             selected: !_isMale,
//                             onTap: () {
//                               setState(() => _isMale = false);
//                               _savePrefs();
//                             },
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),

//                       // Height
//                       Row(
//                         children: [
//                           const Expanded(
//                             flex: 2,
//                             child: Text('Height',
//                                 style: TextStyle(fontWeight: FontWeight.w700)),
//                           ),
//                           Expanded(
//                             child: _Segmented<HeightUnit>(
//                               options: const {
//                                 HeightUnit.cm: 'cm',
//                                 HeightUnit.ftin: 'ft+in',
//                               },
//                               selected: _hUnit,
//                               onChanged: (v) {
//                                 setState(() {
//                                   _syncHeightTo(v);
//                                   _hUnit = v;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       if (_hUnit == HeightUnit.cm)
//                         _NumberField(
//                           initialValue: '8090',
//                           controller: _cmCtrl,
//                           unit: 'cm',
//                           onStep: (d) => _step(_cmCtrl, d,
//                               min: 30, max: 272, roundInt: true),
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _MiniNumberField(
//                                 label: 'ft',
//                                 controller: _ftCtrl,
//                                 onStep: (d) => _step(_ftCtrl, d,
//                                     min: 1, max: 8, roundInt: true),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _MiniNumberField(
//                                 label: 'in',
//                                 controller: _inCtrl,
//                                 onStep: (d) => _step(_inCtrl, d,
//                                     min: 0, max: 11.9, step: .5),
//                               ),
//                             ),
//                           ],
//                         ),

//                       const SizedBox(height: 16),

//                       // Weight
//                       Row(
//                         children: [
//                           const Expanded(
//                             flex: 2,
//                             child: Text('Weight',
//                                 style: TextStyle(fontWeight: FontWeight.w700)),
//                           ),
//                           Expanded(
//                             child: _Segmented<WeightUnit>(
//                               options: const {
//                                 WeightUnit.kg: 'kg',
//                                 WeightUnit.lb: 'lb',
//                               },
//                               selected: _wUnit,
//                               onChanged: (v) {
//                                 setState(() {
//                                   _syncWeightTo(v);
//                                   _wUnit = v;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       if (_wUnit == WeightUnit.kg)
//                         _NumberField(
//                           onChanged: (v){
                          
//                           },
//                           initialValue: '000008888',
//                           controller: _kgCtrl,
//                           unit: 'kg',
//                           onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
//                         )
//                       else
//                         _NumberField(
//                           initialValue: '112244',
//                           controller: _lbCtrl,
//                           unit: 'lb',
//                           onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
//                         ),

//                       const SizedBox(height: 16),

//                       // Buttons
//                       SizedBox(
//                         height: 52,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _accent,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14)),
//                             elevation: 0,
//                           ),
//                           onPressed: _calculate,
//                           child: const Text('Calculate BMI',
//                               style: TextStyle(fontWeight: FontWeight.w700)),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: _reset,
//                         child: Text(
//                             'Reset', //${context.read<GlobalBloc>().state.loginModel!.bmi.last.age}
//                             style: TextStyle(color: _hint)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ]),
//     );
//   }
// }

// // ---------- UI BUILDING BLOCKS ----------

// class _Card extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry padding;
//   const _Card(
//       {required this.child,
//       this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(.06),
//                 blurRadius: 14,
//                 offset: const Offset(0, 6))
//           ],
//         ),
//         padding: padding,
//         child: child,
//       ),
//     );
//   }
// }

// class _Choice extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//   const _Choice(
//       {required this.label, required this.selected, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 170),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//               color:
//                   selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(selected ? Icons.male : Icons.female,
//                 size: 18,
//                 color: selected
//                     ? const Color(0xFFFF7A3D)
//                     : const Color(0xFFBDBDBD)),
//             const SizedBox(width: 6),
//             Text(label,
//                 style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: selected ? Colors.black : const Color(0xFF6B6B6B))),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Segmented<T> extends StatelessWidget {
//   final Map<T, String> options;
//   final T selected;
//   final ValueChanged<T> onChanged;
//   const _Segmented(
//       {required this.options, required this.selected, required this.onChanged});

//   @override
//   Widget build(BuildContext context) {
//     final keys = options.keys.toList();
//     return Container(
//       height: 36,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F7),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE6E6E6)),
//       ),
//       child: Row(
//         children: List.generate(keys.length, (i) {
//           final k = keys[i];
//           final isSel = k == selected;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => onChanged(k),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 160),
//                 alignment: Alignment.center,
//                 margin: const EdgeInsets.all(3),
//                 decoration: BoxDecoration(
//                   color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                       color:
//                           isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
//                 ),
//                 child: Text(
//                   options[k]!,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: isSel ? Colors.black : const Color(0xFF6B6B6B),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// class _NumberField extends StatefulWidget {
//   final TextEditingController controller;
//   final String unit;
//   final void Function(double delta) onStep;

//   /// NEW: set an initial number once (only if controller.text is empty)
//   final String? initialValue;

//   /// OPTIONAL: format decimals (e.g., 0 → ints, 1/2 → 1 or 2 decimals)
//   final int fractionDigits;

//   /// NEW: onChanged callback (when text changes)
//   final void Function(String value)? onChanged;

//   const _NumberField({
//     required this.controller,
//     required this.unit,
//     required this.onStep,
//     required this.initialValue,
//     this.fractionDigits = 0,
//     this.onChanged,
//     super.key,
//   });

//   @override
//   State<_NumberField> createState() => _NumberFieldState();
// }

// class _NumberFieldState extends State<_NumberField> {
//   @override
//   void initState() {
//     super.initState();
//     if ((widget.controller.text).trim().isEmpty &&
//         widget.initialValue != null) {
//       final digits = widget.fractionDigits.clamp(0, 6);
//       widget.controller.text = widget.initialValue!;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 52,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F7),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE6E6E6)),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.remove_circle_outline),
//             onPressed: () => widget.onStep(-1),
//             splashRadius: 22,
//           ),
//           Expanded(
//             child: TextField(
//               controller: widget.controller,
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               textAlign: TextAlign.center,
//               decoration: InputDecoration(
//                 border: InputBorder.none,
//                 hintText: '0',
//                 hintStyle: const TextStyle(color: _hint),
//                 suffixText: widget.unit,
//                 suffixStyle:
//                     const TextStyle(color: _hint, fontWeight: FontWeight.w600),
//               ),
//               onChanged: widget.onChanged, // 👈 added callback
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.add_circle_outline),
//             onPressed: () => widget.onStep(1),
//             splashRadius: 22,
//           ),
//         ],
//       ),
//     );
//   }
// }


// // class _NumberField extends StatelessWidget {
// //   final TextEditingController controller;
// //   final String unit;
// //   final void Function(double delta) onStep;

// //   const _NumberField({
// //     required this.controller,
// //     required this.unit,
// //     required this.onStep,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: 52,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF5F5F7),
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(color: const Color(0xFFE6E6E6)),
// //       ),
// //       child: Row(
// //         children: [
// //           IconButton(
// //               icon: const Icon(Icons.remove_circle_outline),
// //               onPressed: () => onStep(-1),
// //               splashRadius: 22),
// //           Expanded(
// //             child: TextField(
// //               controller: controller,
// //               keyboardType:
// //                   const TextInputType.numberWithOptions(decimal: true),
// //               textAlign: TextAlign.center,
// //               decoration: InputDecoration(
// //                 border: InputBorder.none,
// //                 hintText: '0',
// //                 hintStyle: const TextStyle(color: _hint),
// //                 suffixText: unit,
// //                 suffixStyle:
// //                     const TextStyle(color: _hint, fontWeight: FontWeight.w600),
// //               ),
// //             ),
// //           ),
// //           IconButton(
// //               icon: const Icon(Icons.add_circle_outline),
// //               onPressed: () => onStep(1),
// //               splashRadius: 22),
// //         ],
// //       ),
// //     );
// //   }
// // }

// class _MiniNumberField extends StatelessWidget {
//   final String label;
//   final TextEditingController controller;
//   final void Function(double delta) onStep;

//   const _MiniNumberField({
//     required this.label,
//     required this.controller,
//     required this.onStep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
//         const SizedBox(height: 6),
//         Container(
//           height: 52,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF5F5F7),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: const Color(0xFFE6E6E6)),
//           ),
//           child: Row(
//             children: [
//               IconButton(
//                   icon: const Icon(Icons.remove_circle_outline),
//                   onPressed: () => onStep(-1),
//                   splashRadius: 22),
//               Expanded(
//                 child: TextField(
//                   controller: controller,
//                   keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                   textAlign: TextAlign.center,
//                   decoration: const InputDecoration(
//                       border: InputBorder.none,
//                       hintText: '0',
//                       hintStyle: TextStyle(color: _hint)),
//                 ),
//               ),
//               IconButton(
//                   icon: const Icon(Icons.add_circle_outline),
//                   onPressed: () => onStep(1),
//                   splashRadius: 22),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _BmiDial extends StatelessWidget {
//   final double? bmi;
//   final Color color;
//   const _BmiDial({required this.bmi, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 106,
//       height: 106,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: const SweepGradient(
//           colors: [
//             Colors.blue,
//             Colors.green,
//             Colors.orange,
//             Colors.red,
//             Colors.blue
//           ],
//           stops: [0.0, .46, .70, .90, 1.0],
//         ),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
//         ],
//       ),
//       child: Center(
//         child: Container(
//           width: 90,
//           height: 90,
//           decoration:
//               const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//           child: Center(
//             child: bmi == null
//                 ? const Text('--',
//                     style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: _hint))
//                 : Text(
//                     bmi!.toStringAsFixed(1),
//                     style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                         color:
//                             color == Colors.transparent ? Colors.black : color),
//                   ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _HealthyRangeLine extends StatelessWidget {
//   final double cm;
//   final WeightUnit wUnit;
//   const _HealthyRangeLine({required this.cm, required this.wUnit});

//   @override
//   Widget build(BuildContext context) {
//     final m = cm / 100.0;
//     final minKg = 18.5 * m * m;
//     final maxKg = 24.9 * m * m;

//     String render(double kg) {
//       if (wUnit == WeightUnit.kg) return '${kg.toStringAsFixed(1)} kg';
//       final lb = kg / 0.45359237;
//       return '${lb.toStringAsFixed(0)} lb';
//     }

//     return Text(
//       'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
//       style: const TextStyle(fontSize: 12, color: _hint),
//     );
//   }
// }

// class _BmiRangeBar extends StatelessWidget {
//   final double bmi;
//   const _BmiRangeBar({required this.bmi});

//   @override
//   Widget build(BuildContext context) {
//     const maxBmi = 40.0;
//     final clamp = bmi.clamp(0, maxBmi);
//     return LayoutBuilder(
//       builder: (context, c) {
//         final w = c.maxWidth;
//         final x = (clamp / maxBmi) * w;

//         return Stack(
//           alignment: Alignment.centerLeft,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Row(
//                 children: const [
//                   _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
//                   _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
//                   _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
//                   _RangeSegment(color: Colors.red, flex: 100), // 30–40
//                 ],
//               ),
//             ),
//             Positioned(
//               left: x - 8,
//               child: Column(
//                 children: [
//                   Icon(Icons.arrow_drop_down,
//                       color: Colors.black.withOpacity(.65)),
//                   Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                       border: Border.all(color: Colors.black.withOpacity(.2)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned.fill(
//               child: IgnorePointer(
//                 ignoring: true,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     _TickLabel('0'),
//                     _TickLabel('18.5'),
//                     _TickLabel('25'),
//                     _TickLabel('30'),
//                     _TickLabel('40'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _RangeSegment extends StatelessWidget {
//   final Color color;
//   final int flex; // scale out of 399
//   const _RangeSegment({required this.color, required this.flex});
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       flex: flex,
//       child: Container(
//         height: 16,
//         color: color.withOpacity(.25),
//       ),
//     );
//   }
// }

// class _TickLabel extends StatelessWidget {
//   final String text;
//   const _TickLabel(this.text);
//   @override
//   Widget build(BuildContext context) {
//     return Text(text,
//         style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
//   }
// }


// /*const _hint = Color(0xFF8E8E93);

// class BmiPage extends StatefulWidget {
//   const BmiPage({super.key});

//   @override
//   State<BmiPage> createState() => _BmiPageState();
// }

// enum HeightUnit { cm, ftin }

// enum WeightUnit { kg, lb }

// class _BmiPageState extends State<BmiPage> {
//   // THEME
//   static const _accent = Color(0xFFFF7A3D);
//   static const _header = Color(0xFFFF9156);
//   static const _hint = Color(0xFF8E8E93);

//   // STATE
//   bool _isMale = true;
//   HeightUnit _hUnit = HeightUnit.cm;
//   WeightUnit _wUnit = WeightUnit.kg;

//   // Controllers
//   final _ageCtrl = TextEditingController(text: '25');

//   final _cmCtrl = TextEditingController(text: '170');
//   final _ftCtrl = TextEditingController(text: '5');
//   final _inCtrl = TextEditingController(text: '7'); // 5'7" ≈ 170 cm

//   final _kgCtrl = TextEditingController(text: '55');
//   final _lbCtrl = TextEditingController(text: '121'); // ≈ 55 kg

//   // Result
//   double? _bmi;
//   String? _category;
//   Color _catColor = Colors.transparent;

//   @override
//   void initState() {
//     super.initState();
//     _loadPrefs();
//   }

//   @override
//   void dispose() {
//     _ageCtrl.dispose();
//     _cmCtrl.dispose();
//     _ftCtrl.dispose();
//     _inCtrl.dispose();
//     _kgCtrl.dispose();
//     _lbCtrl.dispose();
//     super.dispose();
//   }

//   // ---------- PERSISTENCE ----------
//   Future<void> _loadPrefs() async {
//     final p = await SharedPreferences.getInstance();
//     setState(() {
//       _isMale = p.getBool('bmi_isMale') ?? true;
//       _hUnit = HeightUnit.values[p.getInt('bmi_hUnit') ?? 0];
//       _wUnit = WeightUnit.values[p.getInt('bmi_wUnit') ?? 0];
//       _ageCtrl.text = p.getString('bmi_age') ?? '25';
//       _cmCtrl.text = p.getString('bmi_cm') ?? '170';
//       _ftCtrl.text = p.getString('bmi_ft') ?? '5';
//       _inCtrl.text = p.getString('bmi_in') ?? '7';
//       _kgCtrl.text = p.getString('bmi_kg') ?? '55';
//       _lbCtrl.text = p.getString('bmi_lb') ?? '121';
//     });
//   }

//   Future<void> _savePrefs() async {
//     final p = await SharedPreferences.getInstance();
//     await p.setBool('bmi_isMale', _isMale);
//     await p.setInt('bmi_hUnit', _hUnit.index);
//     await p.setInt('bmi_wUnit', _wUnit.index);
//     await p.setString('bmi_age', _ageCtrl.text.trim());
//     await p.setString('bmi_cm', _cmCtrl.text.trim());
//     await p.setString('bmi_ft', _ftCtrl.text.trim());
//     await p.setString('bmi_in', _inCtrl.text.trim());
//     await p.setString('bmi_kg', _kgCtrl.text.trim());
//     await p.setString('bmi_lb', _lbCtrl.text.trim());
//   }

//   // --- CONVERSIONS ---
//   double _cmFromCurrent() {
//     if (_hUnit == HeightUnit.cm) {
//       return double.tryParse(_cmCtrl.text.trim()) ?? 0;
//     }
//     final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
//     final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
//     final totalIn = (ft * 12) + inches;
//     return totalIn * 2.54;
//   }

//   double _kgFromCurrent() {
//     if (_wUnit == WeightUnit.kg) {
//       return double.tryParse(_kgCtrl.text.trim()) ?? 0;
//     }
//     final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
//     return lb * 0.45359237;
//   }

//   void _syncHeightTo(HeightUnit to) {
//     final cm = _cmFromCurrent().clamp(30, 272); // 1ft–8ft11in
//     if (to == HeightUnit.cm) {
//       _cmCtrl.text = cm.toStringAsFixed(0);
//     } else {
//       final totalIn = cm / 2.54;
//       final ft = totalIn ~/ 12;
//       final inches = totalIn - ft * 12;
//       _ftCtrl.text = ft.toStringAsFixed(0);
//       _inCtrl.text = inches.toStringAsFixed(1);
//     }
//     _savePrefs();
//   }

//   void _syncWeightTo(WeightUnit to) {
//     final kg = _kgFromCurrent().clamp(10, 350);
//     if (to == WeightUnit.kg) {
//       _kgCtrl.text =
//           (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
//     } else {
//       final lb = kg / 0.45359237;
//       _lbCtrl.text =
//           (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
//     }
//     _savePrefs();
//   }

//   // --- CALC ---
//   void _calculate() {
//     final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
//     final cm = _cmFromCurrent();
//     final kg = _kgFromCurrent();

//     if (age <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter a valid age.')),
//       );
//       return;
//     }
//     if (cm <= 0 || kg <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter valid height and weight.')),
//       );
//       return;
//     }

//     final m = cm / 100.0;
//     final bmi = kg / (m * m);

//     String cat;
//     Color col;
//     if (bmi < 18.5) {
//       cat = 'Underweight';
//       col = Colors.blue;
//     } else if (bmi < 25) {
//       cat = 'Normal';
//       col = Colors.green;
//     } else if (bmi < 30) {
//       cat = 'Overweight';
//       col = Colors.orange;
//     } else {
//       cat = 'Obese';
//       col = Colors.red;
//     }

//     setState(() {
//       _bmi = double.parse(bmi.toStringAsFixed(1));
//       _category = cat;
//       _catColor = col;
//     });

//     _savePrefs();
//   }

//   void _reset() {
//     setState(() {
//       _isMale = true;
//       _hUnit = HeightUnit.cm;
//       _wUnit = WeightUnit.kg;
//       _ageCtrl.text = '25';
//       _cmCtrl.text = '170';
//       _ftCtrl.text = '5';
//       _inCtrl.text = '7';
//       _kgCtrl.text = '55';
//       _lbCtrl.text = '121';
//       _bmi = null;
//       _category = null;
//       _catColor = Colors.transparent;
//     });
//     _savePrefs();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(children: [
//         // Header gradient
//         Container(
//           height: 230,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [_accent, _header],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//         ),
//         SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.only(bottom: 28),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 12),
//                 const Center(
//                   child: Text(
//                     'BMI Calculator',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // RESULT DIAL CARD
//                 _Card(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           _BmiDial(bmi: _bmi, color: _catColor),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _bmi == null
//                                       ? 'No result'
//                                       : '${_bmi!.toStringAsFixed(1)} kg/m²',
//                                   style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w700),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   _bmi == null
//                                       ? 'Enter your details and tap Calculate.'
//                                       : (_category ?? ''),
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       color: _bmi == null ? _hint : _catColor,
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 if (_bmi != null)
//                                   _HealthyRangeLine(
//                                       cm: _cmFromCurrent(), wUnit: _wUnit),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (_bmi != null) ...[
//                         const SizedBox(height: 14),
//                         _BmiRangeBar(bmi: _bmi!),
//                       ],
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // INPUT CARD
//                 _Card(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Gender
//                       const Text('Gender',
//                           style: TextStyle(
//                               fontWeight: FontWeight.w700, fontSize: 16)),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           _Choice(
//                             label: 'Male',
//                             selected: _isMale,
//                             onTap: () {
//                               setState(() => _isMale = true);
//                               _savePrefs();
//                             },
//                           ),
//                           const SizedBox(width: 10),
//                           _Choice(
//                             label: 'Female',
//                             selected: !_isMale,
//                             onTap: () {
//                               setState(() => _isMale = false);
//                               _savePrefs();
//                             },
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 16),

//                       // Age
//                       const Text('Age',
//                           style: TextStyle(
//                               fontWeight: FontWeight.w700, fontSize: 16)),
//                       const SizedBox(height: 8),
//                       _NumberField(
//                         controller: _ageCtrl,
//                         unit: 'yrs',
//                         onStep: (d) => _step(_ageCtrl, d,
//                             min: 1, max: 120, roundInt: true),
//                       ),

//                       const SizedBox(height: 16),

//                       // Height
//                       Row(
//                         children: [
//                           const Expanded(
//                             flex: 2,
//                             child: Text('Height',
//                                 style: TextStyle(fontWeight: FontWeight.w700)),
//                           ),
//                           Expanded(
//                             child: _Segmented<HeightUnit>(
//                               options: const {
//                                 HeightUnit.cm: 'cm',
//                                 HeightUnit.ftin: 'ft+in',
//                               },
//                               selected: _hUnit,
//                               onChanged: (v) {
//                                 setState(() {
//                                   _syncHeightTo(v);
//                                   _hUnit = v;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       if (_hUnit == HeightUnit.cm)
//                         _NumberField(
//                           controller: _cmCtrl,
//                           unit: 'cm',
//                           onStep: (d) => _step(_cmCtrl, d,
//                               min: 30, max: 272, roundInt: true),
//                         )
//                       else
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _MiniNumberField(
//                                 label: 'ft',
//                                 controller: _ftCtrl,
//                                 onStep: (d) => _step(_ftCtrl, d,
//                                     min: 1, max: 8, roundInt: true),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _MiniNumberField(
//                                 label: 'in',
//                                 controller: _inCtrl,
//                                 onStep: (d) => _step(_inCtrl, d,
//                                     min: 0, max: 11.9, step: .5),
//                               ),
//                             ),
//                           ],
//                         ),

//                       const SizedBox(height: 16),

//                       // Weight
//                       Row(
//                         children: [
//                           const Expanded(
//                             flex: 2,
//                             child: Text('Weight',
//                                 style: TextStyle(fontWeight: FontWeight.w700)),
//                           ),
//                           Expanded(
//                             child: _Segmented<WeightUnit>(
//                               options: const {
//                                 WeightUnit.kg: 'kg',
//                                 WeightUnit.lb: 'lb',
//                               },
//                               selected: _wUnit,
//                               onChanged: (v) {
//                                 setState(() {
//                                   _syncWeightTo(v);
//                                   _wUnit = v;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       if (_wUnit == WeightUnit.kg)
//                         _NumberField(
//                           controller: _kgCtrl,
//                           unit: 'kg',
//                           onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
//                         )
//                       else
//                         _NumberField(
//                           controller: _lbCtrl,
//                           unit: 'lb',
//                           onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
//                         ),

//                       const SizedBox(height: 16),

//                       // Buttons
//                       SizedBox(
//                         height: 52,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _accent,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14)),
//                             elevation: 0,
//                           ),
//                           onPressed: _calculate,
//                           child: const Text('Calculate BMI',
//                               style: TextStyle(fontWeight: FontWeight.w700)),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: _reset,
//                         child:
//                             const Text('Reset', style: TextStyle(color: _hint)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ]),
//     );
//   }

//   // Step helpers for numeric fields
//   void _step(TextEditingController c, double delta,
//       {required double min,
//       required double max,
//       bool roundInt = false,
//       double step = 1}) {
//     final v = double.tryParse(c.text.trim()) ?? 0;
//     final next = (v + delta * step).clamp(min, max);
//     c.text = roundInt
//         ? next.toStringAsFixed(0)
//         : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
//     if (_bmi != null) _calculate();
//     _savePrefs();
//   }
// }

// // ---------- UI BUILDING BLOCKS ----------

// class _Card extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry padding;
//   const _Card(
//       {required this.child,
//       this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(.06),
//                 blurRadius: 14,
//                 offset: const Offset(0, 6))
//           ],
//         ),
//         padding: padding,
//         child: child,
//       ),
//     );
//   }
// }

// class _Choice extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//   const _Choice(
//       {required this.label, required this.selected, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 170),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//               color:
//                   selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(selected ? Icons.male : Icons.female,
//                 size: 18,
//                 color: selected
//                     ? const Color(0xFFFF7A3D)
//                     : const Color(0xFFBDBDBD)),
//             const SizedBox(width: 6),
//             Text(label,
//                 style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: selected ? Colors.black : const Color(0xFF6B6B6B))),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Segmented<T> extends StatelessWidget {
//   final Map<T, String> options;
//   final T selected;
//   final ValueChanged<T> onChanged;
//   const _Segmented(
//       {required this.options, required this.selected, required this.onChanged});

//   @override
//   Widget build(BuildContext context) {
//     final keys = options.keys.toList();
//     return Container(
//       height: 36,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F7),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE6E6E6)),
//       ),
//       child: Row(
//         children: List.generate(keys.length, (i) {
//           final k = keys[i];
//           final isSel = k == selected;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => onChanged(k),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 160),
//                 alignment: Alignment.center,
//                 margin: const EdgeInsets.all(3),
//                 decoration: BoxDecoration(
//                   color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                       color:
//                           isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
//                 ),
//                 child: Text(
//                   options[k]!,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: isSel ? Colors.black : const Color(0xFF6B6B6B),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// class _NumberField extends StatelessWidget {
//   final TextEditingController controller;
//   final String unit;
//   final void Function(double delta) onStep;

//   const _NumberField({
//     required this.controller,
//     required this.unit,
//     required this.onStep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const hint = Color(0xFF8E8E93);
//     return Container(
//       height: 52,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F7),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE6E6E6)),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//               icon: const Icon(Icons.remove_circle_outline),
//               onPressed: () => onStep(-1),
//               splashRadius: 22),
//           Expanded(
//             child: TextField(
//               controller: controller,
//               keyboardType:
//                   const TextInputType.numberWithOptions(decimal: true),
//               textAlign: TextAlign.center,
//               decoration: InputDecoration(
//                 border: InputBorder.none,
//                 hintText: '0',
//                 hintStyle: const TextStyle(color: hint),
//                 suffixText: unit,
//                 suffixStyle:
//                     const TextStyle(color: hint, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ),
//           IconButton(
//               icon: const Icon(Icons.add_circle_outline),
//               onPressed: () => onStep(1),
//               splashRadius: 22),
//         ],
//       ),
//     );
//   }
// }

// class _MiniNumberField extends StatelessWidget {
//   final String label;
//   final TextEditingController controller;
//   final void Function(double delta) onStep;

//   const _MiniNumberField({
//     required this.label,
//     required this.controller,
//     required this.onStep,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const hint = Color(0xFF8E8E93);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
//         const SizedBox(height: 6),
//         Container(
//           height: 52,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF5F5F7),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: const Color(0xFFE6E6E6)),
//           ),
//           child: Row(
//             children: [
//               IconButton(
//                   icon: const Icon(Icons.remove_circle_outline),
//                   onPressed: () => onStep(-1),
//                   splashRadius: 22),
//               Expanded(
//                 child: TextField(
//                   controller: controller,
//                   keyboardType:
//                       const TextInputType.numberWithOptions(decimal: true),
//                   textAlign: TextAlign.center,
//                   decoration: const InputDecoration(
//                       border: InputBorder.none,
//                       hintText: '0',
//                       hintStyle: TextStyle(color: hint)),
//                 ),
//               ),
//               IconButton(
//                   icon: const Icon(Icons.add_circle_outline),
//                   onPressed: () => onStep(1),
//                   splashRadius: 22),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _BmiDial extends StatelessWidget {
//   final double? bmi;
//   final Color color;
//   const _BmiDial({required this.bmi, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 106,
//       height: 106,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: const SweepGradient(
//           colors: [
//             Colors.blue,
//             Colors.green,
//             Colors.orange,
//             Colors.red,
//             Colors.blue
//           ],
//           stops: [0.0, .46, .70, .90, 1.0],
//         ),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
//         ],
//       ),
//       child: Center(
//         child: Container(
//           width: 90,
//           height: 90,
//           decoration:
//               const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//           child: Center(
//             child: bmi == null
//                 ? const Text('--',
//                     style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: _hint))
//                 : Text(
//                     bmi!.toStringAsFixed(1),
//                     style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                         color:
//                             color == Colors.transparent ? Colors.black : color),
//                   ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _HealthyRangeLine extends StatelessWidget {
//   final double cm;
//   final WeightUnit wUnit;
//   const _HealthyRangeLine({required this.cm, required this.wUnit});

//   @override
//   Widget build(BuildContext context) {
//     final m = cm / 100.0;
//     final minKg = 18.5 * m * m;
//     final maxKg = 24.9 * m * m;

//     String render(double kg) {
//       if (wUnit == WeightUnit.kg) return kg.toStringAsFixed(1) + ' kg';
//       final lb = kg / 0.45359237;
//       return lb.toStringAsFixed(0) + ' lb';
//     }

//     return Text(
//       'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
//       style: const TextStyle(fontSize: 12, color: _hint),
//     );
//   }
// }

// class _BmiRangeBar extends StatelessWidget {
//   final double bmi;
//   const _BmiRangeBar({required this.bmi});

//   @override
//   Widget build(BuildContext context) {
//     const maxBmi = 40.0;
//     final clamp = bmi.clamp(0, maxBmi);
//     return LayoutBuilder(
//       builder: (context, c) {
//         final w = c.maxWidth;
//         final x = (clamp / maxBmi) * w;

//         return Stack(
//           alignment: Alignment.centerLeft,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Row(
//                 children: const [
//                   _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
//                   _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
//                   _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
//                   _RangeSegment(color: Colors.red, flex: 100), // 30–40
//                 ],
//               ),
//             ),
//             Positioned(
//               left: x - 8,
//               child: Column(
//                 children: [
//                   Icon(Icons.arrow_drop_down,
//                       color: Colors.black.withOpacity(.65)),
//                   Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                       border: Border.all(color: Colors.black.withOpacity(.2)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned.fill(
//               child: IgnorePointer(
//                 ignoring: true,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     _TickLabel('0'),
//                     _TickLabel('18.5'),
//                     _TickLabel('25'),
//                     _TickLabel('30'),
//                     _TickLabel('40'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _RangeSegment extends StatelessWidget {
//   final Color color;
//   final int flex; // scale out of 399
//   const _RangeSegment({required this.color, required this.flex});
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       flex: flex,
//       child: Container(
//         height: 16,
//         color: color.withOpacity(.25),
//       ),
//     );
//   }
// }

// class _TickLabel extends StatelessWidget {
//   final String text;
//   const _TickLabel(this.text);
//   @override
//   Widget build(BuildContext context) {
//     return Text(text,
//         style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
//   }
// }*/

















// // import 'package:flutter/material.dart';

// // const _hint = Color(0xFF8E8E93);

// // class BmiPage extends StatefulWidget {
// //   const BmiPage({super.key});

// //   @override
// //   State<BmiPage> createState() => _BmiPageState();
// // }

// // enum HeightUnit { cm, ftin }

// // enum WeightUnit { kg, lb }

// // class _BmiPageState extends State<BmiPage> {
// //   // THEME
// //   static const _accent = Color(0xFFFF7A3D);
// //   static const _header = Color(0xFFFF9156);
// //   static const _hint = Color(0xFF8E8E93);

// //   // STATE
// //   bool _isMale = true;
// //   HeightUnit _hUnit = HeightUnit.cm;
// //   WeightUnit _wUnit = WeightUnit.kg;

// //   // Controllers (keep both to allow smooth unit toggles)
// //   final _cmCtrl = TextEditingController(text: '170');
// //   final _ftCtrl = TextEditingController(text: '5');
// //   final _inCtrl = TextEditingController(text: '7'); // 5'7" ≈ 170 cm

// //   final _kgCtrl = TextEditingController(text: '55');
// //   final _lbCtrl = TextEditingController(text: '121'); // ≈ 55 kg

// //   // Result
// //   double? _bmi;
// //   String? _category;
// //   Color _catColor = Colors.transparent;

// //   @override
// //   void dispose() {
// //     _cmCtrl.dispose();
// //     _ftCtrl.dispose();
// //     _inCtrl.dispose();
// //     _kgCtrl.dispose();
// //     _lbCtrl.dispose();
// //     super.dispose();
// //   }

// //   // --- CONVERSIONS ---
// //   double _cmFromCurrent() {
// //     if (_hUnit == HeightUnit.cm) {
// //       return double.tryParse(_cmCtrl.text.trim()) ?? 0;
// //     }
// //     final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
// //     final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
// //     final totalIn = (ft * 12) + inches;
// //     return totalIn * 2.54;
// //   }

// //   double _kgFromCurrent() {
// //     if (_wUnit == WeightUnit.kg) {
// //       return double.tryParse(_kgCtrl.text.trim()) ?? 0;
// //     }
// //     final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
// //     return lb * 0.45359237;
// //   }

// //   void _syncHeightTo(HeightUnit to) {
// //     final cm = _cmFromCurrent().clamp(30, 272); // 1ft–8ft11in safe range
// //     if (to == HeightUnit.cm) {
// //       _cmCtrl.text = cm.toStringAsFixed(0);
// //     } else {
// //       final totalIn = cm / 2.54;
// //       final ft = totalIn ~/ 12;
// //       final inches = totalIn - ft * 12;
// //       _ftCtrl.text = ft.toStringAsFixed(0);
// //       _inCtrl.text = inches.toStringAsFixed(1);
// //     }
// //   }

// //   void _syncWeightTo(WeightUnit to) {
// //     final kg = _kgFromCurrent().clamp(10, 350);
// //     if (to == WeightUnit.kg) {
// //       _kgCtrl.text =
// //           (kg % 1 == 0) ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
// //     } else {
// //       final lb = kg / 0.45359237;
// //       _lbCtrl.text =
// //           (lb % 1 == 0) ? lb.toStringAsFixed(0) : lb.toStringAsFixed(1);
// //     }
// //   }

// //   // --- CALC ---
// //   void _calculate() {
// //     final cm = _cmFromCurrent();
// //     final kg = _kgFromCurrent();
// //     if (cm <= 0 || kg <= 0) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Enter valid height and weight.')),
// //       );
// //       return;
// //     }
// //     final m = cm / 100.0;
// //     final bmi = kg / (m * m);

// //     String cat;
// //     Color col;
// //     if (bmi < 18.5) {
// //       cat = 'Underweight';
// //       col = Colors.blue;
// //     } else if (bmi < 25) {
// //       cat = 'Normal';
// //       col = Colors.green;
// //     } else if (bmi < 30) {
// //       cat = 'Overweight';
// //       col = Colors.orange;
// //     } else {
// //       cat = 'Obese';
// //       col = Colors.red;
// //     }

// //     setState(() {
// //       _bmi = double.parse(bmi.toStringAsFixed(1));
// //       _category = cat;
// //       _catColor = col;
// //     });
// //   }

// //   void _reset() {
// //     setState(() {
// //       _isMale = true;
// //       _hUnit = HeightUnit.cm;
// //       _wUnit = WeightUnit.kg;
// //       _cmCtrl.text = '170';
// //       _ftCtrl.text = '5';
// //       _inCtrl.text = '7';
// //       _kgCtrl.text = '55';
// //       _lbCtrl.text = '121';
// //       _bmi = null;
// //       _category = null;
// //       _catColor = Colors.transparent;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(children: [
// //         // Header gradient
// //         Container(
// //           height: 230,
// //           decoration: const BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [_accent, _header],
// //               begin: Alignment.topCenter,
// //               end: Alignment.bottomCenter,
// //             ),
// //           ),
// //         ),
// //         SafeArea(
// //           child: SingleChildScrollView(
// //             padding: const EdgeInsets.only(bottom: 28),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: [
// //                 const SizedBox(height: 12),
// //                 const Center(
// //                   child: Text(
// //                     'BMI Calculator',
// //                     style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.w700),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),

// //                 // RESULT DIAL CARD
// //                 _Card(
// //                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
// //                   child: Column(
// //                     children: [
// //                       Row(
// //                         children: [
// //                           _BmiDial(bmi: _bmi, color: _catColor),
// //                           const SizedBox(width: 12),
// //                           Expanded(
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   _bmi == null
// //                                       ? 'No result'
// //                                       : '${_bmi!.toStringAsFixed(1)} kg/m²',
// //                                   style: const TextStyle(
// //                                       fontSize: 18,
// //                                       fontWeight: FontWeight.w700),
// //                                 ),
// //                                 const SizedBox(height: 6),
// //                                 Text(
// //                                   _bmi == null
// //                                       ? 'Enter your details and tap Calculate.'
// //                                       : (_category ?? ''),
// //                                   style: TextStyle(
// //                                       fontSize: 14,
// //                                       color: _bmi == null ? _hint : _catColor,
// //                                       fontWeight: FontWeight.w600),
// //                                 ),
// //                                 const SizedBox(height: 8),
// //                                 if (_bmi != null)
// //                                   _HealthyRangeLine(
// //                                       cm: _cmFromCurrent(), wUnit: _wUnit),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       if (_bmi != null) ...[
// //                         const SizedBox(height: 14),
// //                         _BmiRangeBar(bmi: _bmi!),
// //                       ],
// //                     ],
// //                   ),
// //                 ),

// //                 const SizedBox(height: 16),

// //                 // INPUT CARD
// //                 _Card(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Gender (kept for parity with profile style)
// //                       const Text('Gender',
// //                           style: TextStyle(
// //                               fontWeight: FontWeight.w700, fontSize: 16)),
// //                       const SizedBox(height: 10),
// //                       Row(
// //                         children: [
// //                           _Choice(
// //                             label: 'Male',
// //                             selected: _isMale,
// //                             onTap: () => setState(() => _isMale = true),
// //                           ),
// //                           const SizedBox(width: 10),
// //                           _Choice(
// //                             label: 'Female',
// //                             selected: !_isMale,
// //                             onTap: () => setState(() => _isMale = false),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 16),

// //                       // Height
// //                       Row(
// //                         children: [
// //                           const Expanded(
// //                             flex: 2,
// //                             child: Text('Height',
// //                                 style: TextStyle(fontWeight: FontWeight.w700)),
// //                           ),
// //                           Expanded(
// //                             child: _Segmented<HeightUnit>(
// //                               options: const {
// //                                 HeightUnit.cm: 'cm',
// //                                 HeightUnit.ftin: 'ft+in',
// //                               },
// //                               selected: _hUnit,
// //                               onChanged: (v) {
// //                                 setState(() {
// //                                   _syncHeightTo(v);
// //                                   _hUnit = v;
// //                                 });
// //                               },
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       if (_hUnit == HeightUnit.cm)
// //                         _NumberField(
// //                           controller: _cmCtrl,
// //                           unit: 'cm',
// //                           onStep: (d) => _step(_cmCtrl, d,
// //                               min: 30, max: 272, roundInt: true),
// //                         )
// //                       else
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: _MiniNumberField(
// //                                 label: 'ft',
// //                                 controller: _ftCtrl,
// //                                 onStep: (d) => _step(_ftCtrl, d,
// //                                     min: 1, max: 8, roundInt: true),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 10),
// //                             Expanded(
// //                               child: _MiniNumberField(
// //                                 label: 'in',
// //                                 controller: _inCtrl,
// //                                 onStep: (d) => _step(_inCtrl, d,
// //                                     min: 0, max: 11.9, step: .5),
// //                               ),
// //                             ),
// //                           ],
// //                         ),

// //                       const SizedBox(height: 16),

// //                       // Weight
// //                       Row(
// //                         children: [
// //                           const Expanded(
// //                             flex: 2,
// //                             child: Text('Weight',
// //                                 style: TextStyle(fontWeight: FontWeight.w700)),
// //                           ),
// //                           Expanded(
// //                             child: _Segmented<WeightUnit>(
// //                               options: const {
// //                                 WeightUnit.kg: 'kg',
// //                                 WeightUnit.lb: 'lb',
// //                               },
// //                               selected: _wUnit,
// //                               onChanged: (v) {
// //                                 setState(() {
// //                                   _syncWeightTo(v);
// //                                   _wUnit = v;
// //                                 });
// //                               },
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       if (_wUnit == WeightUnit.kg)
// //                         _NumberField(
// //                           controller: _kgCtrl,
// //                           unit: 'kg',
// //                           onStep: (d) => _step(_kgCtrl, d, min: 10, max: 350),
// //                         )
// //                       else
// //                         _NumberField(
// //                           controller: _lbCtrl,
// //                           unit: 'lb',
// //                           onStep: (d) => _step(_lbCtrl, d, min: 22, max: 770),
// //                         ),

// //                       const SizedBox(height: 16),

// //                       // Buttons
// //                       SizedBox(
// //                         height: 52,
// //                         child: ElevatedButton(
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: _accent,
// //                             foregroundColor: Colors.white,
// //                             shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(14)),
// //                             elevation: 0,
// //                           ),
// //                           onPressed: _calculate,
// //                           child: const Text('Calculate BMI',
// //                               style: TextStyle(fontWeight: FontWeight.w700)),
// //                         ),
// //                       ),
// //                       TextButton(
// //                         onPressed: _reset,
// //                         child:
// //                             const Text('Reset', style: TextStyle(color: _hint)),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ]),
// //     );
// //   }

// //   // Step helpers for numeric fields
// //   void _step(TextEditingController c, double delta,
// //       {required double min,
// //       required double max,
// //       bool roundInt = false,
// //       double step = 1}) {
// //     final v = double.tryParse(c.text.trim()) ?? 0;
// //     final next = (v + delta * step).clamp(min, max);
// //     c.text = roundInt
// //         ? next.toStringAsFixed(0)
// //         : (next % 1 == 0 ? next.toStringAsFixed(0) : next.toStringAsFixed(1));
// //     if (_bmi != null) _calculate();
// //   }
// // }

// // // ---------- UI BUILDING BLOCKS ----------

// // class _Card extends StatelessWidget {
// //   final Widget child;
// //   final EdgeInsetsGeometry padding;
// //   const _Card(
// //       {required this.child,
// //       this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12)});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(20),
// //           boxShadow: [
// //             BoxShadow(
// //                 color: Colors.black.withOpacity(.06),
// //                 blurRadius: 14,
// //                 offset: const Offset(0, 6))
// //           ],
// //         ),
// //         padding: padding,
// //         child: child,
// //       ),
// //     );
// //   }
// // }

// // class _Choice extends StatelessWidget {
// //   final String label;
// //   final bool selected;
// //   final VoidCallback onTap;
// //   const _Choice(
// //       {required this.label, required this.selected, required this.onTap});

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 170),
// //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// //         decoration: BoxDecoration(
// //           color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(
// //               color:
// //                   selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(selected ? Icons.male : Icons.female,
// //                 size: 18,
// //                 color: selected
// //                     ? const Color(0xFFFF7A3D)
// //                     : const Color(0xFFBDBDBD)),
// //             const SizedBox(width: 6),
// //             Text(label,
// //                 style: TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     color: selected ? Colors.black : const Color(0xFF6B6B6B))),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _Segmented<T> extends StatelessWidget {
// //   final Map<T, String> options;
// //   final T selected;
// //   final ValueChanged<T> onChanged;
// //   const _Segmented(
// //       {required this.options, required this.selected, required this.onChanged});

// //   @override
// //   Widget build(BuildContext context) {
// //     final keys = options.keys.toList();
// //     return Container(
// //       height: 36,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF5F5F7),
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: const Color(0xFFE6E6E6)),
// //       ),
// //       child: Row(
// //         children: List.generate(keys.length, (i) {
// //           final k = keys[i];
// //           final isSel = k == selected;
// //           return Expanded(
// //             child: GestureDetector(
// //               onTap: () => onChanged(k),
// //               child: AnimatedContainer(
// //                 duration: const Duration(milliseconds: 160),
// //                 alignment: Alignment.center,
// //                 margin: const EdgeInsets.all(3),
// //                 decoration: BoxDecoration(
// //                   color: isSel ? const Color(0xFFFFF0E9) : Colors.transparent,
// //                   borderRadius: BorderRadius.circular(8),
// //                   border: Border.all(
// //                       color:
// //                           isSel ? const Color(0xFFFF7A3D) : Colors.transparent),
// //                 ),
// //                 child: Text(
// //                   options[k]!,
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     color: isSel ? Colors.black : const Color(0xFF6B6B6B),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           );
// //         }),
// //       ),
// //     );
// //   }
// // }

// // class _NumberField extends StatelessWidget {
// //   final TextEditingController controller;
// //   final String unit;
// //   final void Function(double delta) onStep;

// //   const _NumberField({
// //     required this.controller,
// //     required this.unit,
// //     required this.onStep,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     const hint = Color(0xFF8E8E93);
// //     return Container(
// //       height: 52,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF5F5F7),
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(color: const Color(0xFFE6E6E6)),
// //       ),
// //       child: Row(
// //         children: [
// //           IconButton(
// //               icon: const Icon(Icons.remove_circle_outline),
// //               onPressed: () => onStep(-1),
// //               splashRadius: 22),
// //           Expanded(
// //             child: TextField(
// //               controller: controller,
// //               keyboardType:
// //                   const TextInputType.numberWithOptions(decimal: true),
// //               textAlign: TextAlign.center,
// //               decoration: InputDecoration(
// //                 border: InputBorder.none,
// //                 hintText: '0',
// //                 hintStyle: const TextStyle(color: hint),
// //                 suffixText: unit,
// //                 suffixStyle:
// //                     const TextStyle(color: hint, fontWeight: FontWeight.w600),
// //               ),
// //             ),
// //           ),
// //           IconButton(
// //               icon: const Icon(Icons.add_circle_outline),
// //               onPressed: () => onStep(1),
// //               splashRadius: 22),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _MiniNumberField extends StatelessWidget {
// //   final String label;
// //   final TextEditingController controller;
// //   final void Function(double delta) onStep;

// //   const _MiniNumberField({
// //     required this.label,
// //     required this.controller,
// //     required this.onStep,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     const hint = Color(0xFF8E8E93);
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
// //         const SizedBox(height: 6),
// //         Container(
// //           height: 52,
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFF5F5F7),
// //             borderRadius: BorderRadius.circular(14),
// //             border: Border.all(color: const Color(0xFFE6E6E6)),
// //           ),
// //           child: Row(
// //             children: [
// //               IconButton(
// //                   icon: const Icon(Icons.remove_circle_outline),
// //                   onPressed: () => onStep(-1),
// //                   splashRadius: 22),
// //               Expanded(
// //                 child: TextField(
// //                   controller: controller,
// //                   keyboardType:
// //                       const TextInputType.numberWithOptions(decimal: true),
// //                   textAlign: TextAlign.center,
// //                   decoration: const InputDecoration(
// //                       border: InputBorder.none,
// //                       hintText: '0',
// //                       hintStyle: TextStyle(color: hint)),
// //                 ),
// //               ),
// //               IconButton(
// //                   icon: const Icon(Icons.add_circle_outline),
// //                   onPressed: () => onStep(1),
// //                   splashRadius: 22),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class _BmiDial extends StatelessWidget {
// //   final double? bmi;
// //   final Color color;
// //   const _BmiDial({required this.bmi, required this.color});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 106,
// //       height: 106,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         gradient: const SweepGradient(
// //           colors: [
// //             Colors.blue,
// //             Colors.green,
// //             Colors.orange,
// //             Colors.red,
// //             Colors.blue
// //           ],
// //           stops: [0.0, .46, .70, .90, 1.0],
// //         ),
// //         boxShadow: [
// //           BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10)
// //         ],
// //       ),
// //       child: Center(
// //         child: Container(
// //           width: 90,
// //           height: 90,
// //           decoration:
// //               const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
// //           child: Center(
// //             child: bmi == null
// //                 ? const Text('--',
// //                     style: TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.w700,
// //                         color: _hint))
// //                 : Text(
// //                     bmi!.toStringAsFixed(1),
// //                     style: TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.w800,
// //                         color:
// //                             color == Colors.transparent ? Colors.black : color),
// //                   ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _HealthyRangeLine extends StatelessWidget {
// //   final double cm;
// //   final WeightUnit wUnit;
// //   const _HealthyRangeLine({required this.cm, required this.wUnit});

// //   @override
// //   Widget build(BuildContext context) {
// //     final m = cm / 100.0;
// //     final minKg = 18.5 * m * m;
// //     final maxKg = 24.9 * m * m;

// //     String render(double kg) {
// //       if (wUnit == WeightUnit.kg) return kg.toStringAsFixed(1) + ' kg';
// //       final lb = kg / 0.45359237;
// //       return lb.toStringAsFixed(0) + ' lb';
// //     }

// //     return Text(
// //       'Healthy weight: ${render(minKg)} – ${render(maxKg)}',
// //       style: const TextStyle(fontSize: 12, color: _hint),
// //     );
// //   }
// // }

// // class _BmiRangeBar extends StatelessWidget {
// //   final double bmi;
// //   const _BmiRangeBar({required this.bmi});

// //   @override
// //   Widget build(BuildContext context) {
// //     const maxBmi = 40.0;
// //     final clamp = bmi.clamp(0, maxBmi);
// //     return LayoutBuilder(
// //       builder: (context, c) {
// //         final w = c.maxWidth;
// //         final x = (clamp / maxBmi) * w;

// //         return Stack(
// //           alignment: Alignment.centerLeft,
// //           children: [
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(10),
// //               child: Row(
// //                 children: const [
// //                   _RangeSegment(color: Colors.blue, flex: 185), // 0–18.5
// //                   _RangeSegment(color: Colors.green, flex: 64), // 18.5–24.9
// //                   _RangeSegment(color: Colors.orange, flex: 50), // 25–29.9
// //                   _RangeSegment(color: Colors.red, flex: 100), // 30–40
// //                 ],
// //               ),
// //             ),
// //             Positioned(
// //               left: x - 8,
// //               child: Column(
// //                 children: [
// //                   Icon(Icons.arrow_drop_down,
// //                       color: Colors.black.withOpacity(.65)),
// //                   Container(
// //                     width: 16,
// //                     height: 16,
// //                     decoration: BoxDecoration(
// //                       shape: BoxShape.circle,
// //                       color: Colors.white,
// //                       border: Border.all(color: Colors.black.withOpacity(.2)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Positioned.fill(
// //               child: IgnorePointer(
// //                 ignoring: true,
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: const [
// //                     _TickLabel('0'),
// //                     _TickLabel('18.5'),
// //                     _TickLabel('25'),
// //                     _TickLabel('30'),
// //                     _TickLabel('40'),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// // }

// // class _RangeSegment extends StatelessWidget {
// //   final Color color;
// //   final int flex; // scale out of 399
// //   const _RangeSegment({required this.color, required this.flex});
// //   @override
// //   Widget build(BuildContext context) {
// //     return Expanded(
// //       flex: flex,
// //       child: Container(
// //         height: 16,
// //         color: color.withOpacity(.25),
// //       ),
// //     );
// //   }
// // }

// // class _TickLabel extends StatelessWidget {
// //   final String text;
// //   const _TickLabel(this.text);
// //   @override
// //   Widget build(BuildContext context) {
// //     return Text(text,
// //         style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
// //   }
// // }



// // // class BmiPage extends StatefulWidget {
// // //   const BmiPage({super.key});

// // //   @override
// // //   State<BmiPage> createState() => _BmiPageState();
// // // }

// // // class _BmiPageState extends State<BmiPage> {
// // //   static const _accent = Color(0xFFFF7A3D);
// // //   static const _header = Color(0xFFFF9156);
// // //   static const _hint = Color(0xFF8E8E93);

// // //   final _heightCtrl = TextEditingController(text: '170'); // cm
// // //   final _weightCtrl = TextEditingController(text: '55');  // kg
// // //   bool _isMale = true;

// // //   double? _bmi;
// // //   String? _category;
// // //   Color _catColor = Colors.transparent;

// // //   @override
// // //   void dispose() {
// // //     _heightCtrl.dispose();
// // //     _weightCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   void _calculate() {
// // //     final h = double.tryParse(_heightCtrl.text.trim());
// // //     final w = double.tryParse(_weightCtrl.text.trim());
// // //     if (h == null || h <= 0 || w == null || w <= 0) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(content: Text('Enter valid height (cm) and weight (kg).')),
// // //       );
// // //       return;
// // //     }
// // //     final m = h / 100.0;
// // //     final bmi = w / (m * m);
// // //     String cat;
// // //     Color col;
// // //     if (bmi < 18.5) { cat = 'Underweight'; col = Colors.blue; }
// // //     else if (bmi < 25) { cat = 'Normal'; col = Colors.green; }
// // //     else if (bmi < 30) { cat = 'Overweight'; col = Colors.orange; }
// // //     else { cat = 'Obese'; col = Colors.red; }

// // //     setState(() {
// // //       _bmi = double.parse(bmi.toStringAsFixed(1));
// // //       _category = cat;
// // //       _catColor = col;
// // //     });
// // //   }

// // //   void _reset() {
// // //     setState(() {
// // //       _heightCtrl.text = '170';
// // //       _weightCtrl.text = '55';
// // //       _bmi = null;
// // //       _category = null;
// // //       _catColor = Colors.transparent;
// // //       _isMale = true;
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final themeTitle = const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20);

// // //     return Scaffold(
// // //       body: Stack(
// // //         children: [
// // //           // Header gradient (same vibe as Profile)
// // //           Container(
// // //             height: 210,
// // //             decoration: const BoxDecoration(
// // //               gradient: LinearGradient(
// // //                 colors: [_accent, _header],
// // //                 begin: Alignment.topCenter,
// // //                 end: Alignment.bottomCenter,
// // //               ),
// // //             ),
// // //           ),
// // //           SafeArea(
// // //             child: SingleChildScrollView(
// // //               padding: const EdgeInsets.only(bottom: 24),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.stretch,
// // //                 children: [
// // //                   const SizedBox(height: 12),
// // //                   const Center(child: Text('BMI Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20))),
// // //                   const SizedBox(height: 16),

// // //                   // Input Card
// // //                   _Card(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         // Gender (just for UI consistency; BMI math does not use it)
// // //                         const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
// // //                         const SizedBox(height: 10),
// // //                         Row(
// // //                           children: [
// // //                             _Choice(
// // //                               label: 'Male',
// // //                               selected: _isMale,
// // //                               onTap: () => setState(() => _isMale = true),
// // //                             ),
// // //                             const SizedBox(width: 10),
// // //                             _Choice(
// // //                               label: 'Female',
// // //                               selected: !_isMale,
// // //                               onTap: () => setState(() => _isMale = false),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                         const SizedBox(height: 16),

// // //                         // Height & Weight
// // //                         Row(
// // //                           children: [
// // //                             Expanded(
// // //                               child: _NumberField(
// // //                                 label: 'Height',
// // //                                 unit: 'cm',
// // //                                 controller: _heightCtrl,
// // //                                 onStep: (d) => _step(_heightCtrl, d, min: 50, max: 250),
// // //                               ),
// // //                             ),
// // //                             const SizedBox(width: 12),
// // //                             Expanded(
// // //                               child: _NumberField(
// // //                                 label: 'Weight',
// // //                                 unit: 'kg',
// // //                                 controller: _weightCtrl,
// // //                                 onStep: (d) => _step(_weightCtrl, d, min: 10, max: 300),
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),

// // //                         const SizedBox(height: 16),

// // //                         // Buttons
// // //                         SizedBox(
// // //                           height: 52,
// // //                           child: ElevatedButton(
// // //                             style: ElevatedButton.styleFrom(
// // //                               backgroundColor: _accent,
// // //                               foregroundColor: Colors.white,
// // //                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // //                               elevation: 0,
// // //                             ),
// // //                             onPressed: _calculate,
// // //                             child: const Text('Calculate BMI', style: TextStyle(fontWeight: FontWeight.w700)),
// // //                           ),
// // //                         ),
// // //                         TextButton(
// // //                           onPressed: _reset,
// // //                           child: const Text('Reset', style: TextStyle(color: _hint)),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),

// // //                   const SizedBox(height: 16),

// // //                   // Result Card
// // //                   _Card(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         const Text('Result', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
// // //                         const SizedBox(height: 10),

// // //                         if (_bmi == null) ...[
// // //                           const Text('Enter your height and weight, then tap Calculate.', style: TextStyle(color: _hint)),
// // //                         ] else ...[
// // //                           Row(
// // //                             children: [
// // //                               Expanded(
// // //                                 child: _MetricChip(value: _bmi!.toStringAsFixed(1), unit: 'kg/m²', label: 'BMI'),
// // //                               ),
// // //                               const SizedBox(width: 10),
// // //                               Expanded(
// // //                                 child: Container(
// // //                                   height: 66,
// // //                                   decoration: BoxDecoration(
// // //                                     color: const Color(0xFFFFF0E9),
// // //                                     borderRadius: BorderRadius.circular(14),
// // //                                   ),
// // //                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// // //                                   child: Column(
// // //                                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                                     children: [
// // //                                       Text(_category ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: _catColor)),
// // //                                       const SizedBox(height: 4),
// // //                                       const Text('Category', style: TextStyle(color: _hint, fontSize: 12)),
// // //                                     ],
// // //                                   ),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                           const SizedBox(height: 16),
// // //                           _BmiRangeBar(bmi: _bmi!),
// // //                           const SizedBox(height: 12),
// // //                           _HealthyWeightRange(heightCm: double.tryParse(_heightCtrl.text) ?? 0),
// // //                           const SizedBox(height: 6),
// // //                           const Text('BMI = weight (kg) / [height (m)]²', style: TextStyle(color: _hint, fontSize: 12)),
// // //                         ],
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _step(TextEditingController c, double delta, {required double min, required double max}) {
// // //     final v = double.tryParse(c.text.trim()) ?? 0;
// // //     final next = (v + delta).clamp(min, max);
// // //     c.text = (next % 1 == 0) ? next.toStringAsFixed(0) : next.toStringAsFixed(1);
// // //     // Live recalc if result already shown
// // //     if (_bmi != null) _calculate();
// // //   }
// // // }

// // // class _Card extends StatelessWidget {
// // //   final Widget child;
// // //   const _Card({required this.child});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 16),
// // //       child: Container(
// // //         decoration: BoxDecoration(
// // //           color: Colors.white,
// // //           borderRadius: BorderRadius.circular(20),
// // //           boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 6))],
// // //         ),
// // //         padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
// // //         child: child,
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _Choice extends StatelessWidget {
// // //   final String label;
// // //   final bool selected;
// // //   final VoidCallback onTap;
// // //   const _Choice({required this.label, required this.selected, required this.onTap});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: AnimatedContainer(
// // //         duration: const Duration(milliseconds: 180),
// // //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// // //         decoration: BoxDecoration(
// // //           color: selected ? const Color(0xFFFFF0E9) : const Color(0xFFF5F5F7),
// // //           borderRadius: BorderRadius.circular(14),
// // //           border: Border.all(color: selected ? const Color(0xFFFF7A3D) : const Color(0xFFE6E6E6)),
// // //         ),
// // //         child: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: selected ? const Color(0xFFFF7A3D) : const Color(0xFFBDBDBD)),
// // //             const SizedBox(width: 6),
// // //             Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.black : const Color(0xFF6B6B6B))),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _NumberField extends StatelessWidget {
// // //   final String label;
// // //   final String unit;
// // //   final TextEditingController controller;
// // //   final void Function(double delta) onStep;

// // //   const _NumberField({
// // //     required this.label,
// // //     required this.unit,
// // //     required this.controller,
// // //     required this.onStep,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     const hint = Color(0xFF8E8E93);
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
// // //         const SizedBox(height: 8),
// // //         Container(
// // //           height: 52,
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFFF5F5F7),
// // //             borderRadius: BorderRadius.circular(14),
// // //             border: Border.all(color: const Color(0xFFE6E6E6)),
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               IconButton(
// // //                 icon: const Icon(Icons.remove_circle_outline),
// // //                 onPressed: () => onStep(-1),
// // //                 splashRadius: 22,
// // //               ),
// // //               Expanded(
// // //                 child: TextField(
// // //                   controller: controller,
// // //                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
// // //                   textAlign: TextAlign.center,
// // //                   decoration: InputDecoration(
// // //                     border: InputBorder.none,
// // //                     hintText: '0',
// // //                     hintStyle: const TextStyle(color: hint),
// // //                     suffixText: unit,
// // //                     suffixStyle: const TextStyle(color: hint, fontWeight: FontWeight.w600),
// // //                   ),
// // //                 ),
// // //               ),
// // //               IconButton(
// // //                 icon: const Icon(Icons.add_circle_outline),
// // //                 onPressed: () => onStep(1),
// // //                 splashRadius: 22,
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _MetricChip extends StatelessWidget {
// // //   final String value;
// // //   final String unit;
// // //   final String label;
// // //   const _MetricChip({required this.value, required this.unit, required this.label});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       height: 66,
// // //       decoration: BoxDecoration(color: const Color(0xFFFFF0E9), borderRadius: BorderRadius.circular(14)),
// // //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           RichText(
// // //             text: TextSpan(style: const TextStyle(color: Colors.black), children: [
// // //               TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700)),
// // //               TextSpan(text: ' $unit', style: const TextStyle(color: Color(0xFF8E8E93))),
// // //             ]),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _HealthyWeightRange extends StatelessWidget {
// // //   final double heightCm;
// // //   const _HealthyWeightRange({required this.heightCm});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     if (heightCm <= 0) return const SizedBox.shrink();
// // //     final m = heightCm / 100.0;
// // //     final minW = 18.5 * m * m;
// // //     final maxW = 24.9 * m * m;
// // //     return Text(
// // //       'Healthy weight range: ${minW.toStringAsFixed(1)}–${maxW.toStringAsFixed(1)} kg for ${heightCm.toStringAsFixed(0)} cm',
// // //       style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
// // //     );
// // //   }
// // // }

// // // class _BmiRangeBar extends StatelessWidget {
// // //   final double bmi;
// // //   const _BmiRangeBar({required this.bmi});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // Segments: 0–18.5 (blue), 18.5–24.9 (green), 25–29.9 (orange), 30–40 (red)
// // //     const maxBmi = 40.0;
// // //     final clamp = bmi.clamp(0, maxBmi);
// // //     return LayoutBuilder(
// // //       builder: (context, c) {
// // //         final w = c.maxWidth;
// // //         final x = (clamp / maxBmi) * w;

// // //         return Stack(
// // //           alignment: Alignment.centerLeft,
// // //           children: [
// // //             Row(
// // //               children: const [
// // //                 _RangeSegment(color: Colors.blue, flex: 185),   // 0–18.5
// // //                 _RangeSegment(color: Colors.green, flex: 64),    // 18.5–24.9
// // //                 _RangeSegment(color: Colors.orange, flex: 50),   // 25–29.9
// // //                 _RangeSegment(color: Colors.red, flex: 100),     // 30–40
// // //               ],
// // //             ),
// // //             // Pointer
// // //             Positioned(
// // //               left: x - 8,
// // //               child: Column(
// // //                 children: [
// // //                   Icon(Icons.arrow_drop_down, color: Colors.black.withOpacity(.65)),
// // //                   Container(
// // //                     width: 16, height: 16,
// // //                     decoration: BoxDecoration(
// // //                       shape: BoxShape.circle,
// // //                       color: Colors.white,
// // //                       border: Border.all(color: Colors.black.withOpacity(.2)),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             // Labels
// // //             Positioned.fill(
// // //               child: IgnorePointer(
// // //                 ignoring: true,
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: const [
// // //                     _TickLabel('0'),
// // //                     _TickLabel('18.5'),
// // //                     _TickLabel('25'),
// // //                     _TickLabel('30'),
// // //                     _TickLabel('40'),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // class _RangeSegment extends StatelessWidget {
// // //   final Color color;
// // //   final int flex; // scale out of 399 (185+64+50+100)
// // //   const _RangeSegment({required this.color, required this.flex});
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Expanded(
// // //       flex: flex,
// // //       child: Container(
// // //         height: 16,
// // //         decoration: BoxDecoration(
// // //           color: color.withOpacity(.25),
// // //           borderRadius: BorderRadius.circular(10),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _TickLabel extends StatelessWidget {
// // //   final String text;
// // //   const _TickLabel(this.text);
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)));
// // //   }
// // // }
