/// Reusable modal & confirmation dialog variants.
enum DialogVariant { info, warning, danger, success }

/// Discount calculation modes.
enum DiscountType { percentage, fixed }

/// Bottom / side navigation main tabs.
enum MainTab { home, sales, inventory, reports }

/// Inventory stock adjustment direction.
enum AdjustmentType { stockIn, stockOut }

/// POS Sales Entry top-bar overflow actions.
enum PosMenuAction {
  postVoid,
  reprint,
  ejLog,
  xReading,
  zReading,
  shiftReconciliation,
  tenderDeclaration,
  // stockAdjustment,
}
