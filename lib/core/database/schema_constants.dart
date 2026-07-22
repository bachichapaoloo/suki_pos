/// Defines table names and DDL scripts for the SukiPOS SQLite database.
class SchemaConstants {
  const SchemaConstants._();

  // Table Names
  static const String department = 'department';
  static const String category = 'category';
  static const String unit = 'unit';
  static const String supplier = 'supplier';
  static const String tag = 'tag';
  static const String bank = 'bank';
  static const String voidReason = 'void_reason';
  static const String orderType = 'order_type';
  static const String discountType = 'discount_type';
  static const String discount = 'discount';
  static const String discountAvailability = 'discount_availability';
  static const String serviceCharge = 'service_charge';
  static const String fundMovementPurpose = 'fund_movement_purpose';
  static const String therapist = 'therapist';
  static const String item = 'item';
  static const String itemPrice = 'item_price';
  static const String itemTag = 'item_tag';
  static const String itemAvailability = 'item_availability';
  static const String optionGroup = 'option_group';
  static const String optionValue = 'option_value';
  static const String itemOptionGroup = 'item_option_group';
  static const String composition = 'composition';
  static const String stock = 'stock';
  static const String giftCheck = 'gift_check';
  static const String giftCheckSerial = 'gift_check_serial';
  static const String coupon = 'coupon';
  static const String couponSerial = 'coupon_serial';
  static const String floor = 'floor';
  static const String diningTable = 'dining_table';
  static const String floorLayoutItem = 'floor_layout_item';
  static const String role = 'role';
  static const String rolePermission = 'role_permission';
  static const String appUser = 'app_user';
  static const String salesOrder = 'sales_order';
  static const String salesOrderItem = 'sales_order_item';
  static const String orderItemOption = 'order_item_option';
  static const String orderRemovalLog = 'order_removal_log';
  static const String splitBillSession = 'split_bill_session';
  static const String splitBill = 'split_bill';
  static const String splitBillItem = 'split_bill_item';
  static const String paymentMethod = 'payment_method';
  static const String saleTransaction = 'sale_transaction';
  static const String transactionLine = 'transaction_line';
  static const String payment = 'payment';
  static const String chargePayment = 'charge_payment';
  static const String paymentDeposit = 'payment_deposit';
  static const String voidTransaction = 'void_transaction';
  static const String cashDeclaration = 'cash_declaration';
  static const String cashDeclarationDenomination = 'cash_declaration_denomination';
  static const String cashFundLog = 'cash_fund_log';
  static const String deposit = 'deposit';
  static const String shortOver = 'short_over';
  static const String dailySummary = 'daily_summary';
  static const String stockReceipt = 'stock_receipt';
  static const String stockReceiptLine = 'stock_receipt_line';
  static const String stockIssue = 'stock_issue';
  static const String stockIssueLine = 'stock_issue_line';
  static const String physicalCount = 'physical_count';
  static const String cogsLine = 'cogs_line';
  static const String discountBeneficiary = 'discount_beneficiary';
  static const String customer = 'customer';
  static const String kdsOrder = 'kds_order';
  static const String kdsOrderItem = 'kds_order_item';
  static const String kdsSettings = 'kds_settings';
  static const String birConfig = 'bir_config';
  static const String printerConfig = 'printer_config';
  static const String emailConfig = 'email_config';
  static const String operatingHours = 'operating_hours';
  static const String connectedTerminal = 'connected_terminal';
  static const String secondScreenAd = 'second_screen_ad';
  static const String liveSyncSetting = 'live_sync_setting';
  static const String syncStatus = 'sync_status';
  static const String counterTable = 'counter_table';
  static const String dtrRecord = 'dtr_record';
  static const String usageLog = 'usage_log';
  static const String selfOrder = 'self_order';
  static const String selfOrderItem = 'self_order_item';
  static const String selfOrderItemOption = 'self_order_item_option';

  /// Complete list of DDL statements executed during database creation.
  static const List<String> createTableScripts = [
    '''
    CREATE TABLE IF NOT EXISTS department (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        code        TEXT    NOT NULL UNIQUE,
        name        TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS category (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        department_id           INTEGER NOT NULL REFERENCES department(id) ON DELETE RESTRICT,
        code                    TEXT,
        name                    TEXT    NOT NULL,
        display_order           INTEGER NOT NULL DEFAULT 0,
        is_available_online     INTEGER NOT NULL DEFAULT 1,
        recommended_category_id INTEGER REFERENCES category(id) ON DELETE SET NULL,
        is_active               INTEGER NOT NULL DEFAULT 1,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at              TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS unit (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        abbreviation TEXT,
        unit_value  REAL,
        base_unit   TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS supplier (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS tag (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL UNIQUE,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS bank (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        card_type   INTEGER,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS void_reason (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        reason      TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS order_type (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        name                    TEXT    NOT NULL,
        ask_guest_count         INTEGER NOT NULL DEFAULT 0,
        ask_ref_no              INTEGER NOT NULL DEFAULT 0,
        is_rental               INTEGER NOT NULL DEFAULT 0,
        is_delivery             INTEGER NOT NULL DEFAULT 0,
        is_kiosk                INTEGER NOT NULL DEFAULT 0,
        no_surcharge            INTEGER NOT NULL DEFAULT 0,
        has_service_charge      INTEGER NOT NULL DEFAULT 1,
        surcharge_formula       TEXT,
        price_level             TEXT,
        requires_password       INTEGER NOT NULL DEFAULT 0,
        additional_percentage   REAL    NOT NULL DEFAULT 0,
        print_additional_copy   INTEGER NOT NULL DEFAULT 0,
        is_active               INTEGER NOT NULL DEFAULT 1,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at              TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS discount_type (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        code        TEXT    NOT NULL UNIQUE,
        name        TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS discount (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        discount_type_id INTEGER NOT NULL REFERENCES discount_type(id) ON DELETE RESTRICT,
        name             TEXT    NOT NULL,
        percentage       REAL,
        fixed_amount     REAL,
        cap_amount       REAL,
        cap_percentage   REAL,
        limit_expr       TEXT,
        is_active        INTEGER NOT NULL DEFAULT 1,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS discount_availability (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        discount_id     INTEGER NOT NULL REFERENCES discount(id) ON DELETE CASCADE,
        day_of_week     TEXT,
        start_time      TEXT,
        end_time        TEXT,
        date_start      TEXT,
        date_end        TEXT,
        is_active       INTEGER NOT NULL DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS service_charge (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        amount      REAL    NOT NULL DEFAULT 0,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS fund_movement_purpose (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        movement_type   TEXT    NOT NULL CHECK(movement_type IN ('income','outgoing')),
        description     TEXT    NOT NULL,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS therapist (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS item (
        id                          INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode                     TEXT    UNIQUE,
        item_code                   TEXT    NOT NULL UNIQUE,
        name                        TEXT    NOT NULL,
        print_name                  TEXT    NOT NULL,
        label_name                  TEXT,
        item_details                TEXT,
        is_label_same_as_receipt    INTEGER NOT NULL DEFAULT 1,
        category_id                 INTEGER NOT NULL REFERENCES category(id) ON DELETE RESTRICT,
        department_id               INTEGER NOT NULL REFERENCES department(id) ON DELETE RESTRICT,
        unit_id                     INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        cost_price                  REAL    NOT NULL DEFAULT 0,
        markup_percentage           REAL,
        conversion_qty              REAL    NOT NULL DEFAULT 1,
        assigned_printer            TEXT,
        display_image               TEXT,
        button_index                INTEGER,
        min_stock_level             REAL    NOT NULL DEFAULT 0,
        max_stock_level             REAL    NOT NULL DEFAULT 0,
        is_discount_exempt          INTEGER NOT NULL DEFAULT 0,
        is_vat_exempt               INTEGER NOT NULL DEFAULT 0,
        is_combo                    INTEGER NOT NULL DEFAULT 0,
        is_finished_good            INTEGER NOT NULL DEFAULT 0,
        is_composition              INTEGER NOT NULL DEFAULT 0,
        is_raw_material             INTEGER NOT NULL DEFAULT 0,
        is_gift_check               INTEGER NOT NULL DEFAULT 0,
        gift_check_id               INTEGER REFERENCES gift_check(id) ON DELETE SET NULL,
        disc_cap_amount             REAL    NOT NULL DEFAULT 0,
        disc_cap_percentage         REAL    NOT NULL DEFAULT 0,
        is_active                   INTEGER NOT NULL DEFAULT 1,
        created_at                  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at                  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS item_price (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id     INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        price_level TEXT    NOT NULL DEFAULT 'default',
        price       REAL    NOT NULL,
        UNIQUE(item_id, price_level)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS item_tag (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id     INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        tag_id      INTEGER NOT NULL REFERENCES tag(id) ON DELETE CASCADE,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        UNIQUE(item_id, tag_id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS item_availability (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id     INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        day_of_week TEXT,
        start_time  TEXT,
        end_time    TEXT,
        date_start  TEXT,
        date_end    TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS option_group (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        is_required     INTEGER NOT NULL DEFAULT 0,
        selection_type  INTEGER NOT NULL DEFAULT 0,
        min_select      INTEGER NOT NULL DEFAULT 0,
        max_select      INTEGER,
        display_order   INTEGER NOT NULL DEFAULT 0,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS option_value (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        option_group_id     INTEGER NOT NULL REFERENCES option_group(id) ON DELETE CASCADE,
        item_id             INTEGER REFERENCES item(id) ON DELETE CASCADE,
        alias               TEXT,
        price_delta         REAL    NOT NULL DEFAULT 0,
        cost_price_delta    REAL    NOT NULL DEFAULT 0,
        quantity            REAL    NOT NULL DEFAULT 1,
        unit_id             INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        display_order       INTEGER NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS item_option_group (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id         INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        option_group_id INTEGER NOT NULL REFERENCES option_group(id) ON DELETE CASCADE,
        display_order   INTEGER NOT NULL DEFAULT 0,
        is_override     INTEGER NOT NULL DEFAULT 0,
        UNIQUE(item_id, option_group_id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS composition (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        finished_item_id  INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        component_item_id INTEGER NOT NULL REFERENCES item(id) ON DELETE RESTRICT,
        quantity          REAL    NOT NULL DEFAULT 1,
        unit_id           INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at        TEXT    NOT NULL DEFAULT (datetime('now')),
        UNIQUE(finished_item_id, component_item_id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id             INTEGER NOT NULL UNIQUE REFERENCES item(id) ON DELETE CASCADE,
        quantity            REAL    NOT NULL DEFAULT 0,
        reorder_level       REAL    NOT NULL DEFAULT 0,
        beginning_inv       REAL    NOT NULL DEFAULT 0,
        min_level           REAL    NOT NULL DEFAULT 0,
        max_level           REAL    NOT NULL DEFAULT 0,
        cost                REAL,
        physical_count      REAL,
        prev_physical_count REAL,
        last_physical_count REAL,
        variance            REAL,
        remarks             TEXT,
        supplier_id         INTEGER REFERENCES supplier(id) ON DELETE SET NULL,
        location            TEXT,
        updated_at          TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gift_check (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        code            INTEGER NOT NULL UNIQUE,
        name            TEXT    NOT NULL,
        amount          REAL    NOT NULL,
        gc_type         INTEGER NOT NULL DEFAULT 1,
        has_promo       INTEGER NOT NULL DEFAULT 0,
        buying_qty      INTEGER NOT NULL DEFAULT 1,
        free_qty        INTEGER NOT NULL DEFAULT 0,
        valid_until     TEXT,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS gift_check_serial (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        gift_check_id           INTEGER NOT NULL REFERENCES gift_check(id) ON DELETE RESTRICT,
        serial_number           TEXT    NOT NULL UNIQUE,
        status                  INTEGER NOT NULL DEFAULT 0,
        origin_branch           TEXT,
        sold_at                 TEXT,
        selling_transaction_id  INTEGER,
        redeemed_by             TEXT,
        redeemed_at             TEXT,
        redeeming_transaction_id INTEGER,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS coupon (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        code            INTEGER NOT NULL UNIQUE,
        name            TEXT    NOT NULL,
        coupon_type     INTEGER NOT NULL DEFAULT 1,
        value           REAL    NOT NULL,
        valid_until     TEXT,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS coupon_serial (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        coupon_id               INTEGER NOT NULL REFERENCES coupon(id) ON DELETE RESTRICT,
        serial_number           TEXT    NOT NULL UNIQUE,
        status                  INTEGER NOT NULL DEFAULT 1,
        redeemed_by             TEXT,
        redeemed_at             TEXT,
        redeeming_transaction_id INTEGER,
        generated_at            TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS floor (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL,
        is_custom_layout INTEGER NOT NULL DEFAULT 0,
        table_size       REAL    NOT NULL DEFAULT 64,
        is_active        INTEGER NOT NULL DEFAULT 1,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS dining_table (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        floor_id    INTEGER NOT NULL REFERENCES floor(id) ON DELETE RESTRICT,
        name        TEXT    NOT NULL,
        x_position  REAL    NOT NULL DEFAULT 0,
        y_position  REAL    NOT NULL DEFAULT 0,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS floor_layout_item (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        floor_id    INTEGER NOT NULL REFERENCES floor(id) ON DELETE CASCADE,
        name        TEXT    NOT NULL,
        item_type   TEXT    NOT NULL,
        x_position  REAL    NOT NULL DEFAULT 0,
        y_position  REAL    NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS role (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        name                 TEXT    NOT NULL UNIQUE,
        can_sales_entry      INTEGER NOT NULL DEFAULT 0,
        can_sales_order      INTEGER NOT NULL DEFAULT 0,
        can_sales_reading    INTEGER NOT NULL DEFAULT 0,
        can_sales_inquiry    INTEGER NOT NULL DEFAULT 0,
        can_file_maintenance INTEGER NOT NULL DEFAULT 0,
        can_admin_mode       INTEGER NOT NULL DEFAULT 0,
        can_dtr_menu         INTEGER NOT NULL DEFAULT 0,
        can_kiosk            INTEGER NOT NULL DEFAULT 0,
        can_inventory        INTEGER NOT NULL DEFAULT 0,
        is_active            INTEGER NOT NULL DEFAULT 1,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at           TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS role_permission (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id         INTEGER NOT NULL REFERENCES role(id) ON DELETE CASCADE,
        permission_key  TEXT    NOT NULL,
        is_allowed      INTEGER NOT NULL DEFAULT 0,
        UNIQUE(role_id, permission_key)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS app_user (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id         INTEGER NOT NULL REFERENCES role(id) ON DELETE RESTRICT,
        name            TEXT    NOT NULL,
        password_hash   TEXT    NOT NULL,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sales_order (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        dining_table_id      INTEGER REFERENCES dining_table(id) ON DELETE SET NULL,
        order_type_id        INTEGER NOT NULL REFERENCES order_type(id) ON DELETE RESTRICT,
        cashier_id           INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        therapist_id         INTEGER REFERENCES therapist(id) ON DELETE SET NULL,
        guest_count          INTEGER NOT NULL DEFAULT 1,
        eligible_guest_count INTEGER NOT NULL DEFAULT 0,
        payment_status       INTEGER NOT NULL DEFAULT 0 CHECK(payment_status IN (0,1,2)),
        discount_id          INTEGER REFERENCES discount(id) ON DELETE SET NULL,
        disc_fixed_amount    REAL    NOT NULL DEFAULT 0,
        disc_percentage      REAL    NOT NULL DEFAULT 0,
        coupon_id            INTEGER REFERENCES coupon(id) ON DELETE SET NULL,
        coupon_serial        TEXT,
        coupon_value         REAL,
        payment_deposit_id   INTEGER,
        is_split_bill        INTEGER NOT NULL DEFAULT 0,
        is_combined          INTEGER NOT NULL DEFAULT 0,
        parent_order_id      INTEGER REFERENCES sales_order(id) ON DELETE SET NULL,
        remarks              TEXT,
        stardeals_serial     TEXT,
        supabase_order_id    INTEGER,
        transaction_date     TEXT,
        paid_at              TEXT,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at           TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sales_order_item (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_order_id  INTEGER NOT NULL REFERENCES sales_order(id) ON DELETE CASCADE,
        item_id         INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_barcode    TEXT,
        item_name       TEXT,
        quantity        INTEGER NOT NULL DEFAULT 1,
        unit_price      REAL    NOT NULL,
        amount          REAL    NOT NULL,
        is_disc_exempt  INTEGER NOT NULL DEFAULT 0,
        item_discount   REAL    NOT NULL DEFAULT 0,
        notes           TEXT,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS order_item_option (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_order_item_id INTEGER NOT NULL REFERENCES sales_order_item(id) ON DELETE CASCADE,
        option_group_id     INTEGER REFERENCES option_group(id) ON DELETE SET NULL,
        option_value_id     INTEGER REFERENCES option_value(id) ON DELETE SET NULL,
        option_group_name   TEXT,
        option_value_name   TEXT,
        price_delta         REAL    NOT NULL DEFAULT 0,
        quantity            REAL    NOT NULL DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS order_removal_log (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_order_id  INTEGER REFERENCES sales_order(id) ON DELETE SET NULL,
        dining_table_id INTEGER REFERENCES dining_table(id) ON DELETE SET NULL,
        cashier_id      INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        item_id         INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_name       TEXT,
        quantity        REAL,
        price           REAL,
        payment_status  INTEGER,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS split_bill_session (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_order_id      INTEGER NOT NULL REFERENCES sales_order(id) ON DELETE RESTRICT,
        number_of_splits    INTEGER NOT NULL,
        status              INTEGER NOT NULL DEFAULT 0,
        created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS split_bill (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        split_bill_session_id   INTEGER NOT NULL REFERENCES split_bill_session(id) ON DELETE CASCADE,
        split_number            INTEGER NOT NULL,
        sales_order_id          INTEGER NOT NULL REFERENCES sales_order(id) ON DELETE RESTRICT,
        total_amount            REAL    NOT NULL,
        guest_count             INTEGER NOT NULL DEFAULT 1,
        discount_id             INTEGER REFERENCES discount(id) ON DELETE SET NULL,
        discount_amount         REAL    NOT NULL DEFAULT 0,
        payment_type            INTEGER,
        payment_reference       TEXT,
        cashier_id              INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        status                  INTEGER NOT NULL DEFAULT 0,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now')),
        paid_at                 TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS split_bill_item (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        split_bill_id           INTEGER NOT NULL REFERENCES split_bill(id) ON DELETE CASCADE,
        split_bill_session_id   INTEGER NOT NULL REFERENCES split_bill_session(id) ON DELETE CASCADE,
        original_order_item_id  INTEGER REFERENCES sales_order_item(id) ON DELETE SET NULL,
        item_barcode            TEXT,
        item_name               TEXT,
        quantity                INTEGER NOT NULL,
        amount                  REAL    NOT NULL,
        is_disc_exempt          INTEGER NOT NULL DEFAULT 0,
        item_discount           REAL    NOT NULL DEFAULT 0,
        status                  INTEGER NOT NULL DEFAULT 0,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS payment_method (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        code        TEXT    NOT NULL UNIQUE,
        name        TEXT    NOT NULL,
        is_active   INTEGER NOT NULL DEFAULT 1
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sale_transaction (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        sales_order_id       INTEGER REFERENCES sales_order(id) ON DELETE SET NULL,
        cashier_id           INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        si_number            INTEGER,
        tseq_no              INTEGER,
        seq_no               INTEGER,
        z_number             INTEGER,
        order_type_id        INTEGER REFERENCES order_type(id) ON DELETE SET NULL,
        guest_count          INTEGER NOT NULL DEFAULT 1,
        eligible_guest_count INTEGER NOT NULL DEFAULT 0,
        gross_amount         REAL    NOT NULL DEFAULT 0,
        discount_amount      REAL    NOT NULL DEFAULT 0,
        item_discount_amount REAL    NOT NULL DEFAULT 0,
        surcharge_amount     REAL    NOT NULL DEFAULT 0,
        surcharge_percent    REAL    NOT NULL DEFAULT 0,
        net_amount           REAL    NOT NULL DEFAULT 0,
        vat_sales            REAL    NOT NULL DEFAULT 0,
        vat_amount           REAL    NOT NULL DEFAULT 0,
        vat_exempt           REAL    NOT NULL DEFAULT 0,
        vat_zero_rated       REAL    NOT NULL DEFAULT 0,
        vat_private          REAL    NOT NULL DEFAULT 0,
        non_vat_sales        REAL    NOT NULL DEFAULT 0,
        discount_id          INTEGER REFERENCES discount(id) ON DELETE SET NULL,
        coupon_id            INTEGER REFERENCES coupon(id) ON DELETE SET NULL,
        status               INTEGER NOT NULL DEFAULT 1,
        is_voided            INTEGER NOT NULL DEFAULT 0,
        x_read_status        INTEGER NOT NULL DEFAULT 0,
        transaction_date     TEXT    NOT NULL,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at            TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transaction_line (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_transaction_id  INTEGER NOT NULL REFERENCES sale_transaction(id) ON DELETE CASCADE,
        item_id              INTEGER REFERENCES item(id) ON DELETE SET NULL,
        barcode              TEXT,
        item_name            TEXT,
        category_name        TEXT,
        department_name      TEXT,
        quantity             REAL     NOT NULL DEFAULT 1,
        unit_price           REAL     NOT NULL,
        gross_price          REAL     NOT NULL,
        amount               REAL     NOT NULL,
        gross_amount         REAL     NOT NULL,
        cost_price           REAL     NOT NULL DEFAULT 0,
        deduction            REAL     NOT NULL DEFAULT 0,
        added_amount         REAL     NOT NULL DEFAULT 0,
        surcharge            REAL     NOT NULL DEFAULT 0,
        disc_type            INTEGER,
        disc_fixed_amt       REAL     NOT NULL DEFAULT 0,
        disc_percent         REAL     NOT NULL DEFAULT 0,
        is_disc_exempt       INTEGER  NOT NULL DEFAULT 0,
        vat_sales            REAL     NOT NULL DEFAULT 0,
        vat_amount           REAL     NOT NULL DEFAULT 0,
        non_vat              REAL     NOT NULL DEFAULT 0,
        vat_exempt_sales     REAL    NOT NULL DEFAULT 0,
        vat_private          REAL     NOT NULL DEFAULT 0,
        zero_rated           REAL     NOT NULL DEFAULT 0,
        item_type            INTEGER,
        order_type_id        INTEGER,
        box_barcode          TEXT,
        tax_code             INTEGER,
        customization_key    TEXT,
        customization_seq    INTEGER
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS payment (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_transaction_id  INTEGER NOT NULL REFERENCES sale_transaction(id) ON DELETE RESTRICT,
        cashier_id           INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        payment_method_id    INTEGER NOT NULL REFERENCES payment_method(id) ON DELETE RESTRICT,
        amount               REAL    NOT NULL,
        gross_price          REAL    NOT NULL DEFAULT 0,
        gross_amount         REAL    NOT NULL DEFAULT 0,
        vat_sales            REAL    NOT NULL DEFAULT 0,
        vat_amount           REAL    NOT NULL DEFAULT 0,
        non_vat              REAL    NOT NULL DEFAULT 0,
        vat_exempt           REAL    NOT NULL DEFAULT 0,
        vat_private          REAL    NOT NULL DEFAULT 0,
        zero_rated           REAL    NOT NULL DEFAULT 0,
        cash_tendered        REAL,
        change_given         REAL,
        bank_id              INTEGER REFERENCES bank(id) ON DELETE SET NULL,
        card_number          TEXT,
        card_expiry          TEXT,
        approval_number      TEXT,
        reference_number     TEXT,
        merchant_terminal    TEXT,
        payment_channel      TEXT,
        card_type            INTEGER,
        cashless_amount      REAL,
        excess_amount        REAL,
        gift_check_id        INTEGER REFERENCES gift_check(id) ON DELETE SET NULL,
        gift_check_qty       INTEGER,
        serial_numbers       TEXT,
        charge_account_id    INTEGER REFERENCES charge_payment(id) ON DELETE SET NULL,
        x_read_status        INTEGER NOT NULL DEFAULT 0,
        z_number             INTEGER,
        status               INTEGER NOT NULL DEFAULT 1,
        transaction_date     TEXT    NOT NULL,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at            TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS charge_payment (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        code            INTEGER NOT NULL UNIQUE,
        name            TEXT    NOT NULL,
        charge_type     INTEGER,
        is_active       INTEGER NOT NULL DEFAULT 1,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS payment_deposit (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_transaction_id  INTEGER REFERENCES sale_transaction(id) ON DELETE SET NULL,
        cashier_id           INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        deposit_name         TEXT    NOT NULL,
        deposit_amount       REAL    NOT NULL,
        reason               TEXT,
        z_number             INTEGER,
        x_read_status        INTEGER NOT NULL DEFAULT 0,
        status               INTEGER NOT NULL DEFAULT 1,
        transaction_date     TEXT   NOT NULL,
        created_at           TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at            TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS void_transaction (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        original_transaction_id INTEGER REFERENCES sale_transaction(id) ON DELETE SET NULL,
        original_tseq_no        INTEGER,
        new_tseq_no             INTEGER,
        item_id                 INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_barcode            TEXT,
        item_name               TEXT,
        price                   REAL,
        quantity                REAL,
        void_reason_id          INTEGER REFERENCES void_reason(id) ON DELETE SET NULL,
        cashier_id              INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        authorized_by_id        INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        machine_number          INTEGER,
        z_number                INTEGER,
        x_read_status           INTEGER NOT NULL DEFAULT 0,
        transaction_date        TEXT    NOT NULL,
        created_at              TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at               TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cash_declaration (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id       INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        tseq_no          INTEGER,
        total_cash       REAL,
        total_amount     REAL,
        card_count       INTEGER,
        check_count      INTEGER,
        gift_check_count INTEGER,
        account_count    INTEGER,
        atm_count        INTEGER,
        other_count      INTEGER,
        change_fund      REAL,
        z_number         INTEGER,
        x_read_status    INTEGER NOT NULL DEFAULT 0,
        status           INTEGER NOT NULL DEFAULT 1,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at        TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cash_declaration_denomination (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        cash_declaration_id INTEGER NOT NULL REFERENCES cash_declaration(id) ON DELETE CASCADE,
        denomination        REAL    NOT NULL,
        quantity            INTEGER NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cash_fund_log (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id       INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        authorized_by_id INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        tseq_no          INTEGER,
        movement_type    INTEGER NOT NULL CHECK(movement_type IN (0,1)),
        amount           REAL    NOT NULL,
        reason           TEXT,
        z_number         INTEGER,
        x_read_status    INTEGER NOT NULL DEFAULT 0,
        status           INTEGER NOT NULL DEFAULT 1,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at        TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS deposit (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id       INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        tseq_no          INTEGER,
        deposit_amount   REAL    NOT NULL,
        z_number         INTEGER,
        x_read_status    INTEGER NOT NULL DEFAULT 0,
        status           INTEGER NOT NULL DEFAULT 0,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at        TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS short_over (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id        INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        tseq_no           INTEGER,
        short_amount      REAL,
        over_amount       REAL,
        total_cash        REAL,
        change_fund       REAL,
        total_collected   REAL,
        theoretical_sales REAL,
        actual_cash       REAL,
        short_over_amount REAL,
        z_number          INTEGER,
        status            INTEGER NOT NULL DEFAULT 1,
        transaction_date  TEXT   NOT NULL,
        created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at         TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS daily_summary (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id        INTEGER NOT NULL REFERENCES app_user(id) ON DELETE RESTRICT,
        tseq_no           INTEGER,
        z_number          INTEGER,
        cash_amount       REAL,
        cash_count        INTEGER,
        charge_amount     REAL,
        charge_count      INTEGER,
        atm_amount        REAL,
        atm_count         INTEGER,
        card_amount       REAL,
        card_count        INTEGER,
        check_amount      REAL,
        check_count       INTEGER,
        gift_check_amount REAL,
        gift_check_count  INTEGER,
        cash_in           REAL,
        cash_out          REAL,
        discount_amount   REAL,
        discount_count    INTEGER,
        net_sales         REAL,
        sales_count       INTEGER,
        deposit_amount    REAL,
        guest_count       INTEGER,
        transaction_date  TEXT   NOT NULL,
        created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at         TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock_receipt (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id       INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        purpose_id       INTEGER REFERENCES fund_movement_purpose(id) ON DELETE SET NULL,
        supplier_id      INTEGER REFERENCES supplier(id) ON DELETE SET NULL,
        po_number        TEXT,
        approval_number  TEXT,
        reference_number TEXT,
        remarks          TEXT,
        total_amount     REAL,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock_receipt_line (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_receipt_id INTEGER NOT NULL REFERENCES stock_receipt(id) ON DELETE CASCADE,
        item_id          INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_code        TEXT,
        barcode          TEXT,
        quantity         REAL    NOT NULL DEFAULT 0,
        unit_id          INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        pieces           INTEGER,
        boxes            INTEGER,
        unit_price       REAL,
        amount           REAL,
        serial_number    TEXT,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock_issue (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id       INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        purpose_id       INTEGER REFERENCES fund_movement_purpose(id) ON DELETE SET NULL,
        supplier_id      INTEGER REFERENCES supplier(id) ON DELETE SET NULL,
        reference        TEXT,
        po_number        TEXT,
        remarks          TEXT,
        total_amount     REAL,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS stock_issue_line (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_issue_id  INTEGER NOT NULL REFERENCES stock_issue(id) ON DELETE CASCADE,
        item_id         INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_code       TEXT,
        barcode         TEXT,
        quantity        REAL    NOT NULL DEFAULT 0,
        unit_id         INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        pieces          INTEGER,
        boxes           INTEGER,
        unit_price      REAL,
        amount          REAL,
        serial_number   TEXT,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS physical_count (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id        INTEGER NOT NULL REFERENCES item(id) ON DELETE CASCADE,
        item_code      TEXT,
        item_name      TEXT,
        counted_qty    REAL    NOT NULL DEFAULT 0,
        previous_count REAL,
        last_count     REAL,
        variance       REAL,
        reorder_level  INTEGER,
        beginning_inv  INTEGER,
        min_level      INTEGER,
        max_level      INTEGER,
        unit_id        INTEGER REFERENCES unit(id) ON DELETE SET NULL,
        cost_price     REAL,
        count_date     TEXT    NOT NULL,
        posted_at      TEXT,
        created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at     TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cogs_line (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_transaction_id INTEGER REFERENCES sale_transaction(id) ON DELETE SET NULL,
        tseq_no             INTEGER,
        parent_item_id      INTEGER REFERENCES item(id) ON DELETE SET NULL,
        component_item_id   INTEGER REFERENCES item(id) ON DELETE SET NULL,
        quantity            REAL    NOT NULL,
        cost_price          REAL    NOT NULL,
        amount              REAL    NOT NULL,
        cashier_id          INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        z_number            INTEGER,
        status              INTEGER NOT NULL DEFAULT 1,
        transaction_date    TEXT   NOT NULL,
        created_at          TEXT    NOT NULL DEFAULT (datetime('now')),
        posted_at           TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS discount_beneficiary (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_transaction_id INTEGER REFERENCES sale_transaction(id) ON DELETE SET NULL,
        tseq_no             INTEGER,
        discount_type_id    INTEGER NOT NULL REFERENCES discount_type(id) ON DELETE RESTRICT,
        beneficiary_name    TEXT    NOT NULL,
        id_number           TEXT,
        tin_number          TEXT,
        address             TEXT,
        child_name          TEXT,
        child_birthdate     TEXT,
        child_age           INTEGER,
        status              INTEGER NOT NULL DEFAULT 1,
        created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS customer (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        tseq_no        INTEGER,
        omt_ref_no     TEXT,
        name           TEXT    NOT NULL,
        address        TEXT,
        tin_number     TEXT,
        business_style TEXT,
        created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at     TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS kds_order (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number      TEXT,
        dining_table_name TEXT,
        customer_name     TEXT,
        overall_status    TEXT    NOT NULL DEFAULT 'preparing' CHECK(overall_status IN ('preparing','ready','completed','cancelled')),
        received_at       TEXT    NOT NULL DEFAULT (datetime('now')),
        completed_at      TEXT,
        created_at        TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS kds_order_item (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        kds_order_id  INTEGER NOT NULL REFERENCES kds_order(id) ON DELETE CASCADE,
        item_name     TEXT    NOT NULL,
        quantity      INTEGER NOT NULL DEFAULT 1,
        options       TEXT,
        customization TEXT,
        notes         TEXT,
        status        TEXT    NOT NULL DEFAULT 'preparing' CHECK(status IN ('preparing','ready','picked_up','completed','cancelled')),
        ready_at      TEXT,
        picked_up_at  TEXT,
        completed_at  TEXT,
        cancelled_at  TEXT,
        created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS kds_settings (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        is_server   INTEGER NOT NULL DEFAULT 0,
        server_ip   TEXT,
        server_port INTEGER,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS bir_config (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name         TEXT,
        branch_name          TEXT,
        address_line_1       TEXT,
        address_line_2       TEXT,
        address_line_3       TEXT,
        address_line_4       TEXT,
        tin                  TEXT,
        serial_number        TEXT,
        min_number           TEXT,
        permit_number        TEXT,
        accreditation_number TEXT,
        machine_number       TEXT,
        location             TEXT,
        date_issued          TEXT,
        receipt_footer_1     TEXT,
        receipt_footer_2     TEXT,
        receipt_footer_3     TEXT,
        receipt_footer_4     TEXT,
        receipt_footer_5     TEXT,
        updated_at           TEXT NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS printer_config (
        id                       INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_printer          TEXT,
        printer_1                TEXT,
        printer_2                TEXT,
        printer_3                TEXT,
        document_printer         TEXT,
        receipt_net_printer      TEXT,
        net_printer_1            TEXT,
        net_printer_2            TEXT,
        net_printer_3            TEXT,
        document_net_printer     TEXT,
        usb_printer_1            TEXT,
        usb_printer_2            TEXT,
        usb_printer_3            TEXT,
        usb_label_printer        TEXT,
        printout_copies          INTEGER NOT NULL DEFAULT 1,
        order_slip_copies        INTEGER NOT NULL DEFAULT 1,
        post_void_copies         INTEGER NOT NULL DEFAULT 1,
        cash_receipt_copies      INTEGER NOT NULL DEFAULT 1,
        charge_receipt_copies    INTEGER NOT NULL DEFAULT 1,
        bank_receipt_copies      INTEGER NOT NULL DEFAULT 1,
        print_change_fund        INTEGER NOT NULL DEFAULT 0,
        print_sales_invoice      INTEGER NOT NULL DEFAULT 0,
        print_tempo_bill         INTEGER NOT NULL DEFAULT 0,
        print_order_slip         INTEGER NOT NULL DEFAULT 0,
        print_tender_declaration INTEGER NOT NULL DEFAULT 0,
        print_x_read             INTEGER NOT NULL DEFAULT 0,
        print_z_read             INTEGER NOT NULL DEFAULT 0,
        print_post_void          INTEGER NOT NULL DEFAULT 0,
        updated_at               TEXT NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS email_config (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        client_email    TEXT,
        client_password TEXT,
        recipient_email TEXT,
        updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS operating_hours (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        day_of_week INTEGER NOT NULL CHECK(day_of_week BETWEEN 0 AND 6),
        open_time   TEXT,
        close_time  TEXT,
        is_closed   INTEGER NOT NULL DEFAULT 0
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS connected_terminal (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        device_info     TEXT    NOT NULL,
        ip_address      TEXT    NOT NULL,
        dining_table_id INTEGER REFERENCES dining_table(id) ON DELETE SET NULL,
        floor_id        INTEGER REFERENCES floor(id) ON DELETE SET NULL,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS second_screen_ad (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        media_type  TEXT,
        file_path   TEXT    NOT NULL,
        position    INTEGER,
        date_start  TEXT,
        date_end    TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS live_sync_setting (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        key         TEXT    NOT NULL UNIQUE,
        type        TEXT    NOT NULL,
        value       TEXT    NOT NULL,
        created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sync_status (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name      TEXT    NOT NULL,
        record_id       INTEGER NOT NULL,
        backend         TEXT    NOT NULL,
        sync_status     TEXT    NOT NULL DEFAULT 'pending' CHECK(sync_status IN ('pending','synced','failed')),
        operation_type  TEXT    NOT NULL DEFAULT 'update' CHECK(operation_type IN ('insert','update','delete')),
        priority        INTEGER NOT NULL DEFAULT 2,
        attempt_count   INTEGER NOT NULL DEFAULT 0,
        max_attempts    INTEGER NOT NULL DEFAULT 3,
        last_attempt_at TEXT,
        next_retry_at   TEXT,
        last_synced_at  TEXT,
        error_message   TEXT,
        created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS counter_table (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        tseq_no         INTEGER NOT NULL DEFAULT 0,
        si_number       INTEGER NOT NULL DEFAULT 0,
        z_read_count    INTEGER NOT NULL DEFAULT 0,
        post_void_count INTEGER NOT NULL DEFAULT 0,
        so_number       INTEGER NOT NULL DEFAULT 1,
        incoming_number INTEGER NOT NULL DEFAULT 1,
        outgoing_number INTEGER NOT NULL DEFAULT 1,
        deposit_number  INTEGER NOT NULL DEFAULT 1,
        trans_number    INTEGER NOT NULL DEFAULT 0,
        last_updated    TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS dtr_record (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id          INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        user_code        TEXT,
        time_in          TEXT,
        time_out         TEXT,
        hours_rendered   REAL    NOT NULL DEFAULT 0,
        status           INTEGER,
        transaction_date TEXT   NOT NULL,
        created_at       TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS usage_log (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id   INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
        username  TEXT,
        module    TEXT    NOT NULL,
        action    TEXT,
        detail    TEXT,
        logged_at TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS self_order (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        order_key      TEXT    NOT NULL UNIQUE,
        order_type_id  INTEGER REFERENCES order_type(id) ON DELETE SET NULL,
        discount_id    INTEGER REFERENCES discount(id) ON DELETE SET NULL,
        guest_count    INTEGER NOT NULL DEFAULT 1,
        payment_status INTEGER NOT NULL DEFAULT 0,
        order_status   INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
        updated_at     TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS self_order_item (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        self_order_id     INTEGER NOT NULL REFERENCES self_order(id) ON DELETE CASCADE,
        item_id           INTEGER REFERENCES item(id) ON DELETE SET NULL,
        item_barcode      TEXT,
        parent_id         INTEGER REFERENCES self_order_item(id) ON DELETE SET NULL,
        quantity          INTEGER NOT NULL DEFAULT 1,
        amount            REAL    NOT NULL,
        customization_key TEXT,
        created_at        TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS self_order_item_option (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        self_order_item_id INTEGER NOT NULL REFERENCES self_order_item(id) ON DELETE CASCADE,
        option_group_name  TEXT,
        option_value_name  TEXT,
        price_delta        REAL    NOT NULL DEFAULT 0
    );
    ''',
  ];

  /// Indexes to accelerate queries across transactions and lookup catalogs.
  static const List<String> createIndexScripts = [
    'CREATE INDEX IF NOT EXISTS idx_item_category ON item(category_id);',
    'CREATE INDEX IF NOT EXISTS idx_item_department ON item(department_id);',
    'CREATE INDEX IF NOT EXISTS idx_item_barcode ON item(barcode);',
    'CREATE INDEX IF NOT EXISTS idx_item_code ON item(item_code);',
    'CREATE INDEX IF NOT EXISTS idx_item_price_item ON item_price(item_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_item ON stock(item_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_order_date ON sales_order(transaction_date);',
    'CREATE INDEX IF NOT EXISTS idx_sales_order_cashier ON sales_order(cashier_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_order_table ON sales_order(dining_table_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_order_status ON sales_order(payment_status);',
    'CREATE INDEX IF NOT EXISTS idx_order_item_order ON sales_order_item(sales_order_id);',
    'CREATE INDEX IF NOT EXISTS idx_sale_transaction_date ON sale_transaction(transaction_date);',
    'CREATE INDEX IF NOT EXISTS idx_sale_transaction_cashier ON sale_transaction(cashier_id);',
    'CREATE INDEX IF NOT EXISTS idx_sale_transaction_z ON sale_transaction(z_number);',
    'CREATE INDEX IF NOT EXISTS idx_sale_transaction_si ON sale_transaction(si_number);',
    'CREATE INDEX IF NOT EXISTS idx_txn_line_txn ON transaction_line(sale_transaction_id);',
    'CREATE INDEX IF NOT EXISTS idx_payment_txn ON payment(sale_transaction_id);',
    'CREATE INDEX IF NOT EXISTS idx_payment_date ON payment(transaction_date);',
    'CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_status(sync_status, priority);',
    'CREATE INDEX IF NOT EXISTS idx_sync_table ON sync_status(table_name, record_id);',
    'CREATE INDEX IF NOT EXISTS idx_user_role ON app_user(role_id);',
    'CREATE INDEX IF NOT EXISTS idx_role_perm_role ON role_permission(role_id);',
  ];

  /// Triggers to automatically maintain `updated_at` timestamps on row updates.
  static const List<String> createTriggerScripts = [
    '''
    CREATE TRIGGER IF NOT EXISTS trg_department_updated
        AFTER UPDATE ON department BEGIN
        UPDATE department SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_category_updated
        AFTER UPDATE ON category BEGIN
        UPDATE category SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_item_updated
        AFTER UPDATE ON item BEGIN
        UPDATE item SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_stock_updated
        AFTER UPDATE ON stock BEGIN
        UPDATE stock SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_sales_order_updated
        AFTER UPDATE ON sales_order BEGIN
        UPDATE sales_order SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
    '''
    CREATE TRIGGER IF NOT EXISTS trg_app_user_updated
        AFTER UPDATE ON app_user BEGIN
        UPDATE app_user SET updated_at = datetime('now') WHERE id = NEW.id;
    END;
    ''',
  ];

  /// Seed data inserted on new database initialization[cite: 2].
  static const List<String> seedScripts = [
    '''
    INSERT OR IGNORE INTO discount_type (code, name) VALUES
        ('generic',     'Generic Discount'),
        ('senior',      'Senior Citizen (GPC)'),
        ('pwd',         'Person with Disability'),
        ('employee',    'Employee Discount'),
        ('vip',         'VIP Discount'),
        ('solo_parent', 'Solo Parent'),
        ('athlete',     'National Athlete'),
        ('custom',      'Custom Discount');
    ''',
    '''
    INSERT OR IGNORE INTO payment_method (code, name) VALUES
        ('cash',       'Cash'),
        ('card',       'Credit/Debit Card'),
        ('atm',        'ATM / Online Banking'),
        ('bank_check', 'Bank Check'),
        ('gift_check', 'Gift Check'),
        ('charge',     'Charge Account'),
        ('coupon',     'Coupon');
    ''',
    '''
    INSERT INTO role (id, name, can_sales_entry, can_sales_order, can_sales_reading, can_sales_inquiry, can_file_maintenance, can_admin_mode, can_dtr_menu, can_kiosk, can_inventory, is_active)
    VALUES (1, 'Superuser', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
    ''',
    '''
    INSERT INTO app_user (id, role_id, name, password_hash, is_active)
    VALUES (1, 1, 'Superuser', '050724', 1);
    ''',
  ];
}
