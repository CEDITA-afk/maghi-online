import 'package:flutter/material.dart';
import '../../../models/spell.dart';
import '../../../models/enums.dart';
import '../../widgets/spell_card.dart';

class SpellSelectionView extends StatefulWidget {
  final Elemento element;
  final List<Spell> allSpells;
  final List<Spell> initialSelection;
  final Function(List<Spell>) onConfirm;

  const SpellSelectionView({
    super.key,
    required this.element,
    required this.allSpells,
    required this.initialSelection,
    required this.onConfirm,
  });

  @override
  State<SpellSelectionView> createState() => _SpellSelectionViewState();
}

class _SpellSelectionViewState extends State<SpellSelectionView> {
  // Mappa che collega l'indice dello slot (0-9) alla magia selezionata
  final Map<int, Spell> _selectedSlots = {};
  late final List<SlotDefinition> _slotRules;

  @override
  void initState() {
    super.initState();
    _initSlotRules();
    
    // Tentativo di ripristinare selezione precedente
    for (int i = 0; i < widget.initialSelection.length && i < 10; i++) {
       _selectedSlots[i] = widget.initialSelection[i];
    }
  }

  void _initSlotRules() {
    _slotRules = [
      SlotDefinition(
        id: 0, 
        title: "Slot 1: Base", 
        subtitle: "Tier 1 - Costo 1 [Puro]", 
        filter: (s) => s.costo.length == 1 && _isPure(s)
      ),
      SlotDefinition(
        id: 1, 
        title: "Slot 2: Core", 
        subtitle: "Tier 2 - Costo 2 [Puro]", 
        filter: (s) => s.costo.length == 2 && _isPure(s)
      ),
      SlotDefinition(
        id: 2, 
        title: "Slot 3: Utility", 
        subtitle: "Tier 1.5 - Costo 1 [P] + 1 [Altro]", 
        filter: (s) => s.costo.length == 2 && !_isPure(s)
      ),
      SlotDefinition(
        id: 3, 
        title: "Slot 4: Impatto", 
        subtitle: "Tier 3 - Costo 2 [P] + 1 [Altro]", 
        filter: (s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate
      ),
      SlotDefinition(
        id: 4, 
        title: "Slot 5: Finisher", 
        subtitle: "Tier 4 - ULTIMATE (Costo 3+)", 
        filter: (s) => s.categoria == CategoriaIncantesimo.ultimate
      ),
      SlotDefinition(
        id: 5, 
        title: "Slot 6: Sinergia", 
        subtitle: "Tier 2 - Ibrido Leggero (1 [P] + 1 [S])", 
        filter: (s) => s.costo.length == 2 && !_isPure(s)
      ),
      SlotDefinition(
        id: 6, 
        title: "Slot 7: Evocazione / Heavy", 
        subtitle: "Tier 3 - Ibrido Heavy (2 [P] + 1 [S])", 
        filter: (s) => s.costo.length == 3 && !_isPure(s) && s.categoria != CategoriaIncantesimo.ultimate
      ),
      SlotDefinition(
        id: 7, 
        title: "Slot 8: Tecnica", 
        subtitle: "Tier 4 - Prismatico / Complesso", 
        filter: (s) => s.costo.length >= 3 && !_isPure(s)
      ),
      SlotDefinition(
        id: 8, 
        title: "Slot 9: Libero", 
        subtitle: "Wildcard (Qualsiasi)", 
        filter: (s) => true
      ),
      SlotDefinition(
        id: 9, 
        title: "Slot 10: Libero", 
        subtitle: "Wildcard (Qualsiasi)", 
        filter: (s) => true
      ),
    ];
  }

  bool _isPure(Spell s) {
    return s.costo.every((c) => c == widget.element);
  }

  void _openSpellPicker(int slotIndex) {
    final rule = _slotRules[slotIndex];
    
    final validSpells = widget.allSpells.where((spell) {
      // 1. Rispetta la regola dello slot?
      if (!rule.filter(spell)) return false;
      
      // 2. È già stata presa in un altro slot?
      bool alreadyPicked = false;
      _selectedSlots.forEach((key, value) {
        if (key != slotIndex && value == spell) alreadyPicked = true;
      });
      return !alreadyPicked;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getElementColor(widget.element),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Scegli per ${rule.title}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(rule.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white))
                ],
              ),
            ),
            Expanded(
              child: validSpells.isEmpty 
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Nessuna magia disponibile per questo criterio (o tutte quelle valide sono già usate).", textAlign: TextAlign.center),
                  )
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: validSpells.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (c, i) {
                    final spell = validSpells[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSlots[slotIndex] = spell;
                        });
                        Navigator.pop(ctx);
                      },
                      child: AbsorbPointer(
                        child: SpellCard(spell: spell, isCastable: true),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    List<Spell> finalDeck = [];
    // Ordina da slot 0 a 9 per mantenere la struttura
    for (int i = 0; i < 10; i++) {
      if (_selectedSlots.containsKey(i)) {
        finalDeck.add(_selectedSlots[i]!);
      }
    }
    
    // Salva nel setup padre
    widget.onConfirm(finalDeck);
    
    // CHIUDE LA SCHERMATA (Fix: prima mancava questo)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color color = _getElementColor(widget.element);
    bool isComplete = _selectedSlots.length == 10;

    return Scaffold(
      appBar: AppBar(
        title: Text("Grimorio ${widget.element.name.toUpperCase()}"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: color.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text("Riempi i 10 Slot. Tocca uno slot per scegliere.", style: TextStyle(color: Colors.grey.shade800, fontSize: 12))),
                Text("${_selectedSlots.length}/10", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _slotRules.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rule = _slotRules[index];
                final selectedSpell = _selectedSlots[index];

                return InkWell(
                  onTap: () => _openSpellPicker(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: selectedSpell != null ? color : Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8), // Ridotto padding
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedSpell != null ? color : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text("${index + 1}", style: TextStyle(color: selectedSpell != null ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rule.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
                              if (selectedSpell != null)
                                Text(selectedSpell.nome, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15))
                              else
                                Text(rule.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(selectedSpell != null ? Icons.autorenew : Icons.add_circle_outline, color: selectedSpell != null ? Colors.grey : color),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isComplete ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300
                ),
                child: const Text("CONFERMA GRIMORIO"),
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _getElementColor(Elemento e) {
    if (e == Elemento.rosso) return Colors.red;
    if (e == Elemento.blu) return Colors.blue;
    if (e == Elemento.verde) return Colors.green;
    return Colors.orange;
  }
}

class SlotDefinition {
  final int id;
  final String title;
  final String subtitle;
  final bool Function(Spell) filter;

  SlotDefinition({required this.id, required this.title, required this.subtitle, required this.filter});
}