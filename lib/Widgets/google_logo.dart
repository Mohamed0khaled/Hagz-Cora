// Placeholder Google logo widget since we don't have the actual asset
import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  
  const GoogleLogoWidget({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
