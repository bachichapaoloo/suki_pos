import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(GetUsersEvent());
  }

  Future<void> _showFormDialog([User? user]) async {
    final result = await showDialog<User>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserFormDialog(user: user),
    );

    if (result != null && mounted) {
      context.read<UserBloc>().add(SaveUserEvent(result));
    }
  }

  Future<void> _confirmDelete(User user) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete User',
      message: 'Are you sure you want to delete user "${user.name}"?',
      confirmLabel: 'Delete',
      variant: DialogVariant.danger,
    );

    if (confirmed == true && mounted) {
      context.read<UserBloc>().add(DeleteUserEvent(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is UserLoading;
        List<User> users = [];
        String? errorMessage;

        if (state is UserLoaded) {
          users = state.users;
        } else if (state is UserError) {
          errorMessage = state.message;
        }

        final filtered = users.where((u) {
          if (_searchQuery.isEmpty) return true;
          return u.name.toLowerCase().contains(_searchQuery) ||
              (u.roleName?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        return ResponsiveDataPage<User>(
          title: 'Users',
          parentHubTitle: 'Admin Hub',
          parentHubRoute: '/admin',
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search users by username or role...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onAddNew: () => _showFormDialog(),
          onRefresh: () async {
            context.read<UserBloc>().add(GetUsersEvent());
          },
          columns: [
            ResponsiveTableColumn<User>(
              title: 'USER',
              flex: 3,
              cellBuilder: (user) => Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF355C8F).withOpacity(0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF355C8F),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
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
            ResponsiveTableColumn<User>(
              title: 'ROLE',
              flex: 2,
              cellBuilder: (user) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.roleName ?? 'No Role',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ),
            ResponsiveTableColumn<User>(
              title: 'STATUS',
              flex: 2,
              cellBuilder: (user) => _buildStatusBadge(user.isActive),
            ),
            ResponsiveTableColumn<User>(
              title: 'ACTIONS',
              flex: 1,
              alignment: Alignment.centerRight,
              cellBuilder: (user) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Edit User',
                    onPressed: () => _showFormDialog(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete User',
                    onPressed: () => _confirmDelete(user),
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, user) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF355C8F).withOpacity(0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF355C8F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              user.roleName ?? 'No role',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(user.isActive),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => _showFormDialog(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(user),
                  ),
                ],
              ),
            );
          },
        );
      },
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

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});
  final User? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  int? _selectedRoleId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name);
    _passwordController = TextEditingController();
    _selectedRoleId = widget.user?.roleId;
    _isActive = widget.user?.isActive ?? true;

    context.read<RoleBloc>().add(GetRolesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit User' : 'New User',
      onSave: () {
        if (_formKey.currentState!.validate() && _selectedRoleId != null) {
          final user = (widget.user ?? const User(id: 0, roleId: 0, name: '', passwordHash: '')).copyWith(
            name: _nameController.text.trim(),
            roleId: _selectedRoleId!,
            passwordHash: _passwordController.text.isNotEmpty
                ? _passwordController.text
                : (widget.user?.passwordHash ?? ''),
            isActive: _isActive,
          );
          Navigator.pop(context, user);
        } else if (_selectedRoleId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a role')),
          );
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Username',
              controller: _nameController,
              hintText: 'e.g. cashier1',
              validator: (v) => v == null || v.isEmpty ? 'Username is required' : null,
            ),
            BlocBuilder<RoleBloc, RoleState>(
              builder: (context, state) {
                List<Role> roles = [];
                if (state is RoleLoaded) roles = state.roles;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Select Role',
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
                        items: roles.map((r) {
                          return DropdownMenuItem(value: r.id, child: Text(r.name));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedRoleId = v),
                        validator: (v) => v == null ? 'Role is required' : null,
                      ),
                    ],
                  ),
                );
              },
            ),
            CustomTextField(
              label: isEditing ? 'New Password (leave empty to keep current)' : 'Password',
              controller: _passwordController,
              obscureText: true,
              hintText: '••••••••',
              validator: (v) {
                if (!isEditing && (v == null || v.isEmpty)) return 'Password is required';
                return null;
              },
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
