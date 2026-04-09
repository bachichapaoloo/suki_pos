import 'package:flutter/material.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

/// Dialog for adding or editing a department.
class DepartmentFormDialog extends StatefulWidget {
  /// Creates a [DepartmentFormDialog].
  const DepartmentFormDialog({super.key, this.department});

  /// The department to edit, or null if creating a new one.
  final Department? department;

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.department?.code);
    _nameController = TextEditingController(text: widget.department?.name);
    _isActive = widget.department?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.department != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Department' : 'New Department',
      onSave: () {
        if (_formKey.currentState!.validate()) {
          final department = Department(
            id: widget.department?.id ?? 0,
            code: _codeController.text.trim(),
            name: _nameController.text.trim(),
            isActive: _isActive,
          );
          Navigator.pop(context, department);
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Department Code',
              controller: _codeController,
              hintText: 'e.g. DEPT001',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a code';
                }
                return null;
              },
            ),
            CustomTextField(
              label: 'Department Name',
              controller: _nameController,
              hintText: 'e.g. Beverages',
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
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
