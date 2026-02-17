import 'package:flutter/material.dart';
import '../../models/spell.dart';
import '../../models/enums.dart';

class SpellCard extends StatelessWidget {
  final Spell spell;
  final bool isCastable;
  final VoidCallback? onTap; // Questa è la funzione passata dallo screen

  const SpellCard({
    super.key, 
    required this.spell, 
    this.isCastable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isCastable ? 1.0 : 0.4,
      child: Card(
        elevation: isCastable ? 4 : 1,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isCastable ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        // L'InkWell rende la carta cliccabile
        child: InkWell(
          onTap: onTap, 
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(spell.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildCostIcons(spell.costo),
                  ],
                ),
                const Divider(),
                Text(spell.effetto, style: const TextStyle(fontSize: 14)),
                if (isCastable)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("CLICCA PER LANCIARE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostIcons(List<Elemento> costo) {
    return Row(
      children: costo.map((e) => Container(
        margin: const EdgeInsets.only(left: 4),
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: e == Elemento.rosso ? Colors.red : e == Elemento.blu ? Colors.blue : e == Elemento.verde ? Colors.green : Colors.orange,
          shape: BoxShape.circle
        ),
      )).toList(),
    );
  }
}