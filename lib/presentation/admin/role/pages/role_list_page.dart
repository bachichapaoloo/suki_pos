import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  String _searchQuery = '';

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

  Future<void> _confirmDelete(Role role) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Role',
      message: 'Are you sure you want to delete role "${role.name}"?',
      confirmLabel: 'Delete',
      variant: DialogVariant.danger,
    );

    if (confirmed == true && mounted) {
      context.read<RoleBloc>().add(DeleteRoleEvent(role.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoleBloc, RoleState>(
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
        final isLoading = state is RoleLoading;
        List<Role> roles = [];
        String? errorMessage;

        if (state is RoleLoaded) {
          roles = state.roles;
        } else if (state is RoleError) {
          errorMessage = state.message;
        }

        final filtered = roles.where((r) {
          if (_searchQuery.isEmpty) return true;
          return r.name.toLowerCase().contains(_searchQuery);
        }).toList();

        return ResponsiveDataPage<Role>(
          title: 'Roles & Permissions',
          parentHubTitle: 'Admin Hub',
          parentHubRoute: '/admin',
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search roles...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onAddNew: () => _showFormDialog(),
          onRefresh: () async {
            context.read<RoleBloc>().add(GetRolesEvent());
          },
          columns: [
            ResponsiveTableColumn<Role>(
              title: 'ROLE NAME',
              flex: 3,
              cellBuilder: (role) => Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security_rounded, size: 20, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      role.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveTableColumn<Role>(
              title: 'PERMISSIONS',
              flex: 4,
              cellBuilder: (role) => _buildPermissionBadges(role),
            ),
            ResponsiveTableColumn<Role>(
              title: 'STATUS',
              flex: 2,
              cellBuilder: (role) => _buildStatusBadge(role.isActive),
            ),
            ResponsiveTableColumn<Role>(
              title: 'ACTIONS',
              flex: 1,
              alignment: Alignment.centerRight,
              cellBuilder: (role) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Edit Role',
                    onPressed: () => _showFormDialog(role),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete Role',
                    onPressed: () => _confirmDelete(role),
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, role) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          role.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      _buildStatusBadge(role.isActive),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => _showFormDialog(role),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(role),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPermissionBadges(role),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPermissionBadges(Role role) {
    final permissions = <String>[];
    if (role.canSalesEntry == true) permissions.add('Sales');
    if (role.canSalesOrder == true) permissions.add('Order');
    if (role.canSalesReading == true) permissions.add('Reading');
    if (role.canSalesInquiry == true) permissions.add('Inquiry');
    if (role.canFileMaintenance == true) permissions.add('Maintenance');
    if (role.canAdminMode == true) permissions.add('Admin');
    if (role.canInventory == true) permissions.add('Inventory');

    if (permissions.isEmpty) {
      return Text('No permissions', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: permissions.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            p,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
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
      maxWidth: 560,
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
              hintText: 'e.g. Supervisor',
              validator: (v) => v == null || v.isEmpty ? 'Role name is required' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Permissions',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select modules and features accessible to this role',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF8FAFC),
              ),
              child: Column(
                children: _permissions.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(
                      key,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    value: _permissions[key],
                    activeColor: const Color(0xFF355C8F),
                    onChanged: (v) => setState(() => _permissions[key] = v ?? false),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
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
                onChanged: (v) => setState(() => _isActive = v),
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
