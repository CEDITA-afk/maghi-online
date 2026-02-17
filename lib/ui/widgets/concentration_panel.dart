import 'package:flutter/material.dart';

class ConcentrationPanel extends StatelessWidget {
  final int selectedDiceCount;
  final int currentEnergy;
  final VoidCallback onConvert; // Dado -> Energia
  final VoidCallback onReroll;  // Energia -> Reroll
  final VoidCallback onKeep;    // Energia -> Keep

  const ConcentrationPanel({
    super.key,
    required this.selectedDiceCount,
    required this.currentEnergy,
    required this.onConvert,
    required this.onReroll,
    required this.onKeep,
  });

  @override
  Widget build(BuildContext context) {
    // Mostriamo il pannello solo se ci sono dadi selezionati
    if (selectedDiceCount == 0) return const SizedBox.shrink();

    bool canPay = currentEnergy >= selectedDiceCount; // 1 Energia per dado

    return Container(
      color: Colors.purple.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Text("CONCENTRAZIONE:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
          
          // CONVERTI (Dadi -> Energia)
          TextButton.icon(
            onPressed: onConvert,
            icon: const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
            label: const Text("Converti (+En)", style: TextStyle(fontSize: 12)),
          ),

          // REROLL (Energia -> Dadi)
          TextButton.icon(
            onPressed: canPay ? onReroll : null,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
            label: Text("Reroll (-${selectedDiceCount}En)", style: const TextStyle(fontSize: 12)),
          ),

          // KEEP (Energia -> Dadi Salvati)
          TextButton.icon(
            onPressed: canPay && selectedDiceCount == 1 ? onKeep : null, // Limitiamo Keep a 1 per semplicità o regola
            icon: const Icon(Icons.save, size: 16, color: Colors.blue),
            label: const Text("Salva (-1En)", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}