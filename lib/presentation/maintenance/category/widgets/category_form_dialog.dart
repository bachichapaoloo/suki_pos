import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.category});
  final Category? category;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _displayOrderController;
  int? _selectedDepartmentId;
  late bool _isAvailableOnline;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _codeController = TextEditingController(text: widget.category?.code);
    _displayOrderController = TextEditingController(
      text: widget.category?.displayOrder.toString() ?? '0',
    );
    _selectedDepartmentId = widget.category?.departmentId;
    _isAvailableOnline = widget.category?.isAvailableOnline ?? true;
    _isActive = widget.category?.isActive ?? true;

    // Ensure departments are loaded for the dropdown
    context.read<DepartmentBloc>().add(GetDepartmentsEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Category' : 'New Category',
      onSave: () {
        if (_formKey.currentState!.validate() &&
            _selectedDepartmentId != null) {
          final category = Category(
            id: widget.category?.id ?? 0,
            departmentId: _selectedDepartmentId!,
            name: _nameController.text.trim(),
            code: _codeController.text.trim().isEmpty
                ? null
                : _codeController.text.trim(),
            displayOrder: int.tryParse(_displayOrderController.text) ?? 0,
            isAvailableOnline: _isAvailableOnline,
            isActive: _isActive,
          );
          Navigator.pop(context, category);
        } else if (_selectedDepartmentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a department')),
          );
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<DepartmentBloc, DepartmentState>(
              builder: (context, state) {
                List<Department> departments = [];
                if (state is DepartmentLoaded) {
                  departments = state.departments;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedDepartmentId,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
                        style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Select Department',
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
                        items: departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.id,
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedDepartmentId = value),
                        validator: (value) => value == null ? 'Department is required' : null,
                      ),
                    ],
                  ),
                );
              },
            ),
            CustomTextField(
              label: 'Category Name',
              controller: _nameController,
              hintText: 'e.g. Soft Drinks',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Name is required' : null,
            ),
            CustomTextField(
              label: 'Category Code',
              controller: _codeController,
              hintText: 'e.g. CAT001',
            ),
            CustomTextField(
              label: 'Display Order',
              controller: _displayOrderController,
              keyboardType: TextInputType.number,
              hintText: '0',
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF7F8FA),
              ),
              child: SwitchListTile(
                title: Text(
                  'Available Online',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                value: _isAvailableOnline,
                activeColor: const Color(0xFF355C8F),
                onChanged: (value) => setState(() => _isAvailableOnline = value),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF7F8FA),
              ),
              child: SwitchListTile(
                title: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                value: _isActive,
                activeColor: const Color(0xFF355C8F),
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
