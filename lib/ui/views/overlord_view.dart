import 'package:flutter/material.dart';
import '../../models/entities.dart';
import '../../models/overlord_model.dart';
import '../../models/enums.dart';

class OverlordView extends StatefulWidget {
  final BossOverlord boss;
  final OverlordLoadout bossLoadout; // <--- NUOVO: Permette l'accesso alle Fasi
  final List<OverlordAbility> abilitaBoss;
  final Function(OverlordAbility, int, Elemento) onAssignCube;
  final Function(OverlordAbility) onCastAbility;
  final VoidCallback onContinue;
  final bool isRoundOver;

  const OverlordView({
    super.key, 
    required this.boss, 
    required this.bossLoadout,
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
  Elemento? _selectedCubeFromPool;

  void _onPoolCubeTap(Elemento e) {
    setState(() {
      if (_selectedCubeFromPool == e) {
        _selectedCubeFromPool = null; 
      } else {
        _selectedCubeFromPool = e; 
      }
    });
  }

  void _onSlotTap(OverlordAbility skill, int slotIndex) {
    if (_selectedCubeFromPool == null) return;
    
    bool isSlotEmpty = skill.currentFill[slotIndex] == null;
    if (!isSlotEmpty) return;

    Elemento required = skill.costo[slotIndex];
    bool compatible = (_selectedCubeFromPool == Elemento.jolly) || 
                      (required == Elemento.jolly) || 
                      (_selectedCubeFromPool == required);

    if (compatible) {
      widget.onAssignCube(skill, slotIndex, _selectedCubeFromPool!);
      setState(() {
        _selectedCubeFromPool = null; 
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Colore non compatibile!"), duration: Duration(milliseconds: 500)
      ));
    }
  }

  // NUOVO: Mostra il testo della scheda boss che legge dinamicamente le Fasi
  void _showBossRules(BuildContext context) {
    List<Widget> fasiWidgets = [];
    if (widget.bossLoadout.phases.isNotEmpty) {
      // Ordina e visualizza le fasi
      var keys = widget.bossLoadout.phases.keys.toList()..sort();
      for (String key in keys) {
        fasiWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                children: [
                  TextSpan(text: "Fase $key: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  TextSpan(text: widget.bossLoadout.phases[key]),
                ],
              ),
            ),
          )
        );
      }
    } else {
      fasiWidgets.add(const Text("Nessuna fase speciale definita per questo Boss.", style: TextStyle(color: Colors.white70)));
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("Regolamento: ${widget.boss.nome}", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.bossLoadout.descrizione, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
              const Divider(color: Colors.white24, height: 24),
              const Text("FASI DELLO SCONTRO:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ...fasiWidgets,
              const Divider(color: Colors.white24, height: 24),
              const Text(
                "NOTA: Quando il Boss cambia Fase o applica un debuff, apri la BACHECA in alto a destra e scrivi una nota in modo che tutti i maghi la vedano!",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHIUDI"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 1. RISERVA E PULSANTE INFO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24)
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("RISERVA MANA (Tocca per selezionare)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.menu_book, color: Colors.purpleAccent),
                      tooltip: "Leggi Regole Boss",
                      onPressed: () => _showBossRules(context),
                    )
                  ],
                ),
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

  Widget _buildAbilityTrack(OverlordAbility skill) {
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
            
            Row(
              children: List.generate(skill.costo.length, (index) {
                Elemento required = skill.costo[index];
                Elemento? current = skill.currentFill[index];
                
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