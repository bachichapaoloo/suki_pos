import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/widgets/category_form_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  String _searchQuery = '';

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

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete "${category.name}"?',
      confirmLabel: 'Delete',
      variant: DialogVariant.danger,
    );

    if (confirmed == true && mounted) {
      context.read<CategoryBloc>().add(DeleteCategoryEvent(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategorySuccess) {
          AppToast.showSuccess(context, message: state.message);
        } else if (state is CategoryError) {
          AppToast.showError(context, message: state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is CategoryLoading;
        List<Category> categories = [];
        String? errorMessage;

        if (state is CategoryLoaded) {
          categories = state.categories;
        } else if (state is CategoryError) {
          errorMessage = state.message;
        }

        final filtered = categories.where((cat) {
          if (_searchQuery.isEmpty) return true;
          return cat.name.toLowerCase().contains(_searchQuery) ||
              (cat.code?.toLowerCase().contains(_searchQuery) ?? false) ||
              (cat.name?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        return ResponsiveDataPage<Category>(
          title: 'Categories',
          parentHubTitle: 'Maintenance Hub',
          parentHubRoute: '/maintenance',
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search categories by name, code or department...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onAddNew: () => _showFormDialog(),
          onRefresh: () async {
            context.read<CategoryBloc>().add(GetCategoriesEvent());
          },
          columns: [
            ResponsiveTableColumn<Category>(
              title: 'CATEGORY NAME',
              flex: 3,
              cellBuilder: (cat) => Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF355C8F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF355C8F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
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
            ResponsiveTableColumn<Category>(
              title: 'CODE',
              flex: 2,
              cellBuilder: (cat) => Text(
                cat.code?.isNotEmpty == true ? cat.code! : '—',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ResponsiveTableColumn<Category>(
              title: 'DEPARTMENT',
              flex: 2,
              cellBuilder: (cat) => Text(
                cat.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            ResponsiveTableColumn<Category>(
              title: 'STATUS',
              flex: 2,
              cellBuilder: (cat) => _buildStatusBadge(cat.isActive),
            ),
            ResponsiveTableColumn<Category>(
              title: 'ACTIONS',
              flex: 1,
              alignment: Alignment.centerRight,
              cellBuilder: (cat) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Edit',
                    onPressed: () => _showFormDialog(cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(cat),
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, cat) {
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
                      color: const Color(0xFF355C8F).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Color(0xFF355C8F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
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
                              cat.code ?? 'No code',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                            ...[
                              Text(' • ', style: GoogleFonts.inter(color: Colors.grey)),
                              Text(
                                cat.name!,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => _showFormDialog(cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(cat),
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
