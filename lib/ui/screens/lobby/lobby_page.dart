import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../logic/firebase_service.dart';
import '../../../data/overlord_repository.dart';
import '../../../data/map_repository.dart';
import '../../../data/data_repository.dart'; // Aggiunto per caricare le magie
import '../../../models/enums.dart';
import '../../../models/spell.dart';
import '../game_page.dart';
import '../setup/spell_selection_view.dart'; // Aggiunto per personalizzazione

class LobbyPage extends StatefulWidget {
  final FirebaseService firebase;
  final String roomId;

  const LobbyPage({super.key, required this.firebase, required this.roomId});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final OverlordRepository _bossRepo = OverlordRepository();
  final MapRepository _mapRepo = MapRepository();
  final DataRepository _spellRepo = DataRepository();
  
  List<dynamic> _bosses = [];
  List<dynamic> _maps = [];
  List<Spell> _allSpells = []; // Caricate per i mazzi standard
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaticData();
  }

  Future<void> _loadStaticData() async {
    var b = await _bossRepo.getAvailableOverlords();
    var m = await _mapRepo.getAvailableScenarios();
    var s = await _spellRepo.loadAllSpells();
    setState(() {
      _bosses = b;
      _maps = m;
      _allSpells = s;
      _loading = false;
    });
  }

  // Helper per generare mazzi standard di backup
  List<Spell> _generateStandardDeck(Elemento element) {
    List<Spell> deck = [];
    List<Spell> pool = _allSpells.where((s) => s.sourceElement == element).toList();
    bool isPure(Spell s) => s.costo.every((c) => c == element);
    void add(bool Function(Spell) f) {
      try { deck.add(pool.firstWhere((s) => f(s) && !deck.contains(s))); } catch (e) {}
    }
    add((s) => s.costo.length == 1 && isPure(s));
    add((s) => s.costo.length == 2 && isPure(s));
    add((s) => s.costo.length == 2 && !isPure(s));
    add((s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate);
    add((s) => s.categoria == CategoriaIncantesimo.ultimate);
    add((s) => s.costo.length == 2);
    add((s) => s.costo.length == 3);
    add((s) => s.costo.length >= 3);
    add((s) => true);
    add((s) => true);
    return deck;
  }

  void _openGrimorio(Elemento e) async {
    // Carica il mazzo attuale o usa quello standard
    List<Spell> currentSelection = _generateStandardDeck(e);

    await Navigator.push(context, MaterialPageRoute(builder: (_) => SpellSelectionView(
      element: e,
      allSpells: _allSpells.where((s) => s.sourceElement == e).toList(),
      initialSelection: currentSelection,
      onConfirm: (newList) {
        // Sincronizza il mazzo su Firebase per la stanza
        widget.firebase.updateFullState({
          'decks.${e.name}': newList.map((s) => s.id).toList()
        });
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("LOBBY: ${widget.roomId}"), centerTitle: true, backgroundColor: Colors.grey.shade900),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.firebase.lobbyStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          if (data['status'] == 'PLAYING') {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startGame(data));
            return const Center(child: Text("Caricamento partita..."));
          }

          String myId = widget.firebase.myUserId!;
          Map<String, dynamic> roles = data['roles'] ?? {};
          List<dynamic> readyPlayers = data['ready'] ?? [];
          bool amIReady = readyPlayers.contains(myId);

          return Column(
            children: [
              // ... (Settings dell'Host invariati)

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRoleCard("Overlord", "overlord", Colors.purple, roles, myId, null),
                    _buildRoleCard("Mago Rosso", "rosso", Colors.red, roles, myId, Elemento.rosso),
                    _buildRoleCard("Mago Blu", "blu", Colors.blue, roles, myId, Elemento.blu),
                    _buildRoleCard("Mago Verde", "verde", Colors.green, roles, myId, Elemento.verde),
                    _buildRoleCard("Mago Giallo", "giallo", Colors.orange, roles, myId, Elemento.giallo),
                  ],
                ),
              ),

              // Barra Ready / Start (Invariata)
              // ...
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(String label, String roleId, Color color, Map roles, String myId, Elemento? el) {
    String? ownerId = roles[roleId];
    bool isMine = ownerId == myId;
    bool isTaken = ownerId != null && !isMine;

    return Card(
      color: isMine ? color.withOpacity(0.3) : (isTaken ? Colors.grey.shade900 : Colors.black45),
      child: ListTile(
        leading: Icon(roleId == 'overlord' ? Icons.security : Icons.person, color: isMine ? color : Colors.white),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isMine ? "Tuo" : (isTaken ? "Occupato" : "Libero")),
        trailing: isMine && el != null 
          ? IconButton(icon: const Icon(Icons.auto_stories, color: Colors.white), onPressed: () => _openGrimorio(el))
          : (isTaken ? const Icon(Icons.lock) : null),
        onTap: () {
          if (!isTaken) isMine ? widget.firebase.unclaimRole(roleId) : widget.firebase.claimRole(roleId);
        },
      ),
    );
  }

  void _startGame(Map<String, dynamic> data) {
    var map = _maps[data['mapIndex']];
    var boss = _bosses[data['bossIndex']];
    Map<String, dynamic> roles = data['roles'] ?? {};
    Map<String, dynamic> cloudDecks = data['decks'] ?? {};
    Map<Elemento, List<Spell>> finalDecks = {};

    // Costruisce i mazzi finali (caricati o standard) per ogni eroe in partita
    roles.forEach((roleName, userId) {
      if (roleName != 'overlord') {
        Elemento el = Elemento.values.firstWhere((e) => e.name == roleName);
        if (cloudDecks.containsKey(roleName)) {
          List<dynamic> ids = cloudDecks[roleName];
          finalDecks[el] = ids.map((id) => _allSpells.firstWhere((s) => s.id == id)).toList();
        } else {
          finalDecks[el] = _generateStandardDeck(el);
        }
      }
    });

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(
      roomId: widget.roomId,
      mapScenario: map,
      bossLoadout: boss,
      numGiocatori: finalDecks.length,
      playerDecks: finalDecks,
    )));
  }
}