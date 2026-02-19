import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../logic/firebase_service.dart';
import '../../../data/overlord_repository.dart'; // Per caricare nomi boss
import '../../../data/map_repository.dart'; // Per caricare nomi mappe
import '../../../models/enums.dart'; // Per Elemento
import '../game_page.dart';
//import '../../widgets/loader.dart'; // Se hai un widget loader, o usa CircularProgressIndicator

class LobbyPage extends StatefulWidget {
  final FirebaseService firebase;
  final String roomId;

  const LobbyPage({super.key, required this.firebase, required this.roomId});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  // Repository per recuperare i dati statici (nomi boss, mappe)
  final OverlordRepository _bossRepo = OverlordRepository();
  final MapRepository _mapRepo = MapRepository();
  
  // Dati caricati
  List<dynamic> _bosses = [];
  List<dynamic> _maps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaticData();
  }

  Future<void> _loadStaticData() async {
    var b = await _bossRepo.getAvailableOverlords();
    var m = await _mapRepo.getAvailableScenarios();
    setState(() {
      _bosses = b;
      _maps = m;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("LOBBY: ${widget.roomId}"),
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.firebase.lobbyStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("La stanza è stata chiusa."));

          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          // CONTROLLO AVVIO PARTITA
          if (data['status'] == 'PLAYING') {
            // Navigazione automatica quando l'host avvia
            WidgetsBinding.instance.addPostFrameCallback((_) {
               // Qui dovremmo recuperare i Loadout reali in base agli indici salvati
               // Per ora passo i dati grezzi, dovrai adattare il costruttore di GamePage
               // o passare gli indici e far caricare a GamePage i dati.
               _startGame(data);
            });
            return const Center(child: Text("Caricamento partita...", style: TextStyle(fontSize: 20)));
          }

          String myId = widget.firebase.myUserId!;
          String hostId = data['hostId'];
          bool isHost = myId == hostId;
          Map<String, dynamic> roles = data['roles'] ?? {};
          List<dynamic> readyPlayers = data['ready'] ?? [];
          bool amIReady = readyPlayers.contains(myId);

          return Column(
            children: [
              // 1. INFO STANZA E SETTINGS (Host Only)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade800,
                child: Column(
                  children: [
                    Text("Giocatori connessi: ${(data['players'] as List).length}", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    if (isHost) ...[
                      _buildDropdown("Mappa", _maps, data['mapIndex'] ?? 0, (v) => widget.firebase.updateSettings('mapIndex', v)),
                      const SizedBox(height: 10),
                      _buildDropdown("Boss", _bosses, data['bossIndex'] ?? 0, (v) => widget.firebase.updateSettings('bossIndex', v)),
                    ] else ...[
                      Text("Mappa: ${_maps[data['mapIndex'] ?? 0].name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Boss: ${_bosses[data['bossIndex'] ?? 0].nome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ]
                  ],
                ),
              ),

              // 2. SELEZIONE RUOLI
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text("Scegli il tuo ruolo (puoi prenderne più di uno):", style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 10),
                    _buildRoleCard("Overlord", "overlord", Colors.purple, roles, myId),
                    _buildRoleCard("Mago Rosso", "rosso", Colors.red, roles, myId),
                    _buildRoleCard("Mago Blu", "blu", Colors.blue, roles, myId),
                    _buildRoleCard("Mago Verde", "verde", Colors.green, roles, myId),
                    _buildRoleCard("Mago Giallo", "giallo", Colors.orange, roles, myId),
                  ],
                ),
              ),

              // 3. BARRA INFERIORE (READY / START)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade900, border: Border(top: BorderSide(color: Colors.white10))),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amIReady ? Colors.green : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => widget.firebase.toggleReady(!amIReady),
                        child: Text(amIReady ? "SONO PRONTO" : "CLICCA QUANDO PRONTO"),
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 10),
                      IconButton.filled(
                        icon: const Icon(Icons.play_arrow),
                        // Abilita Start solo se tutti i ruoli chiave sono presi o se c'è almeno un player pronto
                        onPressed: (readyPlayers.isNotEmpty) ? () => widget.firebase.startGame() : null, 
                        style: IconButton.styleFrom(backgroundColor: Colors.purpleAccent),
                      )
                    ]
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(String label, String roleId, Color color, Map roles, String myId) {
    String? ownerId = roles[roleId];
    bool isMine = ownerId == myId;
    bool isTaken = ownerId != null && !isMine;

    return Card(
      color: isMine ? color.withOpacity(0.3) : (isTaken ? Colors.grey.shade900 : Colors.black45),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isMine ? color : (isTaken ? Colors.transparent : Colors.white24), width: 2),
        borderRadius: BorderRadius.circular(8)
      ),
      child: ListTile(
        leading: Icon(
          roleId == 'overlord' ? Icons.security : Icons.person,
          color: isMine ? color : (isTaken ? Colors.grey : Colors.white),
        ),
        title: Text(label, style: TextStyle(color: isTaken ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(isMine ? "Tuo" : (isTaken ? "Occupato" : "Libero"), style: TextStyle(color: isMine ? color : Colors.grey)),
        trailing: isTaken && !isMine ? const Icon(Icons.lock, color: Colors.grey) : null,
        onTap: () {
          if (isTaken) return; // Non puoi rubare il ruolo
          if (isMine) {
            widget.firebase.unclaimRole(roleId);
          } else {
            widget.firebase.claimRole(roleId);
          }
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, int selectedIdx, Function(int) onChanged) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButton<int>(
            value: selectedIdx,
            isExpanded: true,
            dropdownColor: Colors.grey.shade800,
            items: List.generate(items.length, (index) => DropdownMenuItem(
              value: index,
              child: Text(roleName(items[index])), // Helper per estrarre il nome
            )),
            onChanged: (v) => onChanged(v!),
          ),
        ),
      ],
    );
  }
  
  String roleName(dynamic item) {
    // Helper semplice perché Maps e Bosses hanno campi diversi (name vs nome)
    try { return item.name; } catch(e) { return item.nome; }
  }

  void _startGame(Map<String, dynamic> data) {
    // Costruisci gli oggetti reali dagli indici
    var map = _maps[data['mapIndex']];
    var boss = _bosses[data['bossIndex']];
    
    // Qui devi adattare i parametri per passare i grimori standard
    // O implementare una logica per cui i grimori vengono scelti nella lobby.
    // Per ora passiamo i mazzi standard generati al volo.
    
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => GamePage(
        roomId: widget.roomId,
        mapScenario: map,
        bossLoadout: boss,
        numGiocatori: (data['players'] as List).length, // O calcolato dai ruoli
        playerDecks: {}, // TODO: Passare i deck standard
      ))
    );
  }
}