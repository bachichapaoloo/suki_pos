import 'package:flutter/material.dart';
import '../../../../domain/entities/maintenance/item.dart';
import '../../../../domain/entities/maintenance/option_group.dart';
import '../../../../domain/entities/maintenance/option_value.dart';

class ItemModifierModalDialog extends StatefulWidget {
  final Item item;
  final List<OptionGroup> optionGroups;
  final Function(List<OptionValue> selectedOptions, String? notes) onConfirm;

  const ItemModifierModalDialog({
    super.key,
    required this.item,
    required this.optionGroups,
    required this.onConfirm,
  });

  @override
  State<ItemModifierModalDialog> createState() => _ItemModifierModalDialogState();
}

class _ItemModifierModalDialogState extends State<ItemModifierModalDialog> {
  final Map<int, List<OptionValue>> _selectedSelections = {};
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onOptionSelected(OptionGroup group, OptionValue val) {
    setState(() {
      final groupId = group.id!;
      if (group.selectionType == 0) {
        // Single Select (Radio)
        _selectedSelections[groupId] = [val];
      } else {
        // Multi Select (Checkbox)
        final current = _selectedSelections[groupId] ?? [];
        if (current.any((v) => v.id == val.id)) {
          current.removeWhere((v) => v.id == val.id);
        } else {
          current.add(val);
        }
        _selectedSelections[groupId] = current;
      }
    });
  }

  bool _validate() {
    for (final group in widget.optionGroups) {
      final selected = _selectedSelections[group.id!] ?? [];
      if (group.isRequired && selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an option for ${group.name}')),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelectedValues = _selectedSelections.values.expand((element) => element).toList();

    return AlertDialog(
      title: Text('Customize ${widget.item.name}'),
      content: SizedBox(
        width: 500,
        height: 450,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.optionGroups.length,
                itemBuilder: (context, index) {
                  final group = widget.optionGroups[index];
                  final selectedForGroup = _selectedSelections[group.id!] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(group.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            if (group.isRequired)
                              Text(
                                ' *',
                                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      ...group.values.map((val) {
                        final isSelected = selectedForGroup.any((v) => v.id == val.id);

                        return CheckboxListTile(
                          title: Text(val.alias ?? ''),
                          subtitle: val.priceDelta != 0 ? Text('+₱${val.priceDelta.toStringAsFixed(2)}') : null,
                          value: isSelected,
                          onChanged: (_) => _onOptionSelected(group, val),
                        );
                      }),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Item Special Instructions / Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_validate()) {
              widget.onConfirm(allSelectedValues, _notesController.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
