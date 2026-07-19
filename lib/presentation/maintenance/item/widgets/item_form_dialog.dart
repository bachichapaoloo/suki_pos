import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/item_price.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // General Controllers
  late TextEditingController _codeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _printNameCtrl;
  late TextEditingController _detailsCtrl;

  // Pricing & Stock Controllers
  late TextEditingController _costPriceCtrl;
  late TextEditingController _defaultPriceCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _maxStockCtrl;

  // Dropdowns State
  int? _selectedCategoryId;
  int? _selectedDepartmentId;
  List<Category> _categories = [];
  List<Department> _departments = [];

  // Image State
  String? _displayImage;

  // Boolean Flags
  late bool _isVatExempt;
  late bool _isDiscountExempt;
  late bool _isFinishedGood;
  late bool _isRawMaterial;

  @override
  void initState() {
    super.initState();
    final i = widget.item;

    _codeCtrl = TextEditingController(text: i?.itemCode ?? '');
    _barcodeCtrl = TextEditingController(text: i?.barcode ?? '');
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _printNameCtrl = TextEditingController(text: i?.printName ?? '');
    _detailsCtrl = TextEditingController(text: i?.itemDetails ?? '');

    _costPriceCtrl = TextEditingController(text: i?.costPrice.toString() ?? '0.0');
    _minStockCtrl = TextEditingController(text: i?.minStockLevel.toString() ?? '0.0');
    _maxStockCtrl = TextEditingController(text: i?.maxStockLevel.toString() ?? '0.0');

    double price = 0.0;
    if (i != null) {
      for (final p in i.prices) {
        if (p.priceLevel == 'default') {
          price = p.price;
          break;
        }
      }
    }
    final defaultPrice = price.toString();
    _defaultPriceCtrl = TextEditingController(text: defaultPrice);

    _isVatExempt = i?.isVatExempt ?? false;
    _isDiscountExempt = i?.isDiscountExempt ?? false;
    _isFinishedGood = i?.isFinishedGood ?? true;
    _isRawMaterial = i?.isRawMaterial ?? false;

    if (i != null) {
      _selectedCategoryId = i.categoryId;
      _selectedDepartmentId = i.departmentId;
      _displayImage = i.displayImage;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final getCategories = sl<GetCategories>();
    final getDepartments = sl<GetDepartments>();

    final catResult = await getCategories(NoParams());
    final depResult = await getDepartments(NoParams());

    if (mounted) {
      setState(() {
        catResult.fold((l) => null, (r) => _categories = r);
        depResult.fold((l) => null, (r) => _departments = r);

        // Auto-select first if not set
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
        if (_selectedDepartmentId == null && _departments.isNotEmpty) {
          _selectedDepartmentId = _departments.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _printNameCtrl.dispose();
    _detailsCtrl.dispose();
    _costPriceCtrl.dispose();
    _defaultPriceCtrl.dispose();
    _minStockCtrl.dispose();
    _maxStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _displayImage = pickedFile.path;
      });
    }
  }

  void _onCategoryChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedCategoryId = value;
      });
    }
  }

  void _onDepartmentChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedDepartmentId = value;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final prices = [
        ItemPrice(
          priceLevel: 'default',
          price: double.tryParse(_defaultPriceCtrl.text) ?? 0.0,
        ),
      ];

      final newItem = Item(
        id: widget.item?.id,
        itemCode: _codeCtrl.text,
        barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
        name: _nameCtrl.text,
        printName: _printNameCtrl.text,
        itemDetails: _detailsCtrl.text,
        categoryId: _selectedCategoryId ?? 0,
        departmentId: _selectedDepartmentId ?? 0,
        displayImage: _displayImage,
        costPrice: double.tryParse(_costPriceCtrl.text) ?? 0.0,
        minStockLevel: double.tryParse(_minStockCtrl.text) ?? 0.0,
        maxStockLevel: double.tryParse(_maxStockCtrl.text) ?? 0.0,
        isVatExempt: _isVatExempt,
        isDiscountExempt: _isDiscountExempt,
        isFinishedGood: _isFinishedGood,
        isRawMaterial: _isRawMaterial,
        isActive: true,
        prices: prices,
      );

      context.read<ItemBloc>().add(SaveItemEvent(newItem));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: CustomFormDialog(
        title: widget.item == null ? 'Create New Item' : 'Edit Item',
        maxWidth: 700,
        saveLabel: 'Save Item',
        onSave: _submit,
        content: SizedBox(
          height: 500,
          child: Column(
            children: [
              TabBar(
                labelColor: const Color(0xFF355C8F),
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: const Color(0xFF355C8F),
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Basic Info'),
                  Tab(icon: Icon(Icons.attach_money), text: 'Pricing & Stock'),
                  Tab(icon: Icon(Icons.settings), text: 'Settings'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      // TAB 1: BASIC INFO
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Item Code (Required)*',
                                  controller: _codeCtrl,
                                  validator: (val) => val!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Barcode (Optional)',
                                  controller: _barcodeCtrl,
                                ),
                              ),
                            ],
                          ),
                          CustomTextField(
                            label: 'Full Item Name*',
                            controller: _nameCtrl,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                            onFieldSubmitted: (_) {}, // just to pass the param if needed
                          ),
                          CustomTextField(
                            label: 'Receipt Print Name',
                            controller: _printNameCtrl,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Department',
                                  value: _selectedDepartmentId,
                                  items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                  onChanged: _onDepartmentChanged,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Category',
                                  value: _selectedCategoryId,
                                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                  onChanged: _onCategoryChanged,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_displayImage != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_displayImage!),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 72),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  icon: Icon(Icons.image, color: Colors.grey[600]),
                                  label: Text(
                                    _displayImage == null ? 'Upload Image' : 'Change Image',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF1E293B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // TAB 2: PRICING & STOCK
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Cost Price',
                                  controller: _costPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixText: '₱ ',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Selling Price*',
                                  controller: _defaultPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  prefixText: '₱ ',
                                  validator: (val) => val!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 48, color: Color(0xFFE2E8F0)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Min Stock Alert Level',
                                  controller: _minStockCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Max Stock Level',
                                  controller: _maxStockCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // TAB 3: SETTINGS / FLAGS
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          _buildSwitch(
                            title: 'VAT Exempt',
                            subtitle: 'Do not charge VAT on this item.',
                            value: _isVatExempt,
                            onChanged: (val) => setState(() => _isVatExempt = val),
                          ),
                          _buildSwitch(
                            title: 'Discount Exempt',
                            subtitle: 'Prevent PWD/Senior discounts from applying.',
                            value: _isDiscountExempt,
                            onChanged: (val) => setState(() => _isDiscountExempt = val),
                          ),
                          const Divider(height: 32, color: Color(0xFFE2E8F0)),
                          _buildSwitch(
                            title: 'Finished Good',
                            subtitle: 'This item is sold directly to customers.',
                            value: _isFinishedGood,
                            onChanged: (val) => setState(() => _isFinishedGood = val),
                          ),
                          _buildSwitch(
                            title: 'Raw Material',
                            subtitle: 'Used as an ingredient in other recipes.',
                            value: _isRawMaterial,
                            onChanged: (val) => setState(() => _isRawMaterial = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Select $label',
              hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF355C8F), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
            ),
            items: items,
            onChanged: onChanged,
            validator: (val) => val == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF7F8FA),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        value: value,
        activeColor: const Color(0xFF355C8F),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
