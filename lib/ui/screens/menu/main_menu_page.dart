import 'package:flutter/material.dart';
import '../../../logic/firebase_service.dart';
import '../lobby/lobby_page.dart';
import '../setup/setup_page.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebase = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.auto_fix_high, size: 100, color: Colors.purpleAccent),
              const SizedBox(height: 20),
              const Text("MAGHI DEL DESTINO", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              _menuButton(
                "CREA NUOVA PARTITA", 
                Icons.add_box, 
                Colors.purple, 
                () async {
                  String rid = await _firebase.createLobby();
                  _navToLobby(rid);
                }
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(hintText: "ID STANZA", filled: true, fillColor: Colors.white10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () async {
                      bool ok = await _firebase.joinLobby(_codeController.text.trim());
                      if (ok) _navToLobby(_codeController.text.trim());
                    }, 
                    icon: const Icon(Icons.login)
                  )
                ],
              ),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Divider()),
              
              _menuButton(
                "TEST (HOTSEAT)", 
                Icons.play_circle_outline, 
                Colors.grey.shade800, 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage()))
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navToLobby(String rid) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyPage(firebase: _firebase, roomId: rid)));
  }

  Widget _menuButton(String text, IconData icon, Color color, VoidCallback t) {
    return SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: t, icon: Icon(icon), label: Text(text), style: ElevatedButton.styleFrom(backgroundColor: color)));
  }
}