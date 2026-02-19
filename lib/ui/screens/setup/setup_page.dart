import 'package:flutter/material.dart';
import '../../../data/data_repository.dart';
import '../../../data/overlord_repository.dart';
import '../../../data/map_repository.dart';
import '../../../models/spell.dart';
import '../../../models/enums.dart';
import '../../../models/overlord_model.dart';
import '../../../models/map_model.dart';
import '../game_page.dart';
import 'spell_selection_view.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final DataRepository _spellRepo = DataRepository();
  final OverlordRepository _overlordRepo = OverlordRepository();
  final MapRepository _mapRepo = MapRepository();

  // Dati caricati dai repository
  List<OverlordLoadout> _availableOverlords = [];
  List<Spell> _allSpells = [];
  List<MapScenario> _availableMaps = [];
  bool _isLoading = true;

  // Stato del Setup
  int _step = 1; // 1: Boss e Giocatori, 2: Eroi, 3: Abilità Boss, 4: Mappa
  int _playerCount = 3;
  OverlordLoadout? _selectedOverlord;
  MapScenario? _selectedMap;
  
  // Controller per ID Stanza (usato se si vuole sincronizzare anche in Test)
  final TextEditingController _roomController = TextEditingController(text: "HOTSEAT_TEST");
  
  // Grimori selezionati
  final Map<Elemento, List<Spell>> _heroDecks = {};
  
  // Abilità Boss selezionate
  final Set<OverlordAbility> _selFast = {};
  final Set<OverlordAbility> _selMedium = {};
  final Set<OverlordAbility> _selUltimate = {};
  final Set<OverlordAbility> _selChaos = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bosses = await _overlordRepo.getAvailableOverlords();
    final spells = await _spellRepo.loadAllSpells();
    final maps = await _mapRepo.getAvailableScenarios();
    
    setState(() {
      _availableOverlords = bosses;
      _allSpells = spells;
      _availableMaps = maps;

      if (bosses.isNotEmpty) _selectedOverlord = bosses.first;
      if (maps.isNotEmpty) _selectedMap = maps.first;

      // Inizializza i mazzi standard in base al numero di giocatori iniziale (3)
      _updateDefaultDecks(spells);

      _isLoading = false;
    });
  }

  // Genera i mazzi standard per gli elementi scelti
  void _updateDefaultDecks(List<Spell> spells) {
    _heroDecks.clear();
    List<Elemento> elements = [Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo];
    for (int i = 0; i < _playerCount; i++) {
      _heroDecks[elements[i]] = _generateStandardDeck(elements[i], spells);
    }
  }

  List<Spell> _generateStandardDeck(Elemento element, List<Spell> allSpells) {
    List<Spell> deck = [];
    List<Spell> pool = allSpells.where((s) => s.sourceElement == element).toList();

    bool isPure(Spell s) => s.costo.every((c) => c == element);
    
    _addSlot(deck, pool, (s) => s.costo.length == 1 && isPure(s));
    _addSlot(deck, pool, (s) => s.costo.length == 2 && isPure(s));
    _addSlot(deck, pool, (s) => s.costo.length == 2 && !isPure(s));
    _addSlot(deck, pool, (s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate);
    _addSlot(deck, pool, (s) => s.categoria == CategoriaIncantesimo.ultimate);
    _addSlot(deck, pool, (s) => s.costo.length == 2);
    _addSlot(deck, pool, (s) => s.costo.length == 3);
    _addSlot(deck, pool, (s) => s.costo.length >= 3);
    _addSlot(deck, pool, (s) => true);
    _addSlot(deck, pool, (s) => true);

    return deck;
  }

  void _addSlot(List<Spell> deck, List<Spell> pool, bool Function(Spell) filter) {
    try {
      Spell match = pool.firstWhere((s) => filter(s) && !deck.contains(s));
      deck.add(match);
    } catch (e) {}
  }

  void _startGame() {
    List<OverlordAbility> finalAbilities = [..._selFast, ..._selMedium, ..._selUltimate, ..._selChaos];
    final finalLoadout = _selectedOverlord!.copyWithSelection(finalAbilities);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(
          numGiocatori: _heroDecks.length,
          playerDecks: _heroDecks,
          bossLoadout: finalLoadout,
          mapScenario: _selectedMap!,
          roomId: _roomController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Setup Modalità Test - Fase $_step/4"),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _step / 4, color: Colors.purpleAccent),
          Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildCurrentStep())),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      default: return Container();
    }
  }

  // --- STEP 1: BOSS & NUMERO GIOCATORI ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("1. SELEZIONA OVERLORD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonFormField<OverlordLoadout>(
          value: _selectedOverlord,
          items: _availableOverlords.map((b) => DropdownMenuItem(value: b, child: Text(b.nome))).toList(),
          onChanged: (v) => setState(() => _selectedOverlord = v),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 30),
        const Text("2. NUMERO EROI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text("1")),
            ButtonSegment(value: 2, label: Text("2")),
            ButtonSegment(value: 3, label: Text("3")),
            ButtonSegment(value: 4, label: Text("4")),
          ],
          selected: {_playerCount},
          onSelectionChanged: (s) => setState(() {
            _playerCount = s.first;
            _updateDefaultDecks(_allSpells);
          }),
        ),
      ],
    );
  }

  // --- STEP 2: GRIMORI (CON CORREZIONE DESELEZIONE) ---
  Widget _buildStep2() {
    return Column(
      children: [
        Text("CONFIGURA GRIMORI (${_heroDecks.length} / $_playerCount)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            children: [
              _buildDeckCard(Elemento.rosso),
              _buildDeckCard(Elemento.blu),
              _buildDeckCard(Elemento.verde),
              _buildDeckCard(Elemento.giallo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard(Elemento e) {
    bool hasDeck = _heroDecks.containsKey(e);
    
    return Card(
      color: hasDeck ? _getElementColor(e) : Colors.grey.shade900,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (!hasDeck) {
                setState(() => _heroDecks[e] = _generateStandardDeck(e, _allSpells));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SpellSelectionView(
                  element: e,
                  allSpells: _allSpells.where((s) => s.sourceElement == e).toList(),
                  initialSelection: _heroDecks[e]!,
                  onConfirm: (list) => setState(() => _heroDecks[e] = list),
                )));
              }
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(hasDeck ? Icons.auto_stories : Icons.add, color: Colors.white, size: 30),
                  const SizedBox(height: 5),
                  Text(e.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(hasDeck ? "Mazzo Pronto" : "Clicca per attivare", style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
          // IL TASTO "X" PER DESELEZIONARE
          if (hasDeck)
            Positioned(
              top: 0, right: 0,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _heroDecks.remove(e)),
              ),
            ),
        ],
      ),
    );
  }

  // --- STEP 3: ABILITÀ BOSS ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPoolSection("RAPIDE (2)", _selectedOverlord!.poolFast, _selFast, 2),
          _buildPoolSection("MEDIE (2)", _selectedOverlord!.poolMedium, _selMedium, 2),
          _buildPoolSection("ULTIMATE (1)", _selectedOverlord!.poolUltimate, _selUltimate, 1),
          _buildPoolSection("CAOS (3)", _selectedOverlord!.poolChaos, _selChaos, 3),
        ],
      ),
    );
  }

  Widget _buildPoolSection(String title, List<OverlordAbility> pool, Set<OverlordAbility> sel, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text("$title - ${sel.length}/$max", style: const TextStyle(fontWeight: FontWeight.bold))),
        ...pool.map((a) => CheckboxListTile(
          title: Text(a.nome),
          value: sel.contains(a),
          onChanged: (v) => setState(() {
            if (v!) { if (sel.length < max) sel.add(a); } else { sel.remove(a); }
          }),
        )),
      ],
    );
  }

  // --- STEP 4: MAPPA ---
  Widget _buildStep4() {
    return ListView.builder(
      itemCount: _availableMaps.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(_availableMaps[i].name),
        trailing: _selectedMap == _availableMaps[i] ? const Icon(Icons.check_circle, color: Colors.purpleAccent) : null,
        onTap: () => setState(() => _selectedMap = _availableMaps[i]),
      ),
    );
  }

  Widget _buildBottomBar() {
    bool canProceed = false;
    if (_step == 1) canProceed = true;
    if (_step == 2) canProceed = _heroDecks.length == _playerCount;
    if (_step == 3) canProceed = _selFast.length == 2 && _selMedium.length == 2 && _selUltimate.length == 1;
    if (_step == 4) canProceed = _selectedMap != null;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1) TextButton(onPressed: () => setState(() => _step--), child: const Text("INDIETRO")),
          const Spacer(),
          ElevatedButton(
            onPressed: canProceed ? (_step == 4 ? _startGame : () => setState(() => _step++)) : null,
            child: Text(_step == 4 ? "INIZIA TEST" : "AVANTI"),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(Elemento e) {
    switch(e) {
      case Elemento.rosso: return Colors.red.shade900;
      case Elemento.blu: return Colors.blue.shade900;
      case Elemento.verde: return Colors.green.shade900;
      case Elemento.giallo: return Colors.orange.shade900;
      default: return Colors.grey;
    }
  }
}