import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/maintenance/option_group.dart';
import '../../../../domain/entities/maintenance/option_value.dart';
import '../bloc/option_group_cubit.dart';

class OptionGroupFormDialog extends StatefulWidget {
  final OptionGroup? group;

  const OptionGroupFormDialog({super.key, this.group});

  @override
  State<OptionGroupFormDialog> createState() => _OptionGroupFormDialogState();
}

class _OptionGroupFormDialogState extends State<OptionGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late bool _isRequired;
  late int _selectionType; // 0 = Single (Radio), 1 = Multiple (Checkbox)

  final List<_ValueEntry> _valueEntries = [];

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _isRequired = g?.isRequired ?? false;
    _selectionType = g?.selectionType ?? 0;

    if (g != null && g.values.isNotEmpty) {
      for (final v in g.values) {
        _valueEntries.add(
          _ValueEntry(
            id: v.id,
            aliasCtrl: TextEditingController(text: v.alias ?? ''),
            priceDeltaCtrl: TextEditingController(text: v.priceDelta.toString()),
          ),
        );
      }
    } else {
      _addEmptyValueRow();
    }
  }

  void _addEmptyValueRow() {
    setState(() {
      _valueEntries.add(
        _ValueEntry(
          aliasCtrl: TextEditingController(),
          priceDeltaCtrl: TextEditingController(text: '0.0'),
        ),
      );
    });
  }

  void _removeValueRow(int index) {
    if (_valueEntries.length > 1) {
      setState(() {
        _valueEntries[index].dispose();
        _valueEntries.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var e in _valueEntries) {
      e.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final values = _valueEntries.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return OptionValue(
          id: item.id,
          optionGroupId: widget.group?.id ?? 0,
          alias: item.aliasCtrl.text.trim(),
          priceDelta: double.tryParse(item.priceDeltaCtrl.text) ?? 0.0,
          displayOrder: idx,
        );
      }).toList();

      final newGroup = OptionGroup(
        id: widget.group?.id,
        name: _nameCtrl.text.trim(),
        isRequired: _isRequired,
        selectionType: _selectionType,
        values: values,
      );

      context.read<OptionGroupCubit>().saveGroup(newGroup);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.group == null ? 'Create Modifier Group' : 'Edit Modifier Group'),
      content: SizedBox(
        width: 600,
        height: 520,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group Name* (e.g., Size, Choice of Drink)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Mandatory Selection'),
                      subtitle: const Text('Cashier must pick an option'),
                      value: _isRequired,
                      onChanged: (val) => setState(() => _isRequired = val),
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Single (Radio)')),
                        ButtonSegment(value: 1, label: Text('Multi (Checkbox)')),
                      ],
                      selected: {_selectionType},
                      onSelectionChanged: (set) => setState(() => _selectionType = set.first),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Option Choices & Pricing',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addEmptyValueRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _valueEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _valueEntries[index];
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: item.aliasCtrl,
                            decoration: InputDecoration(
                              labelText: 'Choice Label* (e.g. Large)',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: item.priceDeltaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Price (+/-)',
                              prefixText: '₱ ',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                          onPressed: () => _removeValueRow(index),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save Modifier Group'),
        ),
      ],
    );
  }
}

class _ValueEntry {
  final int? id;
  final TextEditingController aliasCtrl;
  final TextEditingController priceDeltaCtrl;

  _ValueEntry({
    this.id,
    required this.aliasCtrl,
    required this.priceDeltaCtrl,
  });

  void dispose() {
    aliasCtrl.dispose();
    priceDeltaCtrl.dispose();
  }
}
