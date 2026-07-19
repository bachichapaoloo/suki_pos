import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/widgets/category_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(GetCategoriesEvent());
  }

  Future<void> _showFormDialog([Category? category]) async {
    final result = await showDialog<Category>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(category: category),
    );

    if (result != null && mounted) {
      context.read<CategoryBloc>().add(SaveCategoryEvent(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentTab: MainTab.inventory,
      mobileAppBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      desktopHeader: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Breadcrumb
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pushReplacementNamed('/maintenance'),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, size: 20, color: Color(0xFF355C8F)),
                      const SizedBox(width: 8),
                      Text(
                        'Maintenance Hub',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF355C8F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                const SizedBox(width: 16),
              ],
            ),
            Text(
              'Categories',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showFormDialog(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF355C8F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              icon: const Icon(Icons.logout, color: Colors.grey),
            ),
          ],
        ),
      ),
      desktopBody: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: _buildBodyContent(),
        ),
      ),
      mobileBody: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    return BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategorySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoryLoaded) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('No categories found.'));
            }
            return ListView.separated(
              itemCount: state.categories.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return ListTile(
                  title: Text(
                    category.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(category.code ?? 'No Code'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showFormDialog(category),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<CategoryBloc>().add(
                            DeleteCategoryEvent(category.id),
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
      );
  }
}
