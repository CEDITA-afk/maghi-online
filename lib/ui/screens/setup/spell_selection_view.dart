import 'package:flutter/material.dart';
import '../../../models/spell.dart';
import '../../../models/enums.dart';

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
  // Mappa degli slot (0-9) e della magia assegnata
  final Map<int, Spell> _selectedSlots = {};
  
  // Regole descrittive per ogni slot
  late final List<String> _slotDescriptions;

  @override
  void initState() {
    super.initState();
    _slotDescriptions = [
      "Base (Costo 1 Puro)",
      "Core (Costo 2 Puro)",
      "Utility (Costo 2 Ibrido)",
      "Impatto (Costo 3)",
      "ULTIMATE",
      "Sinergia (Costo 2)",
      "Heavy (Costo 3)",
      "Tecnica (Costo 3+)",
      "Wildcard",
      "Wildcard",
    ];

    // Carica la selezione iniziale se presente
    for (int i = 0; i < widget.initialSelection.length && i < 10; i++) {
      _selectedSlots[i] = widget.initialSelection[i];
    }
  }

  // Metodo per svuotare completamente il grimorio
  void _clearAll() {
    setState(() {
      _selectedSlots.clear();
    });
  }

  bool _isPure(Spell s) => s.costo.every((c) => c == widget.element);

  // Filtra le magie disponibili per uno specifico slot
  List<Spell> _getAvailableForSlot(int index) {
    return widget.allSpells.where((s) {
      // Evita duplicati nello stesso grimorio
      if (_selectedSlots.values.contains(s)) return false;

      switch (index) {
        case 0: return s.costo.length == 1 && _isPure(s);
        case 1: return s.costo.length == 2 && _isPure(s);
        case 2: return s.costo.length == 2 && !_isPure(s);
        case 3: return s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate;
        case 4: return s.categoria == CategoriaIncantesimo.ultimate;
        case 5: return s.costo.length == 2;
        case 6: return s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate;
        case 7: return s.costo.length >= 3;
        default: return true; // Wildcards
      }
    }).toList();
  }

  void _openSpellPicker(int slotIndex) {
    final available = _getAvailableForSlot(slotIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Seleziona per: ${_slotDescriptions[slotIndex]}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: available.isEmpty
                ? const Center(child: Text("Nessuna magia disponibile per questo slot"))
                : ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, i) {
                      final s = available[i];
                      return ListTile(
                        title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s.descrizione, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text("${s.costo.length} Mana"),
                        onTap: () {
                          setState(() => _selectedSlots[slotIndex] = s);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getElementColor(widget.element);
    bool isComplete = _selectedSlots.length == 10;

    return Scaffold(
      appBar: AppBar(
        title: Text("Grimorio ${widget.element.name.toUpperCase()}"),
        backgroundColor: themeColor,
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
            padding: const EdgeInsets.all(12),
            color: themeColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 10),
                Text("Selezionate: ${_selectedSlots.length} / 10"),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                final spell = _selectedSlots[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: spell != null ? themeColor.withOpacity(0.2) : Colors.grey.shade900,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeColor,
                      child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      spell?.nome ?? "Slot Vuoto",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: spell != null ? Colors.white : Colors.white38,
                      ),
                    ),
                    subtitle: Text(_slotDescriptions[index]),
                    trailing: spell != null
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () => setState(() => _selectedSlots.remove(index)),
                          )
                        : const Icon(Icons.add_circle_outline, color: Colors.white24),
                    onTap: () => _openSpellPicker(index),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? themeColor : Colors.grey,
                ),
                onPressed: isComplete
                    ? () {
                        widget.onConfirm(_selectedSlots.values.toList());
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text("CONFERMA GRIMORIO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(Elemento e) {
    switch (e) {
      case Elemento.rosso: return Colors.red.shade900;
      case Elemento.blu: return Colors.blue.shade900;
      case Elemento.verde: return Colors.green.shade900;
      case Elemento.giallo: return Colors.orange.shade900;
      default: return Colors.grey;
    }
  }
}