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

  List<OverlordLoadout> _availableOverlords = [];
  List<Spell> _allSpells = [];
  List<MapScenario> _availableMaps = [];
  bool _isLoading = true;

  int _step = 1; // 1: Boss & Eroi, 2: Grimori, 3: Abilità Boss, 4: Mappa
  int _playerCount = 3;
  OverlordLoadout? _selectedOverlord;
  MapScenario? _selectedMap;
  
  final Map<Elemento, List<Spell>> _heroDecks = {};
  
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
    
    if (mounted) {
      setState(() {
        _availableOverlords = bosses;
        _allSpells = spells;
        _availableMaps = maps;

        if (bosses.isNotEmpty) _selectedOverlord = bosses.first;
        if (maps.isNotEmpty) _selectedMap = maps.first;

        _updateDefaultDecks(spells);
        _isLoading = false;
      });
    }
  }

  void _updateDefaultDecks(List<Spell> spells) {
    _heroDecks.clear();
    List<Elemento> defaults = [Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo];
    for (int i = 0; i < _playerCount; i++) {
      _heroDecks[defaults[i]] = _generateStandardDeck(defaults[i], spells);
    }
  }

  List<Spell> _generateStandardDeck(Elemento element, List<Spell> allSpells) {
    List<Spell> deck = [];
    List<Spell> available = allSpells.where((s) => s.sourceElement == element).toList();
    bool isPure(Spell s) => s.costo.every((c) => c == element);
    
    void add(bool Function(Spell) filter) {
      try {
        Spell match = available.firstWhere((s) => filter(s) && !deck.contains(s));
        deck.add(match);
      } catch (e) {}
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

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

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
          roomId: "HOTSEAT", // ID fisso per Hotseat locale
          myUserId: null,    // NULL = Modalità Hotseat, controlli tutto tu
          roles: const {},   // Nessun limite di ruolo
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Modalità Test (Hotseat) - Fase $_step/4"),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
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

  Widget _buildStep2() {
    int readyCount = _heroDecks.values.where((l) => l.length == 10).length;
    bool isCountCorrect = readyCount == _playerCount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("GRIMORI EROI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCountCorrect ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isCountCorrect ? Colors.green : Colors.orange),
              ),
              child: Text("Selezionati: $readyCount / $_playerCount", style: TextStyle(fontWeight: FontWeight.bold, color: isCountCorrect ? Colors.green : Colors.orange)),
            ),
          ],
        ),
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
    bool isComplete = hasDeck && _heroDecks[e]!.length == 10;
    
    return Card(
      color: hasDeck ? _getElementColor(e) : Colors.grey.shade800,
      elevation: hasDeck ? 4 : 1,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (!hasDeck) {
                setState(() => _heroDecks[e] = _generateStandardDeck(e, _allSpells));
              } else {
                _openDeckBuilder(e);
              }
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(hasDeck ? (isComplete ? Icons.check_circle : Icons.edit) : Icons.add, color: Colors.white, size: 32),
                  Text(e.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(hasDeck ? (isComplete ? "Mazzo Pronto" : "Personalizza") : "Aggiungi", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          if (hasDeck) // X per deselezionare il mago se vogliamo giocare con meno eroi
            Positioned(
              top: 4, right: 4,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _heroDecks.remove(e)),
              ),
            ),
        ],
      ),
    );
  }

  void _openDeckBuilder(Elemento e) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SpellSelectionView(
      element: e,
      allSpells: _allSpells.where((s) => s.sourceElement == e).toList(),
      initialSelection: _heroDecks[e] ?? [],
      onConfirm: (list) => setState(() => _heroDecks[e] = list),
    )));
  }

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
          title: Text(a.nome), subtitle: Text(a.effetto, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          value: sel.contains(a),
          onChanged: (v) => setState(() {
            if (v!) { if (sel.length < max) sel.add(a); } else { sel.remove(a); }
          }),
        )),
      ],
    );
  }

  Widget _buildStep4() {
    return ListView.builder(
      itemCount: _availableMaps.length,
      itemBuilder: (context, i) => Card(
        color: _selectedMap == _availableMaps[i] ? Colors.purple.withOpacity(0.2) : Colors.grey.shade900,
        child: ListTile(
          title: Text(_availableMaps[i].name),
          trailing: _selectedMap == _availableMaps[i] ? const Icon(Icons.check_circle, color: Colors.purpleAccent) : null,
          onTap: () => setState(() => _selectedMap = _availableMaps[i]),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    bool canProceed = false;
    if (_step == 1) canProceed = _selectedOverlord != null;
    if (_step == 2) canProceed = _heroDecks.length == _playerCount;
    if (_step == 3) canProceed = _selFast.length == 2 && _selMedium.length == 2 && _selUltimate.length == 1;
    if (_step == 4) canProceed = _selectedMap != null;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1) OutlinedButton(onPressed: _prevStep, child: const Text("INDIETRO")),
          const Spacer(),
          ElevatedButton(
            onPressed: canProceed ? (_step == 4 ? _startGame : _nextStep) : null,
            style: ElevatedButton.styleFrom(backgroundColor: canProceed ? Colors.purpleAccent : Colors.grey),
            child: Text(_step == 4 ? "INIZIA TEST" : "AVANTI"),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(Elemento e) {
    if (e == Elemento.rosso) return Colors.red.shade900;
    if (e == Elemento.blu) return Colors.blue.shade900;
    if (e == Elemento.verde) return Colors.green.shade900;
    return Colors.orange.shade900;
  }
}