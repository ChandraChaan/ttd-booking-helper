import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'look.dart';
import 'model.dart';

/// Add or edit one devotee. Returns the saved devotee, or null.
Future<Devotee?> editDevotee(BuildContext context, {Devotee? existing}) {
  return showModalBottomSheet<Devotee>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DevoteeForm(existing: existing),
  );
}

class _DevoteeForm extends StatefulWidget {
  const _DevoteeForm({this.existing});
  final Devotee? existing;

  @override
  State<_DevoteeForm> createState() => _DevoteeFormState();
}

class _DevoteeFormState extends State<_DevoteeForm> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final age = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.age}',
  );
  late final idNumber = TextEditingController(
    text: widget.existing?.idNumber ?? '',
  );
  late Gender gender = widget.existing?.gender ?? Gender.male;
  late String idType = widget.existing?.idType ?? idTypes.first;
  String? error;

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    idNumber.dispose();
    super.dispose();
  }

  void _save() {
    final a = int.tryParse(age.text.trim());
    if (name.text.trim().isEmpty) {
      return setState(
        () => error = 'Enter the name as printed on the photo ID.',
      );
    }
    if (a == null || a < 0 || a > 120) {
      return setState(() => error = 'Enter the age in years.');
    }
    final d = Devotee(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.text.trim(),
      age: a,
      gender: gender,
      idType: idType,
      idNumber: idNumber.text.trim(),
    );
    final problem = d.idProblem;
    if (problem != null) return setState(() => error = '$problem.');
    Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null ? 'ADD DEVOTEE' : 'EDIT DEVOTEE',
              style: l.label(),
            ),
            const SizedBox(height: 4),
            Text(
              'Type it exactly as on the photo ID. The name is checked at the queue.',
              style: TextStyle(color: l.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Name as on ID'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<Gender>(
                    showSelectedIcon: false,
                    segments: [
                      for (final g in Gender.values)
                        ButtonSegment(
                          value: g,
                          label: Text(g == Gender.other ? 'TG' : g.label),
                        ),
                    ],
                    selected: {gender},
                    onSelectionChanged: (s) => setState(() => gender = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: idType,
              decoration: const InputDecoration(labelText: 'Photo ID'),
              items: [
                for (final t in idTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => idType = v ?? idType),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: idNumber,
              textCapitalization: TextCapitalization.characters,
              keyboardType: idType == 'Aadhaar'
                  ? TextInputType.number
                  : TextInputType.text,
              style: const TextStyle(
                fontFeatures: Look.figures,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(labelText: '$idType number'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: l.warn)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
