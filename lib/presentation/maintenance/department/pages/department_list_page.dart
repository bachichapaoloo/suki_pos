import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/widgets/department_form_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

/// Page displaying the responsive list of departments.
class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({super.key});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DepartmentBloc>().add(GetDepartmentsEvent());
  }

  Future<void> _showFormDialog([Department? department]) async {
    final result = await showDialog<Department>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DepartmentFormDialog(department: department),
    );

    if (result != null && mounted) {
      context.read<DepartmentBloc>().add(SaveDepartmentEvent(result));
    }
  }

  Future<void> _confirmDelete(Department department) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Department',
      message: 'Are you sure you want to delete "${department.name}"?',
      confirmLabel: 'Delete',
      variant: DialogVariant.danger,
    );

    if (confirmed == true && mounted) {
      context.read<DepartmentBloc>().add(DeleteDepartmentEvent(department.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DepartmentBloc, DepartmentState>(
      listener: (context, state) {
        if (state is DepartmentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is DepartmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is DepartmentLoading;
        List<Department> departments = [];
        String? errorMessage;

        if (state is DepartmentLoaded) {
          departments = state.departments;
        } else if (state is DepartmentError) {
          errorMessage = state.message;
        }

        final filtered = departments.where((dept) {
          if (_searchQuery.isEmpty) return true;
          return dept.name.toLowerCase().contains(_searchQuery) || dept.code.toLowerCase().contains(_searchQuery);
        }).toList();

        return ResponsiveDataPage<Department>(
          title: 'Departments',
          parentHubTitle: 'Maintenance Hub',
          parentHubRoute: '/maintenance',
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search departments by name or code...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onAddNew: () => _showFormDialog(),
          onRefresh: () async {
            context.read<DepartmentBloc>().add(GetDepartmentsEvent());
          },
          columns: [
            ResponsiveTableColumn<Department>(
              title: 'DEPARTMENT NAME',
              flex: 3,
              cellBuilder: (dept) => Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dept.name,
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
            ResponsiveTableColumn<Department>(
              title: 'CODE',
              flex: 2,
              cellBuilder: (dept) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dept.code,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            ResponsiveTableColumn<Department>(
              title: 'STATUS',
              flex: 2,
              cellBuilder: (dept) => _buildStatusBadge(dept.isActive),
            ),
            ResponsiveTableColumn<Department>(
              title: 'ACTIONS',
              flex: 1,
              alignment: Alignment.centerRight,
              cellBuilder: (dept) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Edit',
                    onPressed: () => _showFormDialog(dept),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(dept),
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, dept) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5DDF1).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_outlined, color: Color(0xFF0369A1), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${dept.code}',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => _showFormDialog(dept),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(dept),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}
