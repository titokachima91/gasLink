// lib/widgets/gas_cylinder_icon.dart
//This widget displays a gas cylinder icon with dynamic sizing based on the cylinder's weight. It visually indicates whether the cylinder is in stock or out of stock by changing its color. The widget is used in product listings to represent different gas cylinder sizes and their availability status.
import 'package:flutter/material.dart';

class GasCylinderIcon extends StatelessWidget {
  final String weight;
  final bool inStock;

  const GasCylinderIcon({
    super.key,
    required this.weight,
    this.inStock = true,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing based on cylinder weight
    double height = 36.0;
    double width = 24.0;

    final normalizedWeight = weight.toLowerCase().replaceAll(' ', '');
    if (normalizedWeight.contains('3kg')) {
      height = 28.0;
      width = 20.0;
    } else if (normalizedWeight.contains('6kg')) {
      height = 36.0;
      width = 24.0;
    } else if (normalizedWeight.contains('15kg')) {
      height = 46.0;
      width = 28.0;
    } else if (normalizedWeight.contains('38kg') ||
        normalizedWeight.contains('40kg')) {
      height = 56.0;
      width = 30.0;
    }

    final baseColor = inStock ? Colors.orange.shade700 : Colors.grey.shade500;

    return Container(
      width: 52,
      height: 60,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Base shadow
          Container(
            width: width + 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Gas Cylinder Body
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top handle ring
                Container(
                  height: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Weight text label
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    weight.replaceAll('kg', '').replaceAll('KG', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
