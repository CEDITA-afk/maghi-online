import 'package:flutter/material.dart';
import '../../models/enums.dart';

class HeroSelectorView extends StatelessWidget {
  final List<Elemento> actedHeroes; // Chi ha già agito
  final List<Elemento> activeElements; // Chi è in partita (configurazione setup)
  final Function(Elemento) onSelected;

  const HeroSelectorView({
    super.key, 
    required this.actedHeroes, 
    required this.activeElements,
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("CHI AGISCE ORA?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Scegli un Mago per il prossimo turno", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // Genera pulsanti solo per i maghi attivi
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: activeElements.map((e) {
              bool done = actedHeroes.contains(e);
              return Opacity(
                opacity: done ? 0.3 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: done ? null : () => onSelected(e),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(), 
                        padding: const EdgeInsets.all(24),
                        backgroundColor: _getColor(e),
                        elevation: done ? 0 : 5,
                      ),
                      child: Icon(_getIcon(e), color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 8),
                    if (done) 
                      const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    else 
                      Text(e.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Color _getColor(Elemento e) {
    if (e == Elemento.rosso) return Colors.red;
    if (e == Elemento.blu) return Colors.blue;
    if (e == Elemento.verde) return Colors.green;
    return Colors.orange;
  }

  IconData _getIcon(Elemento e) {
    if (e == Elemento.rosso) return Icons.local_fire_department;
    if (e == Elemento.blu) return Icons.water_drop;
    if (e == Elemento.verde) return Icons.grass;
    return Icons.flash_on;
  }
}