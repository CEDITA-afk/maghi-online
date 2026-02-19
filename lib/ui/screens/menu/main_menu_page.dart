import 'package:flutter/material.dart';
import '../../logic/firebase_service.dart';
import '../lobby/lobby_page.dart';
import '../setup/setup_page.dart'; // La vecchia pagina per il TEST (Hotseat)

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebase = FirebaseService(); // Istanza singleton o provider

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_fix_high, size: 80, color: Colors.purpleAccent),
              const SizedBox(height: 20),
              const Text("MAGHI DEL DESTINO", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Digital Sandbox", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 50),

              // CREA PARTITA
              _buildButton(
                icon: Icons.add_circle_outline,
                label: "CREA NUOVA PARTITA",
                color: Colors.purple,
                onTap: () async {
                  String roomId = await _firebase.createLobby();
                  if (mounted) _goToLobby(roomId);
                },
              ),
              const SizedBox(height: 15),

              // PARTECIPA
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "ID Stanza (es. ROOM-1234)",
                        hintStyle: TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      bool success = await _firebase.joinLobby(_codeController.text.toUpperCase().trim());
                      if (success && mounted) {
                        _goToLobby(_codeController.text.toUpperCase().trim());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stanza non trovata!")));
                      }
                    },
                  )
                ],
              ),
              
              const Divider(height: 40, color: Colors.white24),

              // TEST (HOTSEAT)
              _buildButton(
                icon: Icons.phonelink_setup,
                label: "MODALITÀ TEST (SOLO)",
                color: Colors.grey.shade800,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToLobby(String roomId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyPage(firebase: _firebase, roomId: roomId)));
  }

  Widget _buildButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
      ),
    );
  }
}