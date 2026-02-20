import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/entities.dart';
import '../../models/enums.dart';
import '../../models/spell.dart';
import '../../models/dice.dart';
import '../../models/overlord_model.dart';
import '../../models/map_model.dart';
import '../../logic/dice_manager.dart';
import '../../logic/firebase_service.dart';

import '../widgets/status_bar.dart';
import '../widgets/dice_tray.dart';
import '../widgets/turn_control_bar.dart';
import '../widgets/concentration_panel.dart';
import '../widgets/dice_selection_dialog.dart';
import '../views/battle_view.dart';
import '../views/overlord_view.dart';
import '../views/interactive_map_view.dart';

class GamePage extends StatefulWidget {
  final int numGiocatori;
  final Map<Elemento, List<Spell>> playerDecks;
  final OverlordLoadout bossLoadout;
  final MapScenario mapScenario;
  final String roomId;
  
  final String? myUserId;
  final Map<String, dynamic> roles;

  const GamePage({
    super.key,
    required this.numGiocatori,
    required this.playerDecks,
    required this.bossLoadout,
    required this.mapScenario,
    required this.roomId,
    this.myUserId,
    this.roles = const {},
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final DiceManager _dice = DiceManager();
  late FirebaseService _firebase;
  
  late TabController _tabController; 
  late TabController _mainViewTabController; 

  late BossOverlord _boss;
  late Map<Elemento, Mago> _maghi;
  late List<Elemento> _activeElements;
  
  List<Minion> _minions = [];
  List<MapObject> _customObjects = [];
  Map<String, Point> _savedPositions = {}; 
  int _minionCounter = 0;
  
  int _actions = 0;
  Elemento? _activeHero;
  List<Elemento> _actedHeroes = [];
  bool _isOverlordPhase = false;
  
  List<ManaDice> _hand = [];
  final Set<int> _selectedDiceIndices = {};

  // NUOVO: Variabile per la Bacheca
  List<Map<String, dynamic>> _sharedNotes = [];

  bool get isHotseat => widget.myUserId == null;
  
  bool canControl(String roleName) {
    if (isHotseat) return true;
    return widget.roles[roleName] == widget.myUserId;
  }

  bool canInteractMage(Elemento e) => canControl(e.name) && _activeHero == e;
  bool canInteractOverlord() => canControl('overlord') && _isOverlordPhase;

  @override
  void initState() {
    super.initState();
    _firebase = FirebaseService(widget.roomId);
    _initGame();
    _initDefaultPositions();
    
    _tabController = TabController(length: _activeElements.length + 1, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {}); 
    });
    
    _mainViewTabController = TabController(length: 2, vsync: this);
  }

  void _initGame() {
    _activeElements = [Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo]
        .where((e) => widget.playerDecks.containsKey(e)).toList();

    int startHp = widget.bossLoadout.getHpFase1(widget.numGiocatori);
    _boss = BossOverlord(nome: widget.bossLoadout.nome, hp: startHp, maxHp: startHp);

    _maghi = {};
    for (var el in _activeElements) {
      _maghi[el] = Mago(nome: el.name.toUpperCase(), hp: 15, maxHp: 15, elemento: el);
    }
  }

  void _initDefaultPositions() {
    _savedPositions['boss'] = Point((widget.mapScenario.cols / 2).floor(), 2);
    int startX = 1;
    for (var el in _activeElements) {
      _savedPositions[el.name] = Point(startX, widget.mapScenario.rows - 2);
      startX += 2;
    }
    for (var obj in widget.mapScenario.initialObjects) {
      _savedPositions[obj.id] = Point(obj.x, obj.y);
    }
  }

  void _pushFullState() {
    FirebaseFirestore.instance.collection('sessions').doc(widget.roomId).set({
      'boss_hp': _boss.hp,
      'boss_mana': _boss.cubettiMana.map((key, value) => MapEntry(key.name, value)),
      'boss_abilities': widget.bossLoadout.abilitaSelezionate.map((a) => {
        'nome': a.nome,
        'currentFill': a.currentFill.map((e) => e?.name).toList(),
      }).toList(),
      'hero_status': _maghi.map((key, m) => MapEntry(key.name, {'hp': m.hp, 'energy': m.energy, 'isSpirito': m.isSpirito})),
      'minions': _minions.map((m) => {'id': m.id, 'nome': m.nome, 'hp': m.hp, 'maxHp': m.maxHp, 'tipo': m.nomeTipo, 'num': m.numeroProgressivo}).toList(),
      'active_hero': _activeHero?.name,
      'actions': _actions,
      'acted_heroes': _actedHeroes.map((e) => e.name).toList(),
      'is_overlord_phase': _isOverlordPhase,
      'hand': _hand.map((d) => {'id': d.id, 'source': d.sourceColor.name, 'effective': d.effectiveElement.name, 'val': d.faceValue}).toList(),
      'selected_dice': _selectedDiceIndices.toList(),
      'shared_notes': _sharedNotes, // SALVA LA BACHECA SUL CLOUD
    }, SetOptions(merge: true));
  }

  void _updatePosition(String id, int x, int y) {
    setState(() => _savedPositions[id] = Point(x, y));
    _firebase.updatePosition(id, x, y);
  }

  void _spawnMinionFromMap(Minion template) {
    setState(() {
      _minionCounter++;
      final m = Minion(id: "minion_${DateTime.now().millisecondsSinceEpoch}", nome: "Scherano $_minionCounter", hp: 5, maxHp: 5, nomeTipo: "Scherano", numeroProgressivo: _minionCounter);
      _minions.add(m);
      _savedPositions[m.id] = Point(5, 5);
      _pushFullState();
    });
  }

  void _spawnObjectFromMap(MapObject obj) {
    setState(() {
      _customObjects.add(obj);
      _savedPositions[obj.id] = Point(obj.x, obj.y);
      _pushFullState();
    });
  }
  
  void _handleMinionTap(Minion m) {
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(m.nome),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () { setState(() => m.hp--); setDialogState((){}); _pushFullState(); }),
                Text("HP: ${m.hp}"),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () { setState(() => m.hp++); setDialogState((){}); _pushFullState(); }),
              ],
            ),
            actions: [
              TextButton(onPressed: () { setState(() { _minions.remove(m); _savedPositions.remove(m.id); _pushFullState(); }); Navigator.pop(ctx); }, child: const Text("ELIMINA", style: TextStyle(color: Colors.red))),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHIUDI")),
            ],
          ),
        ),
      );
  }

  Future<void> _startHeroTurn(Elemento e) async {
    setState(() {
      _activeHero = e;
      _actions = 2; 
      _hand.clear();
      _selectedDiceIndices.clear();
      _pushFullState();
    });

    Mago hero = _maghi[e]!;
    List<ManaDice> keptDice = hero.savedDice.toList();
    hero.savedDice.clear(); 

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DiceSelectionDialog(
        maxSelection: 3,
        onConfirm: (colors) {
          setState(() {
            _hand.addAll(keptDice);
            _hand.addAll(_dice.rollSpecific(colors));
            _pushFullState();
          });
        },
      ),
    );
  }

  void _onHpChange(dynamic entity, int delta) {
    setState(() {
      entity.hp = (entity.hp + delta).clamp(0, 999);
      if (entity is Mago) entity.checkSpiritStatus();
      _pushFullState();
    });
  }

  void _cast(Spell s) {
    setState(() {
      _actions--;
      List<int> indicesToRemove = [];
      List<ManaDice> tempHand = List.from(_hand);
      for (var req in List.from(s.costo)) {
         int idx = tempHand.indexWhere((d) => d.effectiveElement == req && !indicesToRemove.contains(tempHand.indexOf(d)));
         if (idx == -1) idx = tempHand.indexWhere((d) => d.effectiveElement == Elemento.jolly && !indicesToRemove.contains(tempHand.indexOf(d)));
         if (idx != -1) indicesToRemove.add(tempHand.indexOf(tempHand[idx]));
      }
      indicesToRemove.sort((a, b) => b.compareTo(a));
      for (int i in indicesToRemove) {
        _boss.riceviMana(_hand[i].effectiveElement); 
        _hand.removeAt(i);
      }
      _selectedDiceIndices.clear();
      _checkEndTurn();
      _pushFullState();
    });
  }

  void _checkEndTurn() {
    if (_actions <= 0) {
      if (_activeHero != null) _actedHeroes.add(_activeHero!);
      _activeHero = null;
      _isOverlordPhase = true;
      _tabController.animateTo(_activeElements.length); 
      _pushFullState();
    }
  }

  void _finishOverlordPhase() {
    setState(() {
      if (_actedHeroes.length == _activeElements.length) {
        for (int i = 0; i < widget.bossLoadout.getRendita(widget.numGiocatori); i++) _boss.riceviMana(Elemento.jolly);
        _actedHeroes.clear(); 
      }
      _isOverlordPhase = false;
      _pushFullState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebase.gameStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          if (data['positions'] != null) (data['positions'] as Map).forEach((id, coord) => _savedPositions[id] = Point(coord['x'], coord['y']));
          if (data['boss_hp'] != null) _boss.hp = data['boss_hp'];
          if (data['boss_mana'] != null) (data['boss_mana'] as Map).forEach((k, v) => _boss.cubettiMana[Elemento.values.firstWhere((e) => e.name == k)] = v);
          
          if (data['boss_abilities'] != null) {
            List abDataList = data['boss_abilities'];
            for (var abData in abDataList) {
              try {
                var ability = widget.bossLoadout.abilitaSelezionate.firstWhere((a) => a.nome == abData['nome']);
                List fillData = abData['currentFill'];
                for (int i = 0; i < fillData.length; i++) {
                  ability.currentFill[i] = fillData[i] != null ? Elemento.values.firstWhere((e) => e.name == fillData[i]) : null;
                }
              } catch (e) {}
            }
          }

          if (data['hero_status'] != null) {
            (data['hero_status'] as Map).forEach((k, st) {
               Elemento e = Elemento.values.firstWhere((ev) => ev.name == k);
               if (_maghi.containsKey(e)) { _maghi[e]!.hp = st['hp']; _maghi[e]!.energy = st['energy']; _maghi[e]!.isSpirito = st['isSpirito']; }
            });
          }

          if (data['hand'] != null) {
            _hand = (data['hand'] as List).map((d) => ManaDice(id: d['id'], sourceColor: Elemento.values.firstWhere((e) => e.name == d['source']), effectiveElement: Elemento.values.firstWhere((e) => e.name == d['effective']), faceValue: d['val'])).toList();
          }
          
          if (data['selected_dice'] != null) {
            _selectedDiceIndices.clear();
            _selectedDiceIndices.addAll(List<int>.from(data['selected_dice']));
          }
          
          // NUOVO: Sincronizza le note condivise
          if (data['shared_notes'] != null) {
            _sharedNotes = List<Map<String, dynamic>>.from(data['shared_notes']);
          }

          if (data['actions'] != null) _actions = data['actions'];
          if (data['is_overlord_phase'] != null) _isOverlordPhase = data['is_overlord_phase'];
          _activeHero = data['active_hero'] != null ? Elemento.values.firstWhere((e) => e.name == data['active_hero']) : null;
          if (data['acted_heroes'] != null) _actedHeroes = (data['acted_heroes'] as List).map((n) => Elemento.values.firstWhere((e) => e.name == n)).toList();
        }

        List<Widget> tabWidgets = _activeElements.map((e) {
          bool hasActed = _actedHeroes.contains(e);
          return Tab(
            icon: Icon(
              hasActed ? Icons.check_circle : _getIcon(e),
              color: hasActed ? Colors.white30 : _getElementColor(e),
            ),
          );
        }).toList();
        tabWidgets.add(const Tab(icon: Icon(Icons.security, color: Colors.purpleAccent))); 

        return Scaffold(
          appBar: AppBar(
            title: Text("PIN: ${widget.roomId}"),
            backgroundColor: Colors.grey.shade900,
            actions: [
              // BOTTone PER APRIRE LA BACHECA
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.sticky_note_2, color: Colors.yellow),
                  tooltip: "Bacheca Note",
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              IconButton(icon: const Icon(Icons.table_bar), onPressed: () => _mainViewTabController.animateTo(0)),
              IconButton(icon: const Icon(Icons.map), onPressed: () => _mainViewTabController.animateTo(1)),
            ],
            bottom: TabBar(controller: _tabController, tabs: tabWidgets),
          ),
          endDrawer: _buildSharedNotesDrawer(), // IL PANNELLO LATERALE
          body: TabBarView(
            controller: _mainViewTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTabletopView(),
              InteractiveMapView(scenario: widget.mapScenario, heroes: _maghi, boss: _boss, minions: _minions, customObjects: _customObjects, savedPositions: _savedPositions, onPositionChanged: _updatePosition, onSpawnMinion: _spawnMinionFromMap, onSpawnObject: _spawnObjectFromMap, onMinionTap: _handleMinionTap),
            ],
          ),
        );
      }
    );
  }

  // NUOVO WIDGET: IL PANNELLO LATERALE
  Widget _buildSharedNotesDrawer() {
    TextEditingController noteController = TextEditingController();
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            color: Colors.black,
            child: const Row(
              children: [
                Icon(Icons.sticky_note_2, color: Colors.yellow),
                SizedBox(width: 10),
                Text("BACHECA STATUS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: _sharedNotes.isEmpty
                ? const Center(child: Text("Nessuna nota attiva.\nUsa la bacheca per tracciare\nfasi, condizioni o ancore.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: _sharedNotes.length,
                    itemBuilder: (context, i) {
                      final nota = _sharedNotes[i];
                      return Card(
                        color: Color(nota['color'] ?? Colors.grey.shade800.value),
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(nota['text'], style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white54),
                            onPressed: () => setState(() {
                              _sharedNotes.removeAt(i);
                              _pushFullState();
                            }),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Es: 'Fase 2', 'Veleno verde'",
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true, fillColor: Colors.black54
                    ),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (noteController.text.isNotEmpty) {
                      setState(() {
                        Color noteColor = widget.myUserId == null ? Colors.blueGrey.shade800 : 
                                          (widget.roles['overlord'] == widget.myUserId ? Colors.red.shade900 : Colors.blue.shade900);
                        _sharedNotes.add({
                          'text': noteController.text,
                          'color': noteColor.value,
                        });
                        _pushFullState();
                      });
                      noteController.clear();
                    }
                  }
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabletopView() {
    return Column(
      children: [
        StatusBar(boss: _boss, maghi: _maghi, onHpChange: _onHpChange),
        if (_activeHero != null)
          IgnorePointer(
            ignoring: !canInteractMage(_activeHero!),
            child: TurnControlBar(
              actions: _actions,
              energy: _maghi[_activeHero]!.energy,
              onMove: () { setState(() => _actions--); _pushFullState(); _mainViewTabController.animateTo(1); },
              onInteract: () => setState(() { _actions--; _pushFullState(); }),
              onHelp: () => setState(() { _actions--; _pushFullState(); }),
              onDisarm: () {},
              onEndTurn: () => setState(() { _actions = 0; _checkEndTurn(); }),
            ),
          ),
        Expanded(child: _buildMainArea()),
        if (_activeHero != null) ...[
          IgnorePointer(
            ignoring: !canInteractMage(_activeHero!),
            child: ConcentrationPanel(
              selectedDiceCount: _selectedDiceIndices.length,
              currentEnergy: _maghi[_activeHero]!.energy,
              onConvert: () {
                if (_selectedDiceIndices.isEmpty) return;
                setState(() { _maghi[_activeHero]!.energy += _selectedDiceIndices.length; List<int> sorted = _selectedDiceIndices.toList()..sort((a,b) => b.compareTo(a)); for (var i in sorted) _hand.removeAt(i); _selectedDiceIndices.clear(); _pushFullState(); });
              },
              onReroll: () {
                if (_selectedDiceIndices.isEmpty) return;
                setState(() { _maghi[_activeHero]!.energy -= _selectedDiceIndices.length; for (var i in _selectedDiceIndices) _hand[i] = _dice.rerollDie(_hand[i]); _pushFullState(); });
              },
              onKeep: () {
                if (_selectedDiceIndices.length != 1) return;
                setState(() { _maghi[_activeHero]!.energy -= 1; int idx = _selectedDiceIndices.first; _maghi[_activeHero]!.savedDice.add(_hand[idx]); _hand.removeAt(idx); _selectedDiceIndices.clear(); _pushFullState(); });
              },
            ),
          ),
          IgnorePointer(
            ignoring: !canInteractMage(_activeHero!),
            child: DiceTray(
              rolledHand: _hand,
              selectedIndices: _selectedDiceIndices,
              onDieTap: (i) => setState(() { _selectedDiceIndices.contains(i) ? _selectedDiceIndices.remove(i) : _selectedDiceIndices.add(i); _pushFullState(); }),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildMainArea() {
    int tabIndex = _tabController.index;
    bool isOverlordTab = tabIndex == _activeElements.length;

    if (isOverlordTab) {
      return AbsorbPointer(
        absorbing: !canInteractOverlord(),
        child: OverlordView(
          boss: _boss,
          bossLoadout: widget.bossLoadout,
          abilitaBoss: widget.bossLoadout.abilitaSelezionate,
          onAssignCube: (a, i, c) { 
            setState(() {
              if (a.tryFillSlot(i, c)) {
                _boss.cubettiMana[c] = (_boss.cubettiMana[c] ?? 1) - 1;
              }
            }); 
            _pushFullState(); 
          },
          onCastAbility: (a) { 
            setState(() => a.reset()); 
            _pushFullState(); 
          },
          onContinue: _finishOverlordPhase,
          isRoundOver: _actedHeroes.length == _activeElements.length,
        ),
      );
    }

    Elemento currentMage = _activeElements[tabIndex];

    if (_isOverlordPhase) return const Center(child: Text("Turno dell'Overlord in corso...", style: TextStyle(fontSize: 18, color: Colors.white54)));

    if (_activeHero == currentMage) {
      return AbsorbPointer(
        absorbing: !canInteractMage(currentMage),
        child: BattleView(
          deck: widget.playerDecks[currentMage] ?? [],
          hand: _hand,
          actions: _actions,
          activeElement: currentMage,
          onCast: _cast,
        ),
      );
    }

    if (_activeHero != null) return Center(child: Text("Turno di ${_activeHero!.name.toUpperCase()} in corso...", style: const TextStyle(fontSize: 18)));

    bool hasActed = _actedHeroes.contains(currentMage);
    if (hasActed) return const Center(child: Text("Questo Eroe ha già agito in questo round. Seleziona un altro Eroe."));

    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: Text("INIZIA TURNO ${currentMage.name.toUpperCase()}"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          backgroundColor: _getElementColor(currentMage),
          foregroundColor: Colors.white,
        ),
        onPressed: canControl(currentMage.name) ? () => _startHeroTurn(currentMage) : null,
      )
    );
  }

  IconData _getIcon(Elemento e) => e == Elemento.rosso ? Icons.local_fire_department : e == Elemento.blu ? Icons.water_drop : e == Elemento.verde ? Icons.grass : Icons.flash_on;
  Color _getElementColor(Elemento e) => e == Elemento.rosso ? Colors.red : e == Elemento.blu ? Colors.blue : e == Elemento.verde ? Colors.green : Colors.orange;
}