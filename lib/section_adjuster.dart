import 'package:flutter/material.dart';

class SectionAdjuster extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  const SectionAdjuster({
    required this.label,
    required this.value,
    this.onAdd,
    this.onRemove,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onRemove,
            splashRadius: 18,
            color: Colors.deepPurple.shade400,
          ),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onAdd,
            splashRadius: 18,
            color: Colors.deepPurple.shade400,
          ),
        ],
      ),
    );
  }
}
