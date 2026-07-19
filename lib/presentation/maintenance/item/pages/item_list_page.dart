import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/maintenance/item/widgets/item_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final Color _primaryBlue = const Color(0xFF355C8F);
  final Color _bgGrey = const Color(0xFFF7F8FA);
  String _selectedCategory = 'All Items';

  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(LoadItems());
  }

  Future<void> _showFormDialog([Item? item]) async {
    final result = await showDialog<Item>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ItemFormDialog(item: item),
    );

    if (result != null && mounted) {
      context.read<ItemBloc>().add(SaveItemEvent(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentTab: MainTab.inventory,
      mobileAppBar: AppBar(
        backgroundColor: _bgGrey,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF355C8F)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/maintenance'),
        ),
        title: Text(
          'Items',
          style: GoogleFonts.inter(
            color: _primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF355C8F)),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        elevation: 2,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      mobileBody: BlocConsumer<ItemBloc, ItemState>(
        listener: _blocListener,
        builder: (context, state) {
          return Column(
            children: [
              _buildSearchBarMobile(),
              _buildCategoryChips(),
              Expanded(
                child: _buildItemListMobile(state),
              ),
            ],
          );
        },
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
              'Items',
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
              onPressed: () => Navigator.of(context).pushReplacementNamed('/maintenance'),
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
          child: Column(
            children: [
              _buildDesktopToolbar(),
              const Divider(height: 1),
              Expanded(
                child: BlocConsumer<ItemBloc, ItemState>(
                  listener: _blocListener,
                  builder: (context, state) {
                    return _buildDesktopTable(state);
                  },
                ),
              ),
              const Divider(height: 1),
              _buildDesktopPagination(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search items, SKU, or barcode...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildDesktopFilterButton('All Categories', Icons.filter_list),
          const SizedBox(width: 12),
          _buildDesktopFilterButton('A-Z', Icons.sort),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterButton(String label, IconData icon) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(ItemState state) {
    if (state is ItemLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ItemLoaded) {
      if (state.items.isEmpty) {
        return Center(
          child: Text('No items found.', style: GoogleFonts.inter(color: Colors.grey[600])),
        );
      }
      return ListView.separated(
        itemCount: state.items.length + 1, // +1 for header
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          if (index == 0) return _buildDesktopTableHeader();
          final item = state.items[index - 1];
          return _buildDesktopTableRow(item);
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDesktopTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ITEM DETAILS', style: _headerStyle())),
          Expanded(flex: 2, child: Text('CATEGORY', style: _headerStyle())),
          Expanded(flex: 2, child: Text('PRICE', style: _headerStyle())),
          Expanded(flex: 2, child: Text('STOCK', style: _headerStyle())),
          SizedBox(
            width: 100,
            child: Text('ACTIONS', style: _headerStyle(), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.grey[600],
    letterSpacing: 1.2,
  );

  Widget _buildDesktopTableRow(Item item) {
    double price = 0.0;
    for (final p in item.prices) {
      if (p.priceLevel == 'default') {
        price = p.price;
        break;
      }
    }
    final defaultPrice = price;
    final inStock = 45; // Mocked
    final lowStock = item.name.contains('Matcha'); // Mocked for mockup exactness

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.displayImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(item.displayImage!), fit: BoxFit.cover),
                        )
                      : Icon(Icons.inventory_2_outlined, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.itemCode}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0E6F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Beverages', // Mocked category
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₱${defaultPrice.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: lowStock ? Colors.red : const Color(0xFF0369A1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lowStock ? '2 (Low)' : '$inStock',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: lowStock ? Colors.red : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                  onPressed: () => _showFormDialog(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () {
                    if (item.id != null) context.read<ItemBloc>().add(DeleteItemEvent(item.id!));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 1-3 of 42 items',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= COMMON METHODS & MOBILE HELPERS =================

  void _blocListener(BuildContext context, ItemState state) {
    if (state is ItemActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
    } else if (state is ItemError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Widget _buildSearchBarMobile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search items, SKU, or category...',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All Items', 'Beverages', 'Snacks', 'Essentials', 'Food'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) setState(() => _selectedCategory = category);
              },
              backgroundColor: const Color(0xFFEEEEEE),
              selectedColor: _primaryBlue,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemListMobile(ItemState state) {
    if (state is ItemLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ItemLoaded) {
      if (state.items.isEmpty) {
        return Center(
          child: Text('No items found.', style: GoogleFonts.inter(color: Colors.grey[600])),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.items.length,
        itemBuilder: (context, index) => _buildItemCardMobile(state.items[index]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildItemCardMobile(Item item) {
    double price = 0.0;
    for (final p in item.prices) {
      if (p.priceLevel == 'default') {
        price = p.price;
        break;
      }
    }
    final defaultPrice = price;
    final inStock = 48; // Mocked
    final lowStock = item.name.contains('Soap'); // Mocked

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: item.displayImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(item.displayImage!), fit: BoxFit.cover),
                    )
                  : Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF93C5FD).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CATEGORY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('SKU: ${item.itemCode}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (lowStock)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Low Stock: 3',
                          style: GoogleFonts.inter(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  else
                    Text(
                      'In Stock: $inStock',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF335481),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${defaultPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _primaryBlue),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Color(0xFF355C8F)),
                              title: const Text('Edit Item'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _showFormDialog(item);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Delete Item', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (item.id != null) context.read<ItemBloc>().add(DeleteItemEvent(item.id!));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Icon(Icons.more_horiz, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        currentIndex: 2,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Sales'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
            ),
            label: 'Inventory',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
