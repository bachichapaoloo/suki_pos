import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: BlocConsumer<UserBloc, UserState>(
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
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }
            return ListView.separated(
              itemCount: state.users.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = state.users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(
                    user.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Role: ${user.roleName ?? 'Unknown'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showFormDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<UserBloc>().add(
                            DeleteUserEvent(user.id),
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
    _passwordController =
        TextEditingController(); // Password not loaded from DB for security
    _selectedRoleId = widget.user?.roleId;
    _isActive = widget.user?.isActive ?? true;

    // Load roles for the dropdown
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
          final user =
              (widget.user ??
                      const User(id: 0, roleId: 0, name: '', passwordHash: ''))
                  .copyWith(
                    name: _nameController.text.trim(),
                    roleId: _selectedRoleId!,
                    // In a real app, hash this!
                    passwordHash: _passwordController.text.isNotEmpty
                        ? _passwordController.text
                        : (widget.user?.passwordHash ?? ''),
                    isActive: _isActive,
                  );
          Navigator.pop(context, user);
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Username',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            BlocBuilder<RoleBloc, RoleState>(
              builder: (context, state) {
                List<Role> roles = [];
                if (state is RoleLoaded) roles = state.roles;

                return DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: roles.map((r) {
                    return DropdownMenuItem(value: r.id, child: Text(r.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedRoleId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: isEditing
                  ? 'New Password (leave empty to keep current)'
                  : 'Password',
              controller: _passwordController,
              obscureText: true,
              validator: (v) {
                if (!isEditing && (v == null || v.isEmpty)) return 'Required';
                return null;
              },
            ),
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
