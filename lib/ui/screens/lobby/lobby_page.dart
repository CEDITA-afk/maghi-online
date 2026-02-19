import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../logic/firebase_service.dart';
import '../../../data/overlord_repository.dart';
import '../../../data/map_repository.dart';
import '../../../data/data_repository.dart';
import '../../../models/enums.dart';
import '../../../models/spell.dart';
import '../game_page.dart';
import '../setup/spell_selection_view.dart';

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
  List<Spell> _allSpells = [];
  bool _loading = true;
  bool _navigating = false; // Previene avvii multipli accidentali

  @override
  void initState() {
    super.initState();
    _loadStaticData();
  }

  Future<void> _loadStaticData() async {
    var b = await _bossRepo.getAvailableOverlords();
    var m = await _mapRepo.getAvailableScenarios();
    var s = await _spellRepo.loadAllSpells();
    if (mounted) {
      setState(() {
        _bosses = b;
        _maps = m;
        _allSpells = s;
        _loading = false;
      });
    }
  }

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

  void _openGrimorio(Elemento e, Map<String, dynamic> cloudDecks) async {
    List<Spell> currentSelection = [];
    if (cloudDecks.containsKey(e.name)) {
        List<dynamic> ids = cloudDecks[e.name];
        currentSelection = ids.map((id) => _allSpells.firstWhere((s) => s.id == id, orElse: () => _allSpells.first)).toList();
    } else {
        currentSelection = _generateStandardDeck(e);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => SpellSelectionView(
      element: e,
      allSpells: _allSpells.where((s) => s.sourceElement == e).toList(),
      initialSelection: currentSelection,
      onConfirm: (newList) {
        // Sincronizza i cambiamenti del mazzo nel cloud per questa stanza
        widget.firebase.updateRoomData({
          'decks.${e.name}': newList.map((s) => s.id).toList()
        });
      },
    )));
  }

  void _startGame(Map<String, dynamic> data) {
    if (_navigating) return;
    _navigating = true;
    try {
      var map = _maps[data['mapIndex'] ?? 0];
      var boss = _bosses[data['bossIndex'] ?? 0];
      Map<String, dynamic> roles = data['roles'] ?? {};
      Map<String, dynamic> cloudDecks = data['decks'] ?? {};
      Map<Elemento, List<Spell>> finalDecks = {};

      roles.forEach((roleName, userId) {
        if (roleName != 'overlord') {
          Elemento el = Elemento.values.firstWhere((e) => e.name == roleName);
          if (cloudDecks.containsKey(roleName)) {
            List<dynamic> ids = cloudDecks[roleName];
            finalDecks[el] = ids.map((id) => _allSpells.firstWhere((s) => s.id == id, orElse: () => _allSpells.first)).toList();
          } else {
            finalDecks[el] = _generateStandardDeck(el);
          }
        }
      });

      // Se in qualche modo nessuno ha preso un eroe ma la partita è partita, genera uno di backup per non crashare
      if (finalDecks.isEmpty) finalDecks[Elemento.rosso] = _generateStandardDeck(Elemento.rosso);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(
        roomId: widget.roomId,
        mapScenario: map,
        bossLoadout: boss,
        numGiocatori: finalDecks.length,
        playerDecks: finalDecks,
        myUserId: widget.firebase.myUserId, // Passa il tuo ID per le restrizioni
        roles: roles,                       // Passa la mappa dei ruoli
      )));
    } catch (e) {
      debugPrint("Errore avvio partita: $e");
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("PIN STANZA: ${widget.roomId}"), centerTitle: true, backgroundColor: Colors.grey.shade900),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.firebase.lobbyStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          
          if (data['status'] == 'PLAYING') {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startGame(data));
            return const Center(child: Text("Caricamento partita...", style: TextStyle(fontSize: 18)));
          }

          String myId = widget.firebase.myUserId!;
          String hostId = data['hostId'] ?? '';
          bool isHost = myId == hostId;
          Map<String, dynamic> roles = data['roles'] ?? {};
          Map<String, dynamic> cloudDecks = data['decks'] ?? {};
          List<dynamic> readyPlayers = data['ready'] ?? [];
          bool amIReady = readyPlayers.contains(myId);

          // Controlli per l'Host: la partita parte solo se c'è almeno un Eroe e qualcuno è pronto
          bool canStart = readyPlayers.isNotEmpty && roles.keys.any((k) => k != 'overlord');

          return Column(
            children: [
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRoleCard("Overlord", "overlord", Colors.purple, roles, myId, null, cloudDecks),
                    _buildRoleCard("Mago Rosso", "rosso", Colors.red, roles, myId, Elemento.rosso, cloudDecks),
                    _buildRoleCard("Mago Blu", "blu", Colors.blue, roles, myId, Elemento.blu, cloudDecks),
                    _buildRoleCard("Mago Verde", "verde", Colors.green, roles, myId, Elemento.verde, cloudDecks),
                    _buildRoleCard("Mago Giallo", "giallo", Colors.orange, roles, myId, Elemento.giallo, cloudDecks),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade900, border: const Border(top: BorderSide(color: Colors.white10))),
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
                        onPressed: canStart ? () => widget.firebase.startGame() : null, 
                        style: IconButton.styleFrom(backgroundColor: canStart ? Colors.purpleAccent : Colors.grey),
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

  Widget _buildDropdown(String label, List<dynamic> items, int selectedIdx, Function(int) onChanged) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButton<int>(
            value: selectedIdx < items.length ? selectedIdx : 0,
            isExpanded: true,
            dropdownColor: Colors.grey.shade800,
            items: List.generate(items.length, (index) => DropdownMenuItem(
              value: index,
              child: Text(roleName(items[index])),
            )),
            onChanged: (v) => onChanged(v!),
          ),
        ),
      ],
    );
  }

  String roleName(dynamic item) {
    try { return item.name; } catch(e) { return item.nome; }
  }

  Widget _buildRoleCard(String label, String roleId, Color color, Map roles, String myId, Elemento? el, Map<String, dynamic> cloudDecks) {
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
          ? IconButton(icon: const Icon(Icons.auto_stories, color: Colors.white), onPressed: () => _openGrimorio(el, cloudDecks))
          : (isTaken ? const Icon(Icons.lock) : null),
        onTap: () {
          if (!isTaken) isMine ? widget.firebase.unclaimRole(roleId) : widget.firebase.claimRole(roleId);
        },
      ),
    );
  }
}