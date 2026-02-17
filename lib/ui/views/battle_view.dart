import 'package:flutter/material.dart';
import '../../models/spell.dart';
import '../../models/dice.dart';
import '../../models/enums.dart';
import '../widgets/spell_card.dart';

class BattleView extends StatelessWidget {
  final List<Spell> deck;
  final List<ManaDice> hand;
  final int actions;
  final Function(Spell) onCast;
  final Elemento activeElement;

  const BattleView({
    super.key,
    required this.deck,
    required this.hand,
    required this.actions,
    required this.onCast,
    required this.activeElement,
  });

  @override
  Widget build(BuildContext context) {
    if (deck.isEmpty) {
      return const Center(child: Text("Grimorio vuoto!", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: deck.length,
      // Padding inferiore per evitare che l'ultima carta sia coperta dal DiceTray
      padding: const EdgeInsets.only(bottom: 100, top: 8, left: 8, right: 8),
      itemBuilder: (context, index) {
        final spell = deck[index];
        
        // Verifica se la magia può essere lanciata
        bool canCast = actions > 0 && spell.canBeCast(hand);

        return SpellCard(
          spell: spell,
          isCastable: canCast,
          onTap: canCast ? () => onCast(spell) : null,
        );
      },
    );
  }
}