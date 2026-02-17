import 'package:flutter/material.dart';
import '../../models/entities.dart';
import '../../models/enums.dart';

class StatusBar extends StatelessWidget {
  final BossOverlord boss;
  final Map<Elemento, Mago> maghi;
  final Function(dynamic, int) onHpChange;

  const StatusBar({
    super.key, 
    required this.boss, 
    required this.maghi, 
    required this.onHpChange
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          // Row Boss con HP e Cubetti (Mana Echo)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBossSection(),
              _buildCubeDisplay(),
            ],
          ),
          const Divider(),
          // Row Eroi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: maghi.values.map((mago) => _buildHeroTile(mago)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossSection() {
    return Row(
      children: [
        const Icon(Icons.adb, color: Colors.black, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(boss.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  onPressed: () => onHpChange(boss, -1), 
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text("${boss.hp}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onHpChange(boss, 1), 
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildCubeDisplay() {
    return Row(
      children: boss.cubettiMana.entries.where((e) => e.key != Elemento.neutro).map((e) {
        // Mostra solo se ci sono cubetti, ma mostra sempre lo spazio per il layout
        if (e.value == 0) return const SizedBox.shrink();

        Color c;
        switch(e.key) {
          case Elemento.rosso: c = Colors.red; break;
          case Elemento.blu: c = Colors.blue; break;
          case Elemento.verde: c = Colors.green; break;
          case Elemento.giallo: c = Colors.orange; break;
          default: c = Colors.black; // Jolly
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
          child: Text("${e.value}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  Widget _buildHeroTile(Mago mago) {
    Color c = _getHeroColor(mago.elemento);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: c.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(mago.isSpirito ? Icons.auto_fix_high : Icons.person, color: c, size: 16),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(onTap: () => onHpChange(mago, -1), child: const Icon(Icons.remove, size: 16)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text("${mago.hp}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              GestureDetector(onTap: () => onHpChange(mago, 1), child: const Icon(Icons.add, size: 16)),
            ],
          )
        ],
      ),
    );
  }

  Color _getHeroColor(Elemento e) {
    switch(e) {
      case Elemento.rosso: return Colors.red;
      case Elemento.blu: return Colors.blue;
      case Elemento.verde: return Colors.green;
      case Elemento.giallo: return Colors.orange;
      default: return Colors.grey;
    }
  }
}