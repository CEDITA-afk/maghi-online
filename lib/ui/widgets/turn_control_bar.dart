import 'package:flutter/material.dart';

class TurnControlBar extends StatelessWidget {
  final int actions;
  final int energy;
  final VoidCallback onMove;
  final VoidCallback onInteract;
  final VoidCallback onHelp;
  final VoidCallback onDisarm; // Azione speciale Disinnesco
  final VoidCallback onEndTurn;

  const TurnControlBar({
    super.key,
    required this.actions,
    required this.energy,
    required this.onMove,
    required this.onInteract,
    required this.onHelp,
    required this.onDisarm,
    required this.onEndTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          // RIGA SUPERIORE: Azioni, Energia, Fine Turno
          Row(
            children: [
              // Azioni
              _buildCounter("AZIONI", actions, Icons.bolt, Colors.amber),
              const SizedBox(width: 16),
              // Energia
              _buildCounter("ENERGIA", energy, Icons.auto_awesome, Colors.purple),
              const Spacer(),
              // Fine Turno
              TextButton.icon(
                onPressed: onEndTurn,
                icon: const Icon(Icons.skip_next, color: Colors.red),
                label: const Text("PASSA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          // RIGA INFERIORE: Pulsanti Azioni Fisiche
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("Muovi", Icons.directions_run, onMove, actions > 0),
                const SizedBox(width: 8),
                _buildActionButton("Interagisci", Icons.touch_app, onInteract, actions > 0),
                const SizedBox(width: 8),
                _buildActionButton("Aiuta", Icons.medical_services, onHelp, actions > 0),
                const SizedBox(width: 8),
                _buildActionButton("Disinnesca", Icons.build, onDisarm, actions > 0, isSpecial: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text("$value", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, bool enabled, {bool isSpecial = false}) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpecial ? Colors.black87 : Colors.grey.shade200,
        foregroundColor: isSpecial ? Colors.white : Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}