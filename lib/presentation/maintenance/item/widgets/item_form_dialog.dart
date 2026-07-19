import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/maintenance/item.dart';
import '../../../../domain/entities/maintenance/item_price.dart';
import '../bloc/item_bloc.dart';
import '../bloc/item_event.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item; // Null if creating new, populated if editing

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _printNameController;
  late TextEditingController _costPriceController;
  late TextEditingController _defaultPriceController;

  // Hardcoded for now, but these should eventually come from Dropdowns mapped to your Department/Category tables
  int _selectedCategoryId = 1;
  int _selectedDepartmentId = 1;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.item?.itemCode ?? '');
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _printNameController = TextEditingController(text: widget.item?.printName ?? '');
    _costPriceController = TextEditingController(text: widget.item?.costPrice.toString() ?? '0.0');

    // Extract the default price from the array if editing
    double price = 0.0;
    if (widget.item != null) {
      for (final p in widget.item!.prices) {
        if (p.priceLevel == 'default') {
          price = p.price;
          break;
        }
      }
    }
    final defaultPrice = price.toString();
    _defaultPriceController = TextEditingController(text: defaultPrice);

    if (widget.item != null) {
      _selectedCategoryId = widget.item!.categoryId;
      _selectedDepartmentId = widget.item!.departmentId;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _printNameController.dispose();
    _costPriceController.dispose();
    _defaultPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // 1. Package the price into our new Aggregate structure
      final prices = [
        ItemPrice(
          priceLevel: 'default',
          price: double.tryParse(_defaultPriceController.text) ?? 0.0,
        ),
      ];

      // 2. Build the Item entity
      final newItem = Item(
        id: widget.item?.id,
        itemCode: _codeController.text,
        name: _nameController.text,
        printName: _printNameController.text,
        categoryId: _selectedCategoryId,
        departmentId: _selectedDepartmentId,
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        isActive: true,
        prices: prices, // Pass the array here
      );

      // 3. Dispatch to BLoC
      context.read<ItemBloc>().add(SaveItemEvent(newItem));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'New Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Item Code / SKU'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onChanged: (val) {
                  // Auto-fill print name if empty
                  if (_printNameController.text.isEmpty ||
                      _printNameController.text == val.substring(0, val.length - 1)) {
                    _printNameController.text = val;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _printNameController,
                decoration: const InputDecoration(labelText: 'Receipt Print Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(labelText: 'Cost Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _defaultPriceController,
                      decoration: const InputDecoration(labelText: 'Selling Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

