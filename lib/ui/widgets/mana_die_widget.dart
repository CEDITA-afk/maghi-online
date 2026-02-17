import 'package:flutter/material.dart';
import '../../models/dice.dart';
import '../../models/enums.dart';

class ManaDieWidget extends StatelessWidget {
  final ManaDice die;
  final double size;

  const ManaDieWidget({
    super.key, 
    required this.die,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    // Colore del Bordo (Il dado fisico / Archetipo)
    Color sourceColor = _getColor(die.sourceColor);
    
    // Colore del Risultato (L'energia)
    Color faceColor = _getColor(die.effectiveElement);
    
    // Icona centrale
    IconData icon = _getIcon(die.effectiveElement);
    
    // Gestione visuale Jolly
    if (die.effectiveElement == Elemento.jolly) {
      faceColor = Colors.grey.shade900;
    }

    // Se il colore interno è uguale al bordo, serve contrasto
    bool isPure = die.effectiveElement == die.sourceColor;

    return Container(
      width: size, 
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: faceColor, 
        borderRadius: BorderRadius.circular(12),
        // BORDO ESTERNO (Colore Archetipo)
        border: Border.all(
          color: sourceColor, 
          width: size * 0.15, // Aumentato spessore (15% della size)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(2, 2)
          )
        ]
      ),
      child: Container(
        // BORDO INTERNO SOTTILE (Per contrasto se Puro)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isPure 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)
            : null,
        ),
        alignment: Alignment.center,
        child: die.effectiveElement == Elemento.jolly 
          ? Icon(Icons.star, color: Colors.amber, size: size * 0.5)
          : Icon(icon, color: Colors.white.withOpacity(0.95), size: size * 0.5),
      ),
    );
  }

  Color _getColor(Elemento e) {
    switch (e) {
      case Elemento.rosso: return Colors.red.shade700;
      case Elemento.blu: return Colors.blue.shade700;
      case Elemento.verde: return Colors.green.shade700;
      case Elemento.giallo: return Colors.orange.shade700;
      case Elemento.jolly: return Colors.black;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(Elemento e) {
    switch (e) {
      case Elemento.rosso: return Icons.local_fire_department;
      case Elemento.blu: return Icons.water_drop;
      case Elemento.verde: return Icons.grass;
      case Elemento.giallo: return Icons.flash_on;
      default: return Icons.question_mark;
    }
  }
}