import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/widgets/department_form_dialog.dart';

/// Page displaying the list of departments.
class DepartmentListPage extends StatefulWidget {
  /// Creates a [DepartmentListPage].
  const DepartmentListPage({super.key});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: BlocConsumer<DepartmentBloc, DepartmentState>(
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
          if (state is DepartmentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DepartmentLoaded) {
            if (state.departments.isEmpty) {
              return const Center(child: Text('No departments found.'));
            }
            return ListView.separated(
              itemCount: state.departments.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final dept = state.departments[index];
                return ListTile(
                  title: Text(
                    dept.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(dept.code),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showFormDialog(dept),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<DepartmentBloc>().add(
                            DeleteDepartmentEvent(dept.id),
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
