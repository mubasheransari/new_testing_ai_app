import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// shared hint color used across small widgets
const _hint = Color(0xFF8E8E93);

enum HeightUnit { cm, ftin }

enum WeightUnit { kg, lb }

enum Activity { low, moderate, high }

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  // Theme (same vibe as your profile/BMI screens)
  static const _accent = Color(0xFFFF7A3D);
  static const _header = Color(0xFFFF9156);

  // Gender & Units
  bool _isMale = true;
  HeightUnit _hUnit = HeightUnit.cm;
  WeightUnit _wUnit = WeightUnit.kg;
  Activity _activity = Activity.moderate; // default: Moderately Active

  // Inputs (defaults)
  final _ageCtrl = TextEditingController(text: '25');

  // height
  final _cmCtrl = TextEditingController(text: '175');
  final _ftCtrl = TextEditingController(text: '5');
  final _inCtrl = TextEditingController(text: '9'); // 5'9" ≈ 175 cm

  // weight
  final _kgCtrl = TextEditingController(text: '70');
  final _lbCtrl = TextEditingController(text: '154'); // ≈ 70 kg

  // Results
  double? _bmr; // kcal/day
  double? _tdee; // kcal/day (maintenance)

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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

  // ---------- Persistence ----------
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();

    setState(() {
      _isMale = p.getBool('cal_isMale') ?? true;

      final hu = p.getInt('cal_hUnit');
      if (hu != null && hu >= 0 && hu < HeightUnit.values.length) {
        _hUnit = HeightUnit.values[hu];
      }

      final wu = p.getInt('cal_wUnit');
      if (wu != null && wu >= 0 && wu < WeightUnit.values.length) {
        _wUnit = WeightUnit.values[wu];
      }

      final act = p.getInt('cal_activity');
      if (act != null && act >= 0 && act < Activity.values.length) {
        _activity = Activity.values[act];
      }

      _ageCtrl.text = p.getString('cal_age') ?? _ageCtrl.text;
      _cmCtrl.text = p.getString('cal_cm') ?? _cmCtrl.text;
      _ftCtrl.text = p.getString('cal_ft') ?? _ftCtrl.text;
      _inCtrl.text = p.getString('cal_in') ?? _inCtrl.text;
      _kgCtrl.text = p.getString('cal_kg') ?? _kgCtrl.text;
      _lbCtrl.text = p.getString('cal_lb') ?? _lbCtrl.text;

      final bmr = p.getDouble('cal_bmr');
      final tdee = p.getDouble('cal_tdee');
      _bmr = bmr;
      _tdee = tdee;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('cal_isMale', _isMale);
    await p.setInt('cal_hUnit', _hUnit.index);
    await p.setInt('cal_wUnit', _wUnit.index);
    await p.setInt('cal_activity', _activity.index);

    await p.setString('cal_age', _ageCtrl.text.trim());
    await p.setString('cal_cm', _cmCtrl.text.trim());
    await p.setString('cal_ft', _ftCtrl.text.trim());
    await p.setString('cal_in', _inCtrl.text.trim());
    await p.setString('cal_kg', _kgCtrl.text.trim());
    await p.setString('cal_lb', _lbCtrl.text.trim());

    if (_bmr != null) {
      await p.setDouble('cal_bmr', _bmr!);
    } else {
      await p.remove('cal_bmr');
    }
    if (_tdee != null) {
      await p.setDouble('cal_tdee', _tdee!);
    } else {
      await p.remove('cal_tdee');
    }
  }

  // ---------- Conversions ----------
  double _cmFromCurrent() {
    if (_hUnit == HeightUnit.cm) {
      return double.tryParse(_cmCtrl.text.trim()) ?? 0;
    }
    final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
    final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
    return ((ft * 12) + inches) * 2.54;
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

  // ---------- Calculation ----------
  // Mifflin–St Jeor BMR:
  // Male:   BMR = 10*kg + 6.25*cm - 5*age + 5
  // Female: BMR = 10*kg + 6.25*cm - 5*age - 161
  //
  // Activity factors:
  // Low Active       -> 1.375
  // Moderately Active-> 1.55
  // High Active      -> 1.725
  void _calculate() {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final cm = _cmFromCurrent();
    final kg = _kgFromCurrent();

    if (age <= 0 || cm <= 0 || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid age, height, and weight.')),
      );
      return;
    }

    final bmr = 10 * kg + 6.25 * cm - 5 * age + (_isMale ? 5 : -161);

    final factor = (_activity == Activity.low)
        ? 1.375
        : (_activity == Activity.moderate)
            ? 1.55
            : 1.725; // Activity.high

    setState(() {
      _bmr = double.parse(bmr.toStringAsFixed(0));
      _tdee = double.parse((bmr * factor).toStringAsFixed(0));
    });

    _savePrefs(); // persist inputs + results
  }

  void _reset() {
    setState(() {
      _isMale = true;
      _hUnit = HeightUnit.cm;
      _wUnit = WeightUnit.kg;
      _activity = Activity.moderate;

      _ageCtrl.text = '25';
      _cmCtrl.text = '175';
      _ftCtrl.text = '5';
      _inCtrl.text = '9';
      _kgCtrl.text = '70';
      _lbCtrl.text = '154';

      _bmr = null;
      _tdee = null;
    });
    _savePrefs();
  }

  // quick helper for step buttons
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
    if (_tdee != null || _bmr != null) {
      // optional: re-save when user tweaks after calc
      _savePrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Orange header
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
                  child: Text('Calories Calculator',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),

                // RESULT CARD
                _Card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CaloriesDial(kcal: _tdee),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tdee == null
                                      ? 'No result'
                                      : '${_tdee!.toStringAsFixed(0)} kcal/day',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Calories',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _tdee == null
                                          ? _hint
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                if (_bmr != null)
                                  _MetricChip(
                                      value: _bmr!.toStringAsFixed(0),
                                      unit: 'kcal/day',
                                      label: 'BMR'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_tdee != null) ...[
                        const SizedBox(height: 14),
                        // Quick guide chips for goals
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _GoalChip(
                                title: 'Lose (−15%)',
                                value: (_tdee! * .85).round()),
                            _GoalChip(title: 'Maintain', value: _tdee!.round()),
                            _GoalChip(
                                title: 'Gain (+15%)',
                                value: (_tdee! * 1.15).round()),
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

                      // Age
                      const Text('Age',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _NumberField(
                        controller: _ageCtrl,
                        unit: 'yrs',
                        onStep: (d) => _step(_ageCtrl, d,
                            min: 5, max: 100, roundInt: true),
                      ),

                      const SizedBox(height: 16),

                      // Height
                      Row(
                        children: [
                          const Expanded(
                              flex: 2,
                              child: Text('Height',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(
                            child: _Segmented<HeightUnit>(
                              options: const {
                                HeightUnit.cm: 'cm',
                                HeightUnit.ftin: 'ft+in'
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(
                            child: _Segmented<WeightUnit>(
                              options: const {
                                WeightUnit.kg: 'kg',
                                WeightUnit.lb: 'lb'
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

                      // Activity Level
                      const Text('Activity Level',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _Segmented<Activity>(
                        options: const {
                          Activity.low: 'Low Active',
                          Activity.moderate: 'Moderately Active',
                          Activity.high: 'High Active',
                        },
                        selected: _activity,
                        onChanged: (v) {
                          setState(() => _activity = v);
                          _savePrefs();
                        },
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
                          child: const Text('Calculate',
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

// ---------- Reusable UI (same styling as BMI) ----------

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
      height: 56,
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
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

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final void Function(double delta) onStep;

  const _NumberField(
      {required this.controller, required this.unit, required this.onStep});

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
              onPressed: () => onStep(-1),
              splashRadius: 22),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: const TextStyle(color: _hint),
                suffixText: unit,
                suffixStyle:
                    const TextStyle(color: _hint, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onStep(1),
              splashRadius: 22),
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

class _MetricChip extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const _MetricChip(
      {required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0E9),
          borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text: ' $unit', style: const TextStyle(color: _hint)),
                ]),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _hint, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CaloriesDial extends StatelessWidget {
  final double? kcal;
  const _CaloriesDial({required this.kcal});

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
            child: kcal == null
                ? const Text('--',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _hint))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kcal!.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('kcal',
                          style: TextStyle(
                              fontSize: 12,
                              color: _hint,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String title;
  final int value;
  const _GoalChip({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$title • ${value.toString()} kcal',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
    );
  }
}


// import 'package:flutter/material.dart';

// // shared hint color used across small widgets
// const _hint = Color(0xFF8E8E93);

// enum HeightUnit { cm, ftin }

// enum WeightUnit { kg, lb }

// enum Activity { low, moderate, high }

// class CaloriesPage extends StatefulWidget {
//   const CaloriesPage({super.key});

//   @override
//   State<CaloriesPage> createState() => _CaloriesPageState();
// }

// class _CaloriesPageState extends State<CaloriesPage> {
//   // Theme (same vibe as your profile/BMI screens)
//   static const _accent = Color(0xFFFF7A3D);
//   static const _header = Color(0xFFFF9156);

//   // Gender & Units
//   bool _isMale = true;
//   HeightUnit _hUnit = HeightUnit.cm;
//   WeightUnit _wUnit = WeightUnit.kg;
//   Activity _activity = Activity.moderate; // default: Moderately Active

//   // Inputs (defaults from your example)
//   final _ageCtrl = TextEditingController(text: '25');

//   // height
//   final _cmCtrl = TextEditingController(text: '175');
//   final _ftCtrl = TextEditingController(text: '5');
//   final _inCtrl = TextEditingController(text: '9'); // 5'9" ≈ 175 cm

//   // weight
//   final _kgCtrl = TextEditingController(text: '70');
//   final _lbCtrl = TextEditingController(text: '154'); // ≈ 70 kg

//   // Results
//   double? _bmr; // kcal/day
//   double? _tdee; // kcal/day (maintenance)

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

//   // ---------- Conversions ----------
//   double _cmFromCurrent() {
//     if (_hUnit == HeightUnit.cm)
//       return double.tryParse(_cmCtrl.text.trim()) ?? 0;
//     final ft = double.tryParse(_ftCtrl.text.trim()) ?? 0;
//     final inches = double.tryParse(_inCtrl.text.trim()) ?? 0;
//     return ((ft * 12) + inches) * 2.54;
//   }

//   double _kgFromCurrent() {
//     if (_wUnit == WeightUnit.kg)
//       return double.tryParse(_kgCtrl.text.trim()) ?? 0;
//     final lb = double.tryParse(_lbCtrl.text.trim()) ?? 0;
//     return lb * 0.45359237;
//   }

//   void _syncHeightTo(HeightUnit to) {
//     final cm = _cmFromCurrent().clamp(30, 272); // safe range
//     if (to == HeightUnit.cm) {
//       _cmCtrl.text = cm.toStringAsFixed(0);
//     } else {
//       final totalIn = cm / 2.54;
//       final ft = totalIn ~/ 12;
//       final inches = totalIn - ft * 12;
//       _ftCtrl.text = ft.toStringAsFixed(0);
//       _inCtrl.text = inches.toStringAsFixed(1);
//     }
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
//   }

//   // ---------- Calculation ----------
//   // Mifflin–St Jeor BMR:
//   // Male:   BMR = 10*kg + 6.25*cm - 5*age + 5
//   // Female: BMR = 10*kg + 6.25*cm - 5*age - 161
//   //
//   // Activity factors:
//   // Low Active       -> 1.375
//   // Moderately Active-> 1.55
//   // High Active      -> 1.725
//   void _calculate() {
//     final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
//     final cm = _cmFromCurrent();
//     final kg = _kgFromCurrent();

//     if (age <= 0 || cm <= 0 || kg <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter valid age, height, and weight.')),
//       );
//       return;
//     }

//     final bmr = 10 * kg + 6.25 * cm - 5 * age + (_isMale ? 5 : -161);

//     final factor = (_activity == Activity.low)
//         ? 1.375
//         : (_activity == Activity.moderate)
//             ? 1.55
//             : 1.725; // Activity.high

//     setState(() {
//       _bmr = double.parse(bmr.toStringAsFixed(0));
//       _tdee = double.parse((bmr * factor).toStringAsFixed(0));
//     });
//   }

//   void _reset() {
//     setState(() {
//       _isMale = true;
//       _hUnit = HeightUnit.cm;
//       _wUnit = WeightUnit.kg;
//       _activity = Activity.moderate;

//       _ageCtrl.text = '25';
//       _cmCtrl.text = '175';
//       _ftCtrl.text = '5';
//       _inCtrl.text = '9';
//       _kgCtrl.text = '70';
//       _lbCtrl.text = '154';

//       _bmr = null;
//       _tdee = null;
//     });
//   }

//   // quick helper for step buttons
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
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(children: [
//         // Orange header
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
//                   child: Text('Calories Calculator',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700)),
//                 ),
//                 const SizedBox(height: 12),

//                 // RESULT CARD
//                 _Card(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           _CaloriesDial(kcal: _tdee),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _tdee == null
//                                       ? 'No result'
//                                       : '${_tdee!.toStringAsFixed(0)} kcal/day',
//                                   style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w700),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   'Calories',
//                                   //   'Maintenance Calories (TDEE)',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       color: _tdee == null
//                                           ? _hint
//                                           : Colors.black87,
//                                       fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 if (_bmr != null)
//                                   _MetricChip(
//                                       value: _bmr!.toStringAsFixed(0),
//                                       unit: 'kcal/day',
//                                       label: 'BMR'),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (_tdee != null) ...[
//                         const SizedBox(height: 14),
//                         // Quick guide chips for goals
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             _GoalChip(
//                                 title: 'Lose (−15%)',
//                                 value: (_tdee! * .85).round()),
//                             _GoalChip(title: 'Maintain', value: _tdee!.round()),
//                             _GoalChip(
//                                 title: 'Gain (+15%)',
//                                 value: (_tdee! * 1.15).round()),
//                           ],
//                         ),
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
//                               label: 'Male',
//                               selected: _isMale,
//                               onTap: () => setState(() => _isMale = true)),
//                           const SizedBox(width: 10),
//                           _Choice(
//                               label: 'Female',
//                               selected: !_isMale,
//                               onTap: () => setState(() => _isMale = false)),
//                         ],
//                       ),

//                       const SizedBox(height: 16),

//                       // Age
//                       const Text('Age',
//                           style: TextStyle(fontWeight: FontWeight.w700)),
//                       const SizedBox(height: 8),
//                       _NumberField(
//                         controller: _ageCtrl,
//                         unit: 'yrs',
//                         onStep: (d) => _step(_ageCtrl, d,
//                             min: 5, max: 100, roundInt: true),
//                       ),

//                       const SizedBox(height: 16),

//                       // Height
//                       Row(
//                         children: [
//                           const Expanded(
//                               flex: 2,
//                               child: Text('Height',
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.w700))),
//                           Expanded(
//                             child: _Segmented<HeightUnit>(
//                               options: const {
//                                 HeightUnit.cm: 'cm',
//                                 HeightUnit.ftin: 'ft+in'
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
//                               flex: 2,
//                               child: Text('Weight',
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.w700))),
//                           Expanded(
//                             child: _Segmented<WeightUnit>(
//                               options: const {
//                                 WeightUnit.kg: 'kg',
//                                 WeightUnit.lb: 'lb'
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

//                       // Activity Level
//                       const Text('Activity Level',
//                           style: TextStyle(fontWeight: FontWeight.w700)),
//                       const SizedBox(height: 8),
//                       _Segmented<Activity>(
//                         options: const {
//                           Activity.low: 'Low Active',
//                           Activity.moderate: 'Moderately Active',
//                           Activity.high: 'High Active',
//                         },
//                         selected: _activity,
//                         onChanged: (v) => setState(() => _activity = v),
//                       ),

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
//                           child: const Text('Calculate',
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
// }

// // ---------- Reusable UI (same styling as BMI) ----------

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
//       height: 56,
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
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 12.5,
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

//   const _NumberField(
//       {required this.controller, required this.unit, required this.onStep});

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
//                 hintStyle: const TextStyle(color: _hint),
//                 suffixText: unit,
//                 suffixStyle:
//                     const TextStyle(color: _hint, fontWeight: FontWeight.w600),
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

//   const _MiniNumberField(
//       {required this.label, required this.controller, required this.onStep});

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

// class _MetricChip extends StatelessWidget {
//   final String value;
//   final String unit;
//   final String label;
//   const _MetricChip(
//       {required this.value, required this.unit, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 66,
//       decoration: BoxDecoration(
//           color: const Color(0xFFFFF0E9),
//           borderRadius: BorderRadius.circular(14)),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           RichText(
//             text: TextSpan(
//                 style: const TextStyle(color: Colors.black),
//                 children: [
//                   TextSpan(
//                       text: value,
//                       style: const TextStyle(fontWeight: FontWeight.w700)),
//                   TextSpan(
//                       text: ' $unit', style: const TextStyle(color: _hint)),
//                 ]),
//           ),
//           const SizedBox(height: 4),
//           Text(label, style: const TextStyle(color: _hint, fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// class _CaloriesDial extends StatelessWidget {
//   final double? kcal;
//   const _CaloriesDial({required this.kcal});

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
//             child: kcal == null
//                 ? const Text('--',
//                     style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: _hint))
//                 : Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(kcal!.toStringAsFixed(0),
//                           style: const TextStyle(
//                               fontSize: 22, fontWeight: FontWeight.w800)),
//                       const SizedBox(height: 2),
//                       const Text('kcal',
//                           style: TextStyle(
//                               fontSize: 12,
//                               color: _hint,
//                               fontWeight: FontWeight.w600)),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _GoalChip extends StatelessWidget {
//   final String title;
//   final int value;
//   const _GoalChip({required this.title, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F5F7),
//         border: Border.all(color: const Color(0xFFE6E6E6)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text('$title • ${value.toString()} kcal',
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
//     );
//   }
// }
