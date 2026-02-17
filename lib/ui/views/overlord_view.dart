import 'package:flutter/material.dart';
import '../../models/entities.dart';
import '../../models/overlord_model.dart';
import '../../models/enums.dart';

class OverlordView extends StatefulWidget {
  final BossOverlord boss;
  final List<OverlordAbility> abilitaBoss;
  // Callback quando un cubetto viene spostato dalla riserva a un tracciato
  final Function(OverlordAbility, int, Elemento) onAssignCube;
  // Callback quando un'abilità viene effettivamente lanciata (svuotando il tracciato)
  final Function(OverlordAbility) onCastAbility;
  
  final VoidCallback onContinue;
  final bool isRoundOver;

  const OverlordView({
    super.key, 
    required this.boss, 
    required this.abilitaBoss,
    required this.onAssignCube,
    required this.onCastAbility,
    required this.onContinue, 
    required this.isRoundOver
  });

  @override
  State<OverlordView> createState() => _OverlordViewState();
}

class _OverlordViewState extends State<OverlordView> {
  // Il cubetto attualmente selezionato dalla riserva
  Elemento? _selectedCubeFromPool;

  void _onPoolCubeTap(Elemento e) {
    setState(() {
      if (_selectedCubeFromPool == e) {
        _selectedCubeFromPool = null; // Deseleziona
      } else {
        _selectedCubeFromPool = e; // Seleziona
      }
    });
  }

  void _onSlotTap(OverlordAbility skill, int slotIndex) {
    if (_selectedCubeFromPool == null) return;

    // Tenta di inserire il cubetto selezionato nello slot
    // La logica di compatibilità (es. Jolly) è gestita dentro tryFillSlot nel modello,
    // ma qui facciamo un check visivo prima di chiamare il callback
    
    bool isSlotEmpty = skill.currentFill[slotIndex] == null;
    if (!isSlotEmpty) return;

    Elemento required = skill.costo[slotIndex];
    bool compatible = (_selectedCubeFromPool == Elemento.jolly) || 
                      (required == Elemento.jolly) || 
                      (_selectedCubeFromPool == required);

    if (compatible) {
      widget.onAssignCube(skill, slotIndex, _selectedCubeFromPool!);
      setState(() {
        _selectedCubeFromPool = null; // Resetta selezione dopo assegnazione
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Colore non compatibile!"), duration: Duration(milliseconds: 500)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 1. RISERVA (POOL)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24)
            ),
            child: Column(
              children: [
                const Text("RISERVA MANA (Tocca per selezionare)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                _buildManaPool(),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          const Divider(color: Colors.white24),

          // 2. LISTA TRACCIATI
          Expanded(
            child: ListView.separated(
              itemCount: widget.abilitaBoss.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildAbilityTrack(widget.abilitaBoss[index]);
              },
            ),
          ),

          // 3. FINE FASE
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, 
                  foregroundColor: Colors.black
                ),
                child: Text(widget.isRoundOver ? "FINE ROUND (Incassa Rendita)" : "PASSA TURNO AGLI EROI"),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Costruisce la riga di cubetti cliccabili dalla riserva del Boss
  Widget _buildManaPool() {
    List<Widget> cubes = [];
    
    widget.boss.cubettiMana.forEach((elemento, count) {
      if (elemento == Elemento.neutro) return;
      for (int i = 0; i < count; i++) {
        bool isSelected = _selectedCubeFromPool == elemento;
        cubes.add(
          GestureDetector(
            onTap: () => _onPoolCubeTap(elemento),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(4),
              width: isSelected ? 32 : 28,
              height: isSelected ? 32 : 28,
              decoration: BoxDecoration(
                color: _getColor(elemento),
                borderRadius: BorderRadius.circular(4),
                border: isSelected ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.white38),
                boxShadow: isSelected ? [BoxShadow(color: _getColor(elemento), blurRadius: 10)] : []
              ),
            ),
          )
        );
      }
    });

    if (cubes.isEmpty) return const Text("Riserva vuota", style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic));

    return Wrap(alignment: WrapAlignment.center, children: cubes);
  }

  // Costruisce la Card dell'abilità con il tracciato
  Widget _buildAbilityTrack(OverlordAbility skill) {
    // Le abilità Caos (costo "Vasca") non usano tracciati classici
    if (skill.tipo == "Caos") return _buildChaosCard(skill);

    bool isReady = skill.isReady;

    return Card(
      color: isReady ? Colors.red.shade900.withOpacity(0.5) : Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isReady ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(skill.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (isReady)
                  ElevatedButton(
                    onPressed: () => widget.onCastAbility(skill),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text("ATTIVA"),
                  )
              ],
            ),
            Text(skill.effetto, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            
            // IL TRACCIATO (SLOTS)
            Row(
              children: List.generate(skill.costo.length, (index) {
                Elemento required = skill.costo[index];
                Elemento? current = skill.currentFill[index];
                
                // Determina se questo slot può accettare il cubetto selezionato (per evidenziarlo)
                bool highlight = false;
                if (current == null && _selectedCubeFromPool != null) {
                  highlight = (_selectedCubeFromPool == Elemento.jolly) || 
                              (required == Elemento.jolly) || 
                              (_selectedCubeFromPool == required);
                }

                return GestureDetector(
                  onTap: () => _onSlotTap(skill, index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: current != null ? _getColor(current) : Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: highlight ? Colors.white : (current != null ? Colors.white : _getColor(required).withOpacity(0.5)),
                        width: highlight ? 2 : 1
                      )
                    ),
                    child: current != null 
                      ? const Icon(Icons.check, size: 20, color: Colors.white54)
                      : (highlight ? const Icon(Icons.add, size: 20, color: Colors.white) : null),
                  ),
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChaosCard(OverlordAbility skill) {
    return Card(
      color: Colors.purple.shade900.withOpacity(0.3),
      child: ListTile(
        title: Text(skill.nome, style: const TextStyle(color: Colors.white)),
        subtitle: Text(skill.effetto, style: const TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
           onPressed: () => widget.onCastAbility(skill),
           style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
           child: const Text("CAOS"),
        ),
      ),
    );
  }

  Color _getColor(Elemento e) {
    switch(e) {
      case Elemento.rosso: return Colors.red;
      case Elemento.blu: return Colors.blue;
      case Elemento.verde: return Colors.green;
      case Elemento.giallo: return Colors.orange;
      case Elemento.jolly: return Colors.black; 
      default: return Colors.grey;
    }
  }
}