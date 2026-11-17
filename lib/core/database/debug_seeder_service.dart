import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/core/utils/crypto_utils.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';
import 'package:suki_pos/data/models/maintenance/item_price_model.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/pos/tender_payment_leg.dart';

/// Summary of records seeded or reset by [DebugSeederService].
class DebugSeedSummary {
  final int departments;
  final int categories;
  final int items;
  final int discounts;
  final int stocks;
  final int giftCheckSerials;
  final bool transactionsCleared;

  const DebugSeedSummary({
    required this.departments,
    required this.categories,
    required this.items,
    required this.discounts,
    required this.stocks,
    required this.giftCheckSerials,
    this.transactionsCleared = false,
  });
}

/// Provides a comprehensive, idempotent debug seeder for manually testing and
/// verifying all SukiPOS features (Sales Entry, 6-Tender + Split Payments,
/// Discounts, VAT/Discount Exemptions, Modifiers, Recipe COGS `sales_m3`,
/// Inventory Stocks, Low-Stock Alerts, Cash Fund In/Out, Tender Declaration,
/// X-Reading, and Z-Reading).
class DebugSeederService {
  final DatabaseHelper _databaseHelper;

  DebugSeederService(this._databaseHelper);

  /// Updates an existing row by `id` (without triggering `ON DELETE RESTRICT`
  /// foreign key errors that `INSERT OR REPLACE` causes) or inserts a new row.
  Future<void> _upsertById(
    Transaction txn,
    String table,
    Map<String, Object?> values,
  ) async {
    final id = values['id'];
    if (id != null) {
      final updated = await txn.update(
        table,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated > 0) return;
    }
    await txn.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Automatically seeds the demo catalog on app startup if the `item` table is empty.
  Future<bool> seedIfCatalogEmpty() async {
    final db = await _databaseHelper.database;
    final itemCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${SchemaConstants.item}'),
        ) ??
        0;
    if (itemCount == 0) {
      await seedDemoCatalog();
      return true;
    }
    return false;
  }

  /// Idempotently seeds or tops up the master catalog, discounts, payment masters,
  /// modifiers, recipe compositions, and stock quantities without deleting existing
  /// sales transactions or shift records.
  Future<DebugSeedSummary> seedDemoCatalog() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Roles & Test Users (Superuser PIN: 050724, Cashier Juan PIN: 123456, Cashier Maria PIN: 654321)
      await txn.execute('''
        INSERT OR IGNORE INTO ${SchemaConstants.role}
          (id, name, can_sales_entry, can_sales_order, can_sales_reading, can_sales_inquiry, can_file_maintenance, can_admin_mode, can_dtr_menu, can_kiosk, can_inventory, is_active)
        VALUES
          (1, 'Superuser', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
          (2, 'Cashier',   1, 1, 1, 1, 0, 0, 1, 0, 0, 1);
      ''');

      await txn.insert(
        SchemaConstants.appUser,
        {
          'id': 1,
          'role_id': 1,
          'name': 'Superuser',
          'password_hash': CryptoUtils.hashPin('050724'),
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await _upsertById(txn, SchemaConstants.appUser, {
        'id': 2,
        'role_id': 2,
        'name': 'Cashier Juan',
        'password_hash': CryptoUtils.hashPin('123456'),
        'is_active': 1,
        'updated_at': now,
      });
      await _upsertById(txn, SchemaConstants.appUser, {
        'id': 3,
        'role_id': 2,
        'name': 'Cashier Maria',
        'password_hash': CryptoUtils.hashPin('654321'),
        'is_active': 1,
        'updated_at': now,
      });

      // 2. Units & Suppliers
      final units = [
        {'id': 1, 'name': 'Piece', 'abbreviation': 'pc', 'unit_value': 1.0, 'base_unit': 'pc'},
        {'id': 2, 'name': 'Bowl', 'abbreviation': 'bwl', 'unit_value': 1.0, 'base_unit': 'bwl'},
        {'id': 3, 'name': 'Cup', 'abbreviation': 'cup', 'unit_value': 1.0, 'base_unit': 'cup'},
        {'id': 4, 'name': 'Pack', 'abbreviation': 'pck', 'unit_value': 1.0, 'base_unit': 'pck'},
        {'id': 5, 'name': 'Bottle', 'abbreviation': 'btl', 'unit_value': 1.0, 'base_unit': 'btl'},
        {'id': 6, 'name': 'Kilogram', 'abbreviation': 'kg', 'unit_value': 1000.0, 'base_unit': 'g'},
      ];
      for (final u in units) {
        await _upsertById(
          txn,
          SchemaConstants.unit,
          {...u, 'is_active': 1, 'updated_at': now},
        );
      }

      final suppliers = [
        {'id': 1, 'name': 'Tokyo Foods Supply Co.'},
        {'id': 2, 'name': 'Metro Beverage Distributors'},
        {'id': 3, 'name': 'Fresh Farm Produce Inc.'},
      ];
      for (final s in suppliers) {
        await _upsertById(
          txn,
          SchemaConstants.supplier,
          {...s, 'is_active': 1, 'updated_at': now},
        );
      }

      // 3. Banks, Charge Accounts, Gift Checks + Serials, Void Reasons
      final banks = [
        {'id': 1, 'name': 'BDO Unibank', 'card_type': 2},
        {'id': 2, 'name': 'BPI', 'card_type': 2},
        {'id': 3, 'name': 'Metrobank', 'card_type': 2},
        {'id': 4, 'name': 'GCash / Maya QR Terminal', 'card_type': 3},
      ];
      for (final b in banks) {
        await _upsertById(
          txn,
          SchemaConstants.bank,
          {...b, 'is_active': 1, 'updated_at': now},
        );
      }

      final chargeAccounts = [
        {'id': 1, 'code': 101, 'name': 'Acme Corp VIP Account', 'charge_type': 1},
        {'id': 2, 'code': 102, 'name': 'Executive Officer Account', 'charge_type': 1},
        {'id': 3, 'code': 103, 'name': 'Partner Hotel Room Charge', 'charge_type': 2},
      ];
      for (final ca in chargeAccounts) {
        await _upsertById(
          txn,
          SchemaConstants.chargePayment,
          {...ca, 'is_active': 1, 'updated_at': now},
        );
      }

      final giftChecks = [
        {'id': 1, 'code': 500, 'name': '₱500 Gift Certificate', 'amount': 500.0, 'gc_type': 1},
        {'id': 2, 'code': 1000, 'name': '₱1,000 VIP Gift Voucher', 'amount': 1000.0, 'gc_type': 1},
      ];
      for (final gc in giftChecks) {
        await _upsertById(
          txn,
          SchemaConstants.giftCheck,
          {...gc, 'is_active': 1, 'updated_at': now},
        );
      }

      final gcSerials = [
        {'id': 1, 'gift_check_id': 1, 'serial_number': 'GC-500-001'},
        {'id': 2, 'gift_check_id': 1, 'serial_number': 'GC-500-002'},
        {'id': 3, 'gift_check_id': 1, 'serial_number': 'GC-500-003'},
        {'id': 4, 'gift_check_id': 1, 'serial_number': 'GC-500-004'},
        {'id': 5, 'gift_check_id': 1, 'serial_number': 'GC-500-005'},
        {'id': 6, 'gift_check_id': 2, 'serial_number': 'GC-1000-001'},
        {'id': 7, 'gift_check_id': 2, 'serial_number': 'GC-1000-002'},
        {'id': 8, 'gift_check_id': 2, 'serial_number': 'GC-1000-003'},
      ];
      for (final ser in gcSerials) {
        await txn.insert(
          SchemaConstants.giftCheckSerial,
          {
            ...ser,
            'status': 1, // 1 = Active / Available for redemption
            'origin_branch': 'MAIN',
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final voidReasons = [
        {'id': 1, 'reason': 'Customer Changed Mind'},
        {'id': 2, 'reason': 'Wrong Item Punched'},
        {'id': 3, 'reason': 'Wrong Payment Tender Selected'},
        {'id': 4, 'reason': 'Duplicate Transaction'},
      ];
      for (final vr in voidReasons) {
        await _upsertById(
          txn,
          SchemaConstants.voidReason,
          {...vr, 'is_active': 1},
        );
      }

      // 4. Discount Types & Configured Discounts
      final discountTypes = [
        {'id': 1, 'code': 'generic', 'name': 'Generic Discount'},
        {'id': 2, 'code': 'senior', 'name': 'Senior Citizen (GPC)'},
        {'id': 3, 'code': 'pwd', 'name': 'Person with Disability'},
        {'id': 4, 'code': 'employee', 'name': 'Employee Discount'},
        {'id': 5, 'code': 'vip', 'name': 'VIP Discount'},
        {'id': 6, 'code': 'solo_parent', 'name': 'Solo Parent'},
        {'id': 7, 'code': 'athlete', 'name': 'National Athlete'},
        {'id': 8, 'code': 'custom', 'name': 'Custom Discount'},
      ];
      for (final dt in discountTypes) {
        await txn.insert(
          SchemaConstants.discountType,
          {...dt, 'is_active': 1},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      Future<int> getDiscTypeId(String code) async {
        final rows = await txn.query(
          SchemaConstants.discountType,
          columns: ['id'],
          where: 'code = ?',
          whereArgs: [code],
          limit: 1,
        );
        return rows.isNotEmpty ? rows.first['id']! as int : 1;
      }

      final seniorTypeId = await getDiscTypeId('senior');
      final pwdTypeId = await getDiscTypeId('pwd');
      final employeeTypeId = await getDiscTypeId('employee');
      final vipTypeId = await getDiscTypeId('vip');
      final genericTypeId = await getDiscTypeId('generic');
      final athleteTypeId = await getDiscTypeId('athlete');

      final discounts = [
        {
          'id': 1,
          'discount_type_id': seniorTypeId,
          'name': 'Senior Citizen 20%',
          'percentage': 20.0,
          'fixed_amount': null,
          'cap_amount': null,
        },
        {
          'id': 2,
          'discount_type_id': pwdTypeId,
          'name': 'PWD 20%',
          'percentage': 20.0,
          'fixed_amount': null,
          'cap_amount': null,
        },
        {
          'id': 3,
          'discount_type_id': employeeTypeId,
          'name': 'Employee Meal 15%',
          'percentage': 15.0,
          'fixed_amount': null,
          'cap_amount': 150.0,
        },
        {
          'id': 4,
          'discount_type_id': vipTypeId,
          'name': 'Suki VIP 10%',
          'percentage': 10.0,
          'fixed_amount': null,
          'cap_amount': null,
        },
        {
          'id': 5,
          'discount_type_id': genericTypeId,
          'name': 'Promo ₱100 Off',
          'percentage': null,
          'fixed_amount': 100.0,
          'cap_amount': 100.0,
        },
        {
          'id': 6,
          'discount_type_id': athleteTypeId,
          'name': 'National Athlete 20%',
          'percentage': 20.0,
          'fixed_amount': null,
          'cap_amount': null,
        },
      ];
      for (final d in discounts) {
        await _upsertById(
          txn,
          SchemaConstants.discount,
          {...d, 'is_active': 1, 'updated_at': now},
        );
      }

      // 5. Departments (5 departments)
      final departments = [
        {'id': 1, 'code': 'DEPT-FOOD', 'name': 'Kitchen & Hot Meals'},
        {'id': 2, 'code': 'DEPT-BEV', 'name': 'Beverages & Cafe'},
        {'id': 3, 'code': 'DEPT-DES', 'name': 'Desserts & Bakery'},
        {'id': 4, 'code': 'DEPT-RET', 'name': 'Retail & Pantry'},
        {'id': 5, 'code': 'DEPT-RAW', 'name': 'Raw Ingredients'},
      ];
      for (final dept in departments) {
        await _upsertById(
          txn,
          SchemaConstants.department,
          {...dept, 'is_active': 1, 'updated_at': now},
        );
      }

      // 6. Categories (8 categories)
      final categories = [
        {'id': 1, 'department_id': 1, 'code': 'CAT-RAMEN', 'name': 'Signature Ramen', 'display_order': 1},
        {'id': 2, 'department_id': 1, 'code': 'CAT-RICE', 'name': 'Donburi & Rice Bowls', 'display_order': 2},
        {'id': 3, 'department_id': 1, 'code': 'CAT-SIDE', 'name': 'Gyoza & Appetizers', 'display_order': 3},
        {'id': 4, 'department_id': 2, 'code': 'CAT-COFFEE', 'name': 'Specialty Coffee & Matcha', 'display_order': 4},
        {'id': 5, 'department_id': 2, 'code': 'CAT-COOL', 'name': 'Bottled & Cold Drinks', 'display_order': 5},
        {'id': 6, 'department_id': 3, 'code': 'CAT-SWEET', 'name': 'Cakes & Desserts', 'display_order': 6},
        {'id': 7, 'department_id': 4, 'code': 'CAT-GROC', 'name': 'Take-Home & Pantry', 'display_order': 7},
        {'id': 8, 'department_id': 5, 'code': 'CAT-RAW', 'name': 'Kitchen Raw Materials', 'display_order': 8},
      ];
      for (final cat in categories) {
        await _upsertById(
          txn,
          SchemaConstants.category,
          {
            ...cat,
            'is_available_online': 1,
            'is_active': 1,
            'updated_at': now,
          },
        );
      }

      // 7. Items & Default Prices (15 items covering all POS scenarios)
      final items = [
        {
          'id': 1,
          'barcode': '480001',
          'item_code': 'ITM-RAMEN-01',
          'name': 'Tonkotsu Ramen',
          'print_name': 'Tonkotsu Ramen',
          'item_details': 'Rich 12-hour pork bone broth with chashu, menma, and scallions (Recipe + Modifiers)',
          'category_id': 1,
          'department_id': 1,
          'unit_id': 2,
          'cost_price': 95.0,
          'price': 280.0,
          'is_composition': 1,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 60.0,
          'reorder_level': 15.0,
          'supplier_id': 1,
        },
        {
          'id': 2,
          'barcode': '480002',
          'item_code': 'ITM-RAMEN-02',
          'name': 'Spicy Tantanmen Ramen',
          'print_name': 'Spicy Tantanmen',
          'item_details': 'Sesame chili broth topped with spicy minced pork and bok choy (Recipe + Modifiers)',
          'category_id': 1,
          'department_id': 1,
          'unit_id': 2,
          'cost_price': 105.0,
          'price': 310.0,
          'is_composition': 1,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 45.0,
          'reorder_level': 15.0,
          'supplier_id': 1,
        },
        {
          'id': 3,
          'barcode': '480003',
          'item_code': 'ITM-DON-01',
          'name': 'Beef Gyudon Bowl',
          'print_name': 'Beef Gyudon Bowl',
          'item_details': 'Simmered US beef belly and sweet onions over Japanese rice',
          'category_id': 2,
          'department_id': 1,
          'unit_id': 2,
          'cost_price': 85.0,
          'price': 245.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 50.0,
          'reorder_level': 10.0,
          'supplier_id': 1,
        },
        {
          'id': 4,
          'barcode': '480004',
          'item_code': 'ITM-DON-02',
          'name': 'Crispy Katsudon Bowl',
          'print_name': 'Crispy Katsudon',
          'item_details': 'Panko pork cutlet with egg dashi (₱224 = ₱200 VATable + ₱24 VAT)',
          'category_id': 2,
          'department_id': 1,
          'unit_id': 2,
          'cost_price': 75.0,
          'price': 224.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 50.0,
          'reorder_level': 10.0,
          'supplier_id': 1,
        },
        {
          'id': 5,
          'barcode': '480005',
          'item_code': 'ITM-SIDE-01',
          'name': 'Pan-Fried Pork Gyoza (6pcs)',
          'print_name': 'Pork Gyoza 6pcs',
          'item_details': 'Crisp Japanese dumplings served with ponzu dipping sauce',
          'category_id': 3,
          'department_id': 1,
          'unit_id': 1,
          'cost_price': 48.0,
          'price': 150.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 80.0,
          'reorder_level': 20.0,
          'supplier_id': 1,
        },
        {
          'id': 6,
          'barcode': '480006',
          'item_code': 'ITM-SIDE-02',
          'name': 'Ebi Tempura Platter (5pcs)',
          'print_name': 'Ebi Tempura 5pcs',
          'item_details': 'Golden battered black tiger prawns with tentsuyu sauce',
          'category_id': 3,
          'department_id': 1,
          'unit_id': 1,
          'cost_price': 90.0,
          'price': 260.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 35.0,
          'reorder_level': 10.0,
          'supplier_id': 1,
        },
        {
          'id': 7,
          'barcode': '480007',
          'item_code': 'ITM-BEV-01',
          'name': 'Iced Uji Matcha Latte',
          'print_name': 'Uji Matcha Latte',
          'item_details': 'Ceremonial grade Kyoto matcha whisked with fresh milk (Has Modifiers)',
          'category_id': 4,
          'department_id': 2,
          'unit_id': 3,
          'cost_price': 45.0,
          'price': 168.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 75.0,
          'reorder_level': 15.0,
          'supplier_id': 2,
        },
        {
          'id': 8,
          'barcode': '480008',
          'item_code': 'ITM-BEV-02',
          'name': 'Japanese Roasted Cold Brew',
          'print_name': 'Roasted Cold Brew',
          'item_details': '16-hour slow-steeped dark roast arabica coffee',
          'category_id': 4,
          'department_id': 2,
          'unit_id': 3,
          'cost_price': 35.0,
          'price': 140.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 65.0,
          'reorder_level': 15.0,
          'supplier_id': 2,
        },
        {
          'id': 9,
          'barcode': '480009',
          'item_code': 'ITM-BEV-03',
          'name': 'Craft Ginger Ale (Promo Bottle)',
          'print_name': 'Craft Ginger Ale',
          'item_details': 'Discount-Exempt item (is_discount_exempt = 1) for testing mixed carts',
          'category_id': 5,
          'department_id': 2,
          'unit_id': 5,
          'cost_price': 55.0,
          'price': 112.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 1,
          'is_raw_material': 0,
          'stock_qty': 90.0,
          'reorder_level': 20.0,
          'supplier_id': 2,
        },
        {
          'id': 10,
          'barcode': '480010',
          'item_code': 'ITM-DES-01',
          'name': 'Hokkaido Basque Cheesecake',
          'print_name': 'Basque Cheesecake',
          'item_details': 'Caramelized cream cheese slice (Seeded at Low Stock: 4 left)',
          'category_id': 6,
          'department_id': 3,
          'unit_id': 1,
          'cost_price': 65.0,
          'price': 195.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 4.0,
          'reorder_level': 10.0,
          'supplier_id': 3,
        },
        {
          'id': 11,
          'barcode': '480011',
          'item_code': 'ITM-RET-01',
          'name': 'Organic Raw Brown Rice (2kg)',
          'print_name': 'Organic Brown Rice',
          'item_details': 'VAT-Exempt agricultural product (is_vat_exempt = 1)',
          'category_id': 7,
          'department_id': 4,
          'unit_id': 6,
          'cost_price': 115.0,
          'price': 180.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 1,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 30.0,
          'reorder_level': 8.0,
          'supplier_id': 3,
        },
        {
          'id': 12,
          'barcode': '480012',
          'item_code': 'ITM-RET-02',
          'name': 'Signature Chili Garlic Oil Jar',
          'print_name': 'Chili Garlic Jar',
          'item_details': 'House-made crispy chili oil (Seeded at Low Stock: 3 left)',
          'category_id': 7,
          'department_id': 4,
          'unit_id': 5,
          'cost_price': 80.0,
          'price': 220.0,
          'is_composition': 0,
          'is_finished_good': 1,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 0,
          'stock_qty': 3.0,
          'reorder_level': 12.0,
          'supplier_id': 1,
        },
        {
          'id': 13,
          'barcode': '480091',
          'item_code': 'RAW-NOODLE',
          'name': 'Fresh Ramen Noodle Pack (Raw)',
          'print_name': 'Raw Ramen Noodle',
          'item_details': 'Raw ingredient deducted automatically via composition / cogs_line (sales_m3)',
          'category_id': 8,
          'department_id': 5,
          'unit_id': 4,
          'cost_price': 25.0,
          'price': 35.0,
          'is_composition': 0,
          'is_finished_good': 0,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 1,
          'stock_qty': 200.0,
          'reorder_level': 40.0,
          'supplier_id': 1,
        },
        {
          'id': 14,
          'barcode': '480092',
          'item_code': 'RAW-BROTH',
          'name': 'Tonkotsu Broth Base 500ml (Raw)',
          'print_name': 'Raw Broth Base',
          'item_details': 'Raw ingredient deducted automatically via composition / cogs_line (sales_m3)',
          'category_id': 8,
          'department_id': 5,
          'unit_id': 4,
          'cost_price': 35.0,
          'price': 50.0,
          'is_composition': 0,
          'is_finished_good': 0,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 1,
          'stock_qty': 150.0,
          'reorder_level': 30.0,
          'supplier_id': 1,
        },
        {
          'id': 15,
          'barcode': '480093',
          'item_code': 'RAW-CHASHU',
          'name': 'Braised Pork Chashu Slice (Raw)',
          'print_name': 'Raw Chashu Slice',
          'item_details': 'Raw ingredient deducted automatically via composition / cogs_line (sales_m3)',
          'category_id': 8,
          'department_id': 5,
          'unit_id': 1,
          'cost_price': 28.0,
          'price': 40.0,
          'is_composition': 0,
          'is_finished_good': 0,
          'is_vat_exempt': 0,
          'is_discount_exempt': 0,
          'is_raw_material': 1,
          'stock_qty': 180.0,
          'reorder_level': 35.0,
          'supplier_id': 1,
        },
      ];

      for (final item in items) {
        final itemId = item['id']! as int;
        final price = item['price']! as double;
        final stockQty = item['stock_qty']! as double;
        final reorderLevel = item['reorder_level']! as double;
        final supplierId = item['supplier_id']! as int;
        final costPrice = item['cost_price']! as double;

        await _upsertById(txn, SchemaConstants.item, {
          'id': itemId,
          'barcode': item['barcode'],
          'item_code': item['item_code'],
          'name': item['name'],
          'print_name': item['print_name'],
          'label_name': item['print_name'],
          'item_details': item['item_details'],
          'category_id': item['category_id'],
          'department_id': item['department_id'],
          'unit_id': item['unit_id'],
          'cost_price': costPrice,
          'min_stock_level': reorderLevel,
          'max_stock_level': stockQty * 2,
          'is_composition': item['is_composition'],
          'is_finished_good': item['is_finished_good'],
          'is_vat_exempt': item['is_vat_exempt'],
          'is_discount_exempt': item['is_discount_exempt'],
          'is_raw_material': item['is_raw_material'],
          'is_active': 1,
          'updated_at': now,
        });

        final updatedPrice = await txn.update(
          SchemaConstants.itemPrice,
          {'price': price},
          where: 'item_id = ? AND price_level = ?',
          whereArgs: [itemId, 'default'],
        );
        if (updatedPrice == 0) {
          await txn.insert(SchemaConstants.itemPrice, {
            'item_id': itemId,
            'price_level': 'default',
            'price': price,
          });
        }

        final stockValues = {
          'item_id': itemId,
          'quantity': stockQty,
          'reorder_level': reorderLevel,
          'beginning_inv': stockQty,
          'min_level': reorderLevel,
          'max_level': stockQty * 2,
          'cost': costPrice,
          'physical_count': stockQty,
          'variance': 0.0,
          'remarks': 'SEEDED: Debug Catalog Initial Stock',
          'supplier_id': supplierId,
          'location': item['is_raw_material'] == 1
              ? 'Cold Storage'
              : 'Main Kitchen / Counter',
          'updated_at': now,
        };
        final updatedStock = await txn.update(
          SchemaConstants.stock,
          stockValues,
          where: 'item_id = ?',
          whereArgs: [itemId],
        );
        if (updatedStock == 0) {
          await txn.insert(SchemaConstants.stock, stockValues);
        }
      }

      // 8. Recipe Compositions (`composition`) for Ramen items -> Raw Materials (`sales_m3` / `cogs_line`)
      final compositions = [
        {'finished_item_id': 1, 'component_item_id': 13, 'quantity': 1.0, 'unit_id': 4},
        {'finished_item_id': 1, 'component_item_id': 14, 'quantity': 1.0, 'unit_id': 4},
        {'finished_item_id': 1, 'component_item_id': 15, 'quantity': 2.0, 'unit_id': 1},
        {'finished_item_id': 2, 'component_item_id': 13, 'quantity': 1.0, 'unit_id': 4},
        {'finished_item_id': 2, 'component_item_id': 14, 'quantity': 1.0, 'unit_id': 4},
        {'finished_item_id': 2, 'component_item_id': 15, 'quantity': 1.0, 'unit_id': 1},
      ];
      for (final comp in compositions) {
        final updatedComp = await txn.update(
          SchemaConstants.composition,
          {...comp, 'updated_at': now},
          where: 'finished_item_id = ? AND component_item_id = ?',
          whereArgs: [comp['finished_item_id'], comp['component_item_id']],
        );
        if (updatedComp == 0) {
          await txn.insert(
            SchemaConstants.composition,
            {...comp, 'created_at': now, 'updated_at': now},
          );
        }
      }

      // 9. Option Groups, Option Values & Item Links
      final optionGroups = [
        {
          'id': 1,
          'name': 'Ramen Toppings & Add-ons',
          'is_required': 0,
          'selection_type': 1,
          'min_select': 0,
          'max_select': 4,
          'display_order': 1,
        },
        {
          'id': 2,
          'name': 'Beverage Customizations',
          'is_required': 0,
          'selection_type': 1,
          'min_select': 0,
          'max_select': 2,
          'display_order': 2,
        },
      ];
      for (final og in optionGroups) {
        await _upsertById(
          txn,
          SchemaConstants.optionGroup,
          {...og, 'updated_at': now},
        );
      }

      final optionValues = [
        {'id': 101, 'option_group_id': 1, 'alias': 'Ajitama Egg', 'price_delta': 45.0, 'cost_price_delta': 18.0, 'display_order': 1},
        {'id': 102, 'option_group_id': 1, 'item_id': 15, 'alias': 'Extra Chashu Pork (2pcs)', 'price_delta': 75.0, 'cost_price_delta': 56.0, 'quantity': 2.0, 'display_order': 2},
        {'id': 103, 'option_group_id': 1, 'item_id': 13, 'alias': 'Extra Ramen Noodles', 'price_delta': 50.0, 'cost_price_delta': 25.0, 'quantity': 1.0, 'display_order': 3},
        {'id': 104, 'option_group_id': 1, 'alias': 'Nori Seaweed (3pcs)', 'price_delta': 30.0, 'cost_price_delta': 10.0, 'display_order': 4},
        {'id': 201, 'option_group_id': 2, 'alias': 'Less Sweet (50%)', 'price_delta': 0.0, 'cost_price_delta': 0.0, 'display_order': 1},
        {'id': 202, 'option_group_id': 2, 'alias': 'Oat Milk Sub', 'price_delta': 40.0, 'cost_price_delta': 18.0, 'display_order': 2},
        {'id': 203, 'option_group_id': 2, 'alias': 'Extra Espresso / Matcha Shot', 'price_delta': 45.0, 'cost_price_delta': 15.0, 'display_order': 3},
      ];
      for (final ov in optionValues) {
        await _upsertById(txn, SchemaConstants.optionValue, ov);
      }

      final itemOptionLinks = [
        {'item_id': 1, 'option_group_id': 1, 'display_order': 1},
        {'item_id': 2, 'option_group_id': 1, 'display_order': 1},
        {'item_id': 7, 'option_group_id': 2, 'display_order': 1},
        {'item_id': 8, 'option_group_id': 2, 'display_order': 1},
      ];
      for (final link in itemOptionLinks) {
        await txn.insert(
          SchemaConstants.itemOptionGroup,
          {...link, 'is_override': 0},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    return const DebugSeedSummary(
      departments: 5,
      categories: 8,
      items: 15,
      discounts: 6,
      stocks: 15,
      giftCheckSerials: 8,
    );
  }

  /// Clears all transactional, shift, and X/Z-reading tables, resets `counter_table`
  /// back to `0` (`si_number = 0, tseq_no = 0, z_read_count = 0`), restores
  /// `gift_check_serial` availability (`status = 1`), and re-seeds the complete
  /// master catalog and stock quantities.
  Future<DebugSeedSummary> resetTransactionsAndReseed() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final transactionalTables = [
        SchemaConstants.electronicJournal,
        SchemaConstants.cashDeclarationDenomination,
        SchemaConstants.cashDeclaration,
        SchemaConstants.shortOver,
        SchemaConstants.dailySummary,
        SchemaConstants.cashFundLog,
        SchemaConstants.deposit,
        SchemaConstants.shift,
        SchemaConstants.voidTransaction,
        SchemaConstants.discountBeneficiary,
        SchemaConstants.cogsLine,
        SchemaConstants.paymentDeposit,
        SchemaConstants.payment,
        SchemaConstants.transactionLine,
        SchemaConstants.saleTransaction,
        SchemaConstants.orderItemOption,
        SchemaConstants.salesOrderItem,
        SchemaConstants.salesOrder,
        SchemaConstants.customer,
      ];

      for (final table in transactionalTables) {
        await txn.delete(table);
      }

      await txn.delete(SchemaConstants.counterTable);
      await txn.insert(SchemaConstants.counterTable, {
        'id': 1,
        'tseq_no': 0,
        'si_number': 0,
        'z_read_count': 0,
        'post_void_count': 0,
        'so_number': 1,
        'incoming_number': 1,
        'outgoing_number': 1,
        'deposit_number': 1,
        'trans_number': 0,
        'last_updated': now,
      });

      await txn.update(
        SchemaConstants.giftCheckSerial,
        {
          'status': 1,
          'redeemed_by': null,
          'redeemed_at': null,
          'redeeming_transaction_id': null,
        },
      );
    });

    final summary = await seedDemoCatalog();
    return DebugSeedSummary(
      departments: summary.departments,
      categories: summary.categories,
      items: summary.items,
      discounts: summary.discounts,
      stocks: summary.stocks,
      giftCheckSerials: summary.giftCheckSerials,
      transactionsCleared: true,
    );
  }

  /// Resets to a clean demo state and automatically executes the 7 QA Test Cases
  /// (`TC-01` through `TC-07`: Opening Change Fund ₱2,000, SI #1 Cash, SI #2 Senior
  /// Citizen + Card, SI #3 Recipe Ramen w/ Modifier + Mixed VAT/Discount-Exempt +
  /// VIP 10% + GCash, SI #4 Split Payment w/ Gift Check Excess + Cash, SI #5 Post-Voided,
  /// and Cash In +₱300 / Cash Out -₱100) so the user can immediately inspect
  /// Transaction History, Inventory COGS deductions, and run Tender Declaration ->
  /// X-Reading -> Z-Reading (`Expected Drawer Cash = ₱2,868.00`, `Net Sales = ₱2,018.50`).
  Future<void> seedSampleShiftAndTransactions({int cashierId = 2}) async {
    await resetTransactionsAndReseed();

    final shiftDao = ShiftDao(_databaseHelper);
    final orderDao = OrderDao(_databaseHelper);
    final now = DateTime.now();

    Item buildSeededItem({
      required int id,
      required String barcode,
      required String code,
      required String name,
      required int categoryId,
      required int departmentId,
      required double costPrice,
      required double price,
      bool isVatExempt = false,
      bool isDiscountExempt = false,
      bool isComposition = false,
    }) {
      return Item(
        id: id,
        barcode: barcode,
        itemCode: code,
        name: name,
        printName: name,
        categoryId: categoryId,
        departmentId: departmentId,
        costPrice: costPrice,
        isVatExempt: isVatExempt,
        isDiscountExempt: isDiscountExempt,
        isComposition: isComposition,
        prices: [
          ItemPriceModel(id: id, priceLevel: 'default', price: price),
        ],
      );
    }

    final katsudon = buildSeededItem(
      id: 4,
      barcode: '480004',
      code: 'ITM-DON-02',
      name: 'Crispy Katsudon Bowl',
      categoryId: 2,
      departmentId: 1,
      costPrice: 75,
      price: 224,
    );
    final tonkotsu = buildSeededItem(
      id: 1,
      barcode: '480001',
      code: 'ITM-RAMEN-01',
      name: 'Tonkotsu Ramen',
      categoryId: 1,
      departmentId: 1,
      costPrice: 95,
      price: 280,
      isComposition: true,
    );
    final tantanmen = buildSeededItem(
      id: 2,
      barcode: '480002',
      code: 'ITM-RAMEN-02',
      name: 'Spicy Tantanmen Ramen',
      categoryId: 1,
      departmentId: 1,
      costPrice: 105,
      price: 310,
      isComposition: true,
    );
    final gingerAle = buildSeededItem(
      id: 9,
      barcode: '480009',
      code: 'ITM-BEV-03',
      name: 'Craft Ginger Ale (Promo Bottle)',
      categoryId: 5,
      departmentId: 2,
      costPrice: 55,
      price: 112,
      isDiscountExempt: true,
    );
    final brownRice = buildSeededItem(
      id: 11,
      barcode: '480011',
      code: 'ITM-RET-01',
      name: 'Organic Raw Brown Rice (2kg)',
      categoryId: 7,
      departmentId: 4,
      costPrice: 115,
      price: 180,
      isVatExempt: true,
    );
    final chiliJar = buildSeededItem(
      id: 12,
      barcode: '480012',
      code: 'ITM-RET-02',
      name: 'Signature Chili Garlic Oil Jar',
      categoryId: 7,
      departmentId: 4,
      costPrice: 80,
      price: 220,
    );

    // TC-01: Open Shift with ₱2,000.00 Opening Change Fund
    await shiftDao.openShift(cashierId, 2000);

    // TC-02 (SI #000001): 2x Crispy Katsudon (₱448.00) paid with ₱500 Cash (₱52 Change)
    await orderDao.checkoutOrderTransaction(
      order: SalesOrderAggregate(
        orderTypeId: 2,
        cashierId: cashierId,
        items: [CartItem(id: 'tc2-1', item: katsudon, quantity: 2)],
        createdAt: now,
      ),
      paymentMethodId: 1,
      cashTendered: 500,
      changeGiven: 52,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 1,
          paymentMethodCode: 'cash',
          paymentMethodName: 'Cash',
          amount: 448,
          cashTendered: 500,
          changeGiven: 52,
        ),
      ],
    );

    // TC-03 (SI #000002): 2x Crispy Katsudon (₱448.00), Senior Citizen 20% (1 of 2 guests) -> ₱384.00 via BDO Card
    await orderDao.checkoutOrderTransaction(
      order: SalesOrderAggregate(
        orderTypeId: 2,
        cashierId: cashierId,
        guestCount: 2,
        eligibleGuestCount: 1,
        discountId: 1, // Senior Citizen 20%
        beneficiaryName: 'Lolo Pedro',
        beneficiaryIdNo: 'SC-998877',
        items: [CartItem(id: 'tc3-1', item: katsudon, quantity: 2)],
        createdAt: now,
      ),
      paymentMethodId: 2,
      cashTendered: 384,
      changeGiven: 0,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 2,
          paymentMethodCode: 'card',
          paymentMethodName: 'Credit/Debit Card',
          amount: 384,
          cashTendered: 384,
          cashlessAmount: 384,
          bankId: 1,
          bankName: 'BDO Unibank',
          cardType: 2,
          cardNumber: '4111',
          approvalNumber: 'APP-1002',
        ),
      ],
    );

    // TC-04 (SI #000003): Tonkotsu Ramen + Ajitama Egg (₱325) + Ginger Ale (₱112, Disc-Exempt) + Brown Rice (₱180, VAT-Exempt)
    // with Suki VIP 10% (discountId: 4) -> Net Due = ₱566.50 via GCash QR
    await orderDao.checkoutOrderTransaction(
      order: SalesOrderAggregate(
        orderTypeId: 2,
        cashierId: cashierId,
        discountId: 4, // Suki VIP 10%
        discPercentage: 10,
        items: [
          CartItem(
            id: 'tc4-1',
            item: tonkotsu,
            selectedOptions: const [
              OptionValue(
                id: 101,
                optionGroupId: 1,
                alias: 'Ajitama Egg',
                priceDelta: 45,
                costPriceDelta: 18,
              ),
            ],
          ),
          CartItem(id: 'tc4-2', item: gingerAle),
          CartItem(id: 'tc4-3', item: brownRice),
        ],
        createdAt: now,
      ),
      paymentMethodId: 3,
      cashTendered: 566.50,
      changeGiven: 0,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 3,
          paymentMethodCode: 'atm',
          paymentMethodName: 'ATM / Online Banking',
          amount: 566.50,
          cashTendered: 566.50,
          cashlessAmount: 566.50,
          bankId: 4,
          paymentChannel: 'GCash',
          referenceNumber: 'GCASH-3003',
        ),
      ],
    );

    // TC-05 (SI #000004): 2x Spicy Tantanmen (₱620.00) Split Payment: ₱400 via ₱500 Gift Check (₱100 Excess) + ₱220 Cash
    await orderDao.checkoutOrderTransaction(
      order: SalesOrderAggregate(
        orderTypeId: 2,
        cashierId: cashierId,
        items: [CartItem(id: 'tc5-1', item: tantanmen, quantity: 2)],
        createdAt: now,
      ),
      paymentMethodId: 5,
      cashTendered: 720,
      changeGiven: 0,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 5,
          paymentMethodCode: 'gift_check',
          paymentMethodName: 'Gift Check',
          amount: 400,
          cashTendered: 500,
          excessAmount: 100,
          cashlessAmount: 500,
          giftCheckId: 1,
          giftCheckQty: 1,
          serialNumbers: 'GC-500-001',
        ),
        TenderPaymentLeg(
          paymentMethodId: 1,
          paymentMethodCode: 'cash',
          paymentMethodName: 'Cash',
          amount: 220,
          cashTendered: 220,
        ),
      ],
    );

    // TC-06 (SI #000005 -> Post-Voided): 1x Signature Chili Garlic Oil Jar (₱220.00) paid Cash then Post-Voided
    final txnId5 = await orderDao.checkoutOrderTransaction(
      order: SalesOrderAggregate(
        orderTypeId: 2,
        cashierId: cashierId,
        items: [CartItem(id: 'tc6-1', item: chiliJar)],
        createdAt: now,
      ),
      paymentMethodId: 1,
      cashTendered: 220,
      changeGiven: 0,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 1,
          paymentMethodCode: 'cash',
          paymentMethodName: 'Cash',
          amount: 220,
          cashTendered: 220,
        ),
      ],
    );
    await orderDao.voidOrderTransaction(
      transactionId: txnId5,
      cashierId: cashierId,
      authorizedById: 1,
      voidReasonId: 1,
      reason: 'Customer Changed Mind',
      expectedAmountDue: 220,
    );

    // TC-07: Cash Fund In (+₱300.00) and Cash Fund Out (-₱100.00)
    await shiftDao.insertCashFundLog(
      cashierId: cashierId,
      isCashIn: true,
      amount: 300,
      reason: 'Additional change coins',
    );
    await shiftDao.insertCashFundLog(
      cashierId: cashierId,
      isCashIn: false,
      amount: 100,
      reason: 'Bought ice bags',
    );
  }
}
