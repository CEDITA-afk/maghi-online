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
  final Map<int, Spell> _selectedSlots = {};
  late final List<SlotDefinition> _slotRules;

  @override
  void initState() {
    super.initState();
    _initSlotRules();
    for (int i = 0; i < widget.initialSelection.length && i < 10; i++) {
       _selectedSlots[i] = widget.initialSelection[i];
    }
  }

  void _clearAll() {
    setState(() {
      _selectedSlots.clear();
    });
  }

  void _initSlotRules() {
    _slotRules = [
      SlotDefinition(id: 0, title: "Slot 1: Base", subtitle: "Tier 1 - Costo 1 [Puro]", filter: (s) => s.costo.length == 1 && _isPure(s)),
      SlotDefinition(id: 1, title: "Slot 2: Core", subtitle: "Tier 2 - Costo 2 [Puro]", filter: (s) => s.costo.length == 2 && _isPure(s)),
      SlotDefinition(id: 2, title: "Slot 3: Utility", subtitle: "Tier 1.5 - Costo 1 [P] + 1 [Altro]", filter: (s) => s.costo.length == 2 && !_isPure(s)),
      SlotDefinition(id: 3, title: "Slot 4: Impatto", subtitle: "Tier 3 - Costo 2 [P] + 1 [Altro]", filter: (s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate),
      SlotDefinition(id: 4, title: "Slot 5: Finisher", subtitle: "Tier 4 - ULTIMATE (Costo 3+)", filter: (s) => s.categoria == CategoriaIncantesimo.ultimate),
      SlotDefinition(id: 5, title: "Slot 6: Sinergia", subtitle: "Tier 2 - Ibrido Leggero", filter: (s) => s.costo.length == 2 && !_isPure(s)),
      SlotDefinition(id: 6, title: "Slot 7: Heavy", subtitle: "Tier 3 - Ibrido Heavy", filter: (s) => s.costo.length == 3 && !_isPure(s) && s.categoria != CategoriaIncantesimo.ultimate),
      SlotDefinition(id: 7, title: "Slot 8: Tecnica", subtitle: "Tier 4 - Complesso", filter: (s) => s.costo.length >= 3 && !_isPure(s)),
      SlotDefinition(id: 8, title: "Slot 9: Libero", subtitle: "Qualsiasi", filter: (s) => true),
      SlotDefinition(id: 9, title: "Slot 10: Libero", subtitle: "Qualsiasi", filter: (s) => true),
    ];
  }

  bool _isPure(Spell s) => s.costo.every((c) => c == widget.element);

  void _openSpellPicker(int slotIndex) {
    final rule = _slotRules[slotIndex];
    final validSpells = widget.allSpells.where((spell) {
      if (!rule.filter(spell)) return false;
      return !_selectedSlots.values.contains(spell) || _selectedSlots[slotIndex] == spell;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _getElementColor(widget.element), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Scegli per ${rule.title}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(rule.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white))
                ],
              ),
            ),
            Expanded(
              child: validSpells.isEmpty 
              ? const Center(child: Text("Nessuna magia disponibile."))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: validSpells.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (c, i) {
                    final spell = validSpells[i];
                    return ListTile(
                      title: Text(spell.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(spell.effetto, maxLines: 2), // Corretto da descrizione a effetto
                      trailing: Text("${spell.costo.length} Mana"),
                      onTap: () {
                        setState(() => _selectedSlots[slotIndex] = spell);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
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
        actions: [
          if (_selectedSlots.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: const Text("SVUOTA", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12), color: color.withOpacity(0.1),
            child: Row(children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Text("Selezionate: ${_selectedSlots.length}/10"),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final selectedSpell = _selectedSlots[index];
                return ListTile(
                  tileColor: selectedSpell != null ? color.withOpacity(0.1) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  title: Text(_slotRules[index].title),
                  subtitle: Text(selectedSpell?.nome ?? _slotRules[index].subtitle),
                  trailing: Icon(selectedSpell != null ? Icons.check_circle : Icons.add_circle, color: color),
                  onTap: () => _openSpellPicker(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: isComplete ? () { widget.onConfirm(_selectedSlots.values.toList()); Navigator.pop(context); } : null,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              child: const Text("CONFERMA GRIMORIO"),
            )),
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