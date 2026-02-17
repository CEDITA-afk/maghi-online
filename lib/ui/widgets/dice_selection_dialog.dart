import 'package:flutter/material.dart';
import '../../models/enums.dart';

class DiceSelectionDialog extends StatefulWidget {
  final int maxSelection; // Quanti dadi DEVI scegliere (es. 3 meno quelli salvati)
  final Function(List<Elemento>) onConfirm;

  const DiceSelectionDialog({
    super.key,
    required this.maxSelection,
    required this.onConfirm,
  });

  @override
  State<DiceSelectionDialog> createState() => _DiceSelectionDialogState();
}

class _DiceSelectionDialogState extends State<DiceSelectionDialog> {
  final Set<Elemento> _selected = {};
  
  // I 4 archetipi disponibili
  final List<Elemento> _options = [
    Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo
  ];

  void _toggle(Elemento e) {
    setState(() {
      if (_selected.contains(e)) {
        _selected.remove(e);
      } else {
        // Puoi selezionare solo se non hai raggiunto il massimo
        // E solo se quel colore non è già selezionato (gestito dal Set)
        if (_selected.length < widget.maxSelection) {
          _selected.add(e);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          const Text("Draft Dadi Mana", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Scegli ${widget.maxSelection} dadi da lanciare.", 
            style: const TextStyle(fontSize: 14, color: Colors.grey)
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Massimo 1 per colore.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _options.map((e) => _buildOption(e)).toList(),
          ),
        ],
      ),
      actions: [
        // Bottone disabilitato finché non selezioni il numero esatto richiesto
        ElevatedButton(
          onPressed: _selected.length == widget.maxSelection 
            ? () {
                widget.onConfirm(_selected.toList());
                Navigator.pop(context);
              } 
            : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text("LANCIA"),
        )
      ],
    );
  }

  Widget _buildOption(Elemento e) {
    bool isSelected = _selected.contains(e);
    Color c = _getColor(e);

    return InkWell(
      onTap: () => _toggle(e),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: isSelected ? c : Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade400, 
            width: isSelected ? 4 : 2
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)] 
            : []
        ),
        child: Icon(
          _getIcon(e), 
          color: isSelected ? Colors.white : Colors.grey,
          size: 30
        ),
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