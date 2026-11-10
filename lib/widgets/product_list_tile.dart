// lib/widgets/product_list_tile.dart
//This widget displays a product in a list format, showing its brand, size, price, stock status, and delivery information. It includes an icon representing the gas cylinder size and color-coded indicators for stock availability. The widget also provides optional edit and delete buttons for vendors to manage their products directly from the list.
import 'package:flutter/material.dart';
import 'gas_cylinder_icon.dart';

import '../core/theme_ext.dart';

class ProductListTile extends StatelessWidget {
  final String brand;
  final String size;
  final double price;
  final bool inStock;
  final String deliveryText;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ProductListTile({
    super.key,
    required this.brand,
    required this.size,
    required this.price,
    required this.inStock,
    required this.deliveryText,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Gas Icon
              GasCylinderIcon(weight: size, inStock: inStock),
              const SizedBox(width: 12),

              // 2. Middle Info Column (Wrapped in Expanded to prevent vertical text squishing)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$brand — $size',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TZS ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deliveryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Right Status Tag & Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          inStock ? context.gasColors.successContainer : context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inStock
                            ? context.gasColors.success
                            : context.colors.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          inStock
                              ? Icons.check_circle
                              : Icons.pause_circle_outline,
                          size: 14,
                          color: inStock
                              ? context.gasColors.success
                              : context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inStock ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: inStock
                                ? context.gasColors.success
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: context.gasColors.info,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: context.colors.error,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
