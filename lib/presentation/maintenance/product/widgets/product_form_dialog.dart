import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _itemCodeController;
  late TextEditingController _barcodeController;
  late TextEditingController _printNameController;
  late TextEditingController _costPriceController;
  int? _selectedDepartmentId;
  int? _selectedCategoryId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _itemCodeController = TextEditingController(text: widget.product?.itemCode);
    _barcodeController = TextEditingController(text: widget.product?.barcode);
    _printNameController = TextEditingController(
      text: widget.product?.printName,
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toString() ?? '0',
    );
    _selectedDepartmentId = widget.product?.departmentId;
    _selectedCategoryId = widget.product?.categoryId;
    _isActive = widget.product?.isActive ?? true;

    context.read<DepartmentBloc>().add(GetDepartmentsEvent());
    context.read<CategoryBloc>().add(GetCategoriesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemCodeController.dispose();
    _barcodeController.dispose();
    _printNameController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Product' : 'New Product',
      maxWidth: 600,
      onSave: () {
        if (_formKey.currentState!.validate() &&
            _selectedDepartmentId != null &&
            _selectedCategoryId != null) {
          final product =
              (widget.product ??
                      Product(
                        id: 0,
                        itemCode: '',
                        name: '',
                        printName: '',
                        categoryId: 0,
                        departmentId: 0,
                      ))
                  .copyWith(
                    id: widget.product?.id ?? 0,
                    name: _nameController.text.trim(),
                    itemCode: _itemCodeController.text.trim(),
                    barcode: _barcodeController.text.trim(),
                    printName: _printNameController.text.trim(),
                    costPrice: double.tryParse(_costPriceController.text) ?? 0,
                    departmentId: _selectedDepartmentId!,
                    categoryId: _selectedCategoryId!,
                    isActive: _isActive,
                  );
          Navigator.pop(context, product);
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<DepartmentBloc, DepartmentState>(
                    builder: (context, state) {
                      List<Department> items = [];
                      if (state is DepartmentLoaded) items = state.departments;
                      return DropdownButtonFormField<int>(
                        value: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        items: items.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                            _selectedCategoryId = null; // Reset category
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      List<Category> items = [];
                      if (state is CategoryLoaded) {
                        items = state.categories
                            .where(
                              (c) => c.departmentId == _selectedDepartmentId,
                            )
                            .toList();
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: items.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategoryId = value),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Product Name',
              controller: _nameController,
              onFieldSubmitted: (v) {
                if (_printNameController.text.isEmpty) {
                  _printNameController.text = v;
                }
              },
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            CustomTextField(
              label: 'Print Name (Receipt)',
              controller: _printNameController,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Item Code',
                    controller: _itemCodeController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Barcode',
                    controller: _barcodeController,
                  ),
                ),
              ],
            ),
            CustomTextField(
              label: 'Cost Price',
              controller: _costPriceController,
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
