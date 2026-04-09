import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoleBloc>().add(GetRolesEvent());
  }

  Future<void> _showFormDialog([Role? role]) async {
    final result = await showDialog<Role>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoleFormDialog(role: role),
    );

    if (result != null && mounted) {
      context.read<RoleBloc>().add(SaveRoleEvent(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: BlocConsumer<RoleBloc, RoleState>(
        listener: (context, state) {
          if (state is RoleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is RoleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RoleLoaded) {
            if (state.roles.isEmpty) {
              return const Center(child: Text('No roles found.'));
            }
            return ListView.separated(
              itemCount: state.roles.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final role = state.roles[index];
                return ListTile(
                  title: Text(
                    role.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showFormDialog(role),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<RoleBloc>().add(
                            DeleteRoleEvent(role.id),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class RoleFormDialog extends StatefulWidget {
  const RoleFormDialog({super.key, this.role});
  final Role? role;

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late Map<String, bool> _permissions;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name);
    _isActive = widget.role?.isActive ?? true;
    _permissions = {
      'Sales Entry': widget.role?.canSalesEntry ?? false,
      'Sales Order': widget.role?.canSalesOrder ?? false,
      'Sales Reading': widget.role?.canSalesReading ?? false,
      'Sales Inquiry': widget.role?.canSalesInquiry ?? false,
      'Maintenance': widget.role?.canFileMaintenance ?? false,
      'Admin Mode': widget.role?.canAdminMode ?? false,
      'Inventory': widget.role?.canInventory ?? false,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormDialog(
      title: widget.role == null ? 'New Role' : 'Edit Role',
      maxWidth: 600,
      onSave: () {
        if (_formKey.currentState!.validate()) {
          final role = (widget.role ?? const Role(id: 0, name: '')).copyWith(
            name: _nameController.text.trim(),
            canSalesEntry: _permissions['Sales Entry'],
            canSalesOrder: _permissions['Sales Order'],
            canSalesReading: _permissions['Sales Reading'],
            canSalesInquiry: _permissions['Sales Inquiry'],
            canFileMaintenance: _permissions['Maintenance'],
            canAdminMode: _permissions['Admin Mode'],
            canInventory: _permissions['Inventory'],
            isActive: _isActive,
          );
          Navigator.pop(context, role);
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Role Name',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Permissions',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(),
            ..._permissions.keys.map((key) {
              return CheckboxListTile(
                title: Text(key, style: GoogleFonts.poppins()),
                value: _permissions[key],
                onChanged: (v) =>
                    setState(() => _permissions[key] = v ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
