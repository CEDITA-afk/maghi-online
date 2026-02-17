import 'package:flutter/material.dart';
import '../../models/dice.dart';
import '../../models/enums.dart';
import 'mana_die_widget.dart';

class DiceTray extends StatelessWidget {
  final List<ManaDice> rolledHand;
  final Set<int> selectedIndices;
  final Function(int) onDieTap;

  const DiceTray({
    super.key,
    required this.rolledHand,
    required this.selectedIndices,
    required this.onDieTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rolledHand.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.brown.shade800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("Nessun dado disponibile", style: TextStyle(color: Colors.white54)),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.brown.shade900,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, -4))],
        border: Border(top: BorderSide(color: Colors.brown.shade700, width: 2)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rolledHand.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final die = rolledHand[index];
          final isSelected = selectedIndices.contains(index);

          return GestureDetector(
            onTap: () => onDieTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: isSelected 
                  ? Matrix4.translationValues(0, -15, 0) 
                  : Matrix4.identity(),
              padding: const EdgeInsets.all(2),
              decoration: isSelected 
                ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getGlowColor(die.effectiveElement).withOpacity(0.6), 
                        blurRadius: 20, 
                        spreadRadius: 2
                      )
                    ]
                  ) 
                : null,
              // Ora ManaDieWidget accetta size grazie alla modifica sopra
              child: ManaDieWidget(die: die, size: 60),
            ),
          );
        },
      ),
    );
  }

  Color _getGlowColor(Elemento e) {
    switch (e) {
      case Elemento.rosso: return Colors.red;
      case Elemento.blu: return Colors.blue;
      case Elemento.verde: return Colors.green;
      case Elemento.giallo: return Colors.orange;
      case Elemento.jolly: return Colors.purpleAccent;
      default: return Colors.white;
    }
  }
}