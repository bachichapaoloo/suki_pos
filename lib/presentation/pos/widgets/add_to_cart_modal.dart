import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_cubit.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_state.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/pages/sales_entry_page.dart';
import 'package:suki_pos/presentation/pos/widgets/item_detail_modal_dialog.dart';

/// Opens the item-detail / add-to-cart modal and wires its result straight
/// into [CartCubit] — either adding a new line or, when [existingCartItem]
/// is supplied, updating that line in place.
///
/// This used to be a private method on [SalesEntryPage]'s state; pulling it
/// out means any screen with access to [OptionGroupCubit] and [CartCubit]
/// in its widget tree (product grid, cart list, search results, a future
/// "reorder last sale" screen, etc.) can trigger the same add-to-cart flow
/// with a single call: `AddToCartModal.show(context, item: item)`.
class AddToCartModal {
  const AddToCartModal._();

  static Future<void> show(
    BuildContext context, {
    required Item item,
    CartItem? existingCartItem,
  }) {
    final optionGroupState = context.read<OptionGroupCubit>().state;
    final List<OptionGroup> optionGroups = optionGroupState is OptionGroupLoaded
        ? optionGroupState.optionGroups
        : const <OptionGroup>[];

    final cartCubit = context.read<CartCubit>();

    return showDialog(
      context: context,
      builder: (_) => ItemDetailModalDialog(
        item: item,
        optionGroups: optionGroups,
        existingCartItem: existingCartItem,
        onConfirm:
            ({
              required selectedOptions,
              required quantity,
              notes,
            }) {
              if (existingCartItem != null) {
                // Edit existing item in cart
                final updated = existingCartItem.copyWith(
                  selectedOptions: selectedOptions,
                  quantity: quantity,
                  notes: notes,
                );
                cartCubit.updateCartItem(existingCartItem.id, updated);
              } else {
                // Add new item to cart
                cartCubit.addItem(
                  item: item,
                  selectedOptions: selectedOptions,
                  quantity: quantity,
                  notes: notes,
                );
              }
            },
      ),
    );
  }
}
