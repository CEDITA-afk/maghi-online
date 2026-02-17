import 'package:flutter/material.dart';

class ActionTracker extends StatelessWidget {
  final int actions;
  final VoidCallback onEndTurnManual;

  const ActionTracker({
    super.key,
    required this.actions,
    required this.onEndTurnManual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text("AZIONI: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ...List.generate(2, (i) => Icon(
            Icons.bolt, 
            color: i < actions ? Colors.amber : Colors.grey.shade300,
            size: 24
          )),
          const Spacer(),
          TextButton.icon(
            onPressed: onEndTurnManual,
            icon: const Icon(Icons.skip_next, size: 16, color: Colors.red),
            label: const Text("PASSA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red, width: 1))
            ),
          )
        ],
      ),
    );
  }
}