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

  // Dati di caricamento
  List<OverlordLoadout> _availableOverlords = [];
  List<Spell> _allSpells = [];
  List<MapScenario> _availableMaps = [];
  bool _isLoading = true;

  // Stato del Setup
  int _step = 1; // 1: Boss & Online, 2: Eroi, 3: Abilità Boss, 4: Mappa
  int _playerCount = 3;
  OverlordLoadout? _selectedOverlord;
  MapScenario? _selectedMap;
  
  // Controller per l'ID Stanza Online
  final TextEditingController _roomController = TextEditingController(text: "TAVOLO_1");
  
  // Grimori Eroi
  final Map<Elemento, List<Spell>> _heroDecks = {};
  
  // Abilità Boss Selezionate (Pools)
  final Set<OverlordAbility> _selFast = {};
  final Set<OverlordAbility> _selMedium = {};
  final Set<OverlordAbility> _selUltimate = {};
  final Set<OverlordAbility> _selChaos = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
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

      // Generazione automatica dei mazzi standard per tutti gli elementi
      _heroDecks[Elemento.rosso] = _generateStandardDeck(Elemento.rosso, spells);
      _heroDecks[Elemento.blu] = _generateStandardDeck(Elemento.blu, spells);
      _heroDecks[Elemento.verde] = _generateStandardDeck(Elemento.verde, spells);
      _heroDecks[Elemento.giallo] = _generateStandardDeck(Elemento.giallo, spells);

      _isLoading = false;
    });
  }

  List<Spell> _generateStandardDeck(Elemento element, List<Spell> allSpells) {
    List<Spell> deck = [];
    List<Spell> available = allSpells.where((s) => s.sourceElement == element).toList();

    bool isPure(Spell s) => s.costo.every((c) => c == element);
    
    // Slot 1: Base (Costo 1 Puro)
    _addSlot(deck, available, (s) => s.costo.length == 1 && isPure(s));
    // Slot 2: Core (Costo 2 Puro)
    _addSlot(deck, available, (s) => s.costo.length == 2 && isPure(s));
    // Slot 3: Utility (Costo 2 Ibrido)
    _addSlot(deck, available, (s) => s.costo.length == 2 && !isPure(s));
    // Slot 4: Impatto (Costo 3 No Ult)
    _addSlot(deck, available, (s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate);
    // Slot 5: Ultimate
    _addSlot(deck, available, (s) => s.categoria == CategoriaIncantesimo.ultimate);
    // Slot 6: Sinergia
    _addSlot(deck, available, (s) => s.costo.length == 2);
    // Slot 7: Heavy
    _addSlot(deck, available, (s) => s.costo.length == 3 && s.categoria != CategoriaIncantesimo.ultimate);
    // Slot 8: Tecnica
    _addSlot(deck, available, (s) => s.costo.length >= 3);
    // Slot 9 & 10: Wildcards
    _addSlot(deck, available, (s) => true);
    _addSlot(deck, available, (s) => true);

    return deck;
  }

  void _addSlot(List<Spell> deck, List<Spell> pool, bool Function(Spell) filter) {
    try {
      Spell match = pool.firstWhere((s) => filter(s) && !deck.contains(s));
      deck.add(match);
    } catch (e) { /* Slot lasciato vuoto se non ci sono match */ }
  }

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

  void _startGame() {
    List<OverlordAbility> finalAbilities = [
      ..._selFast,
      ..._selMedium,
      ..._selUltimate,
      ..._selChaos
    ];

    final finalLoadout = _selectedOverlord!.copyWithSelection(finalAbilities);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GamePage(
          numGiocatori: _playerCount,
          playerDecks: _heroDecks,
          bossLoadout: finalLoadout,
          mapScenario: _selectedMap!,
          roomId: _roomController.text.trim().isEmpty ? "ROOM_TEST" : _roomController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Setup Partita Online - Fase $_step/4"),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _step / 4, color: Colors.purpleAccent, backgroundColor: Colors.grey.shade800),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1: return _buildStep1_BossAndRoom();
      case 2: return _buildStep2_HeroDecks();
      case 3: return _buildStep3_BossLoadout();
      case 4: return _buildStep4_MapSelection();
      default: return Container();
    }
  }

  // --- STEP 1: BOSS, GIOCATORI & STANZA ONLINE ---
  Widget _buildStep1_BossAndRoom() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. STANZA ONLINE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
          const SizedBox(height: 10),
          TextField(
            controller: _roomController,
            decoration: const InputDecoration(
              labelText: "ID Stanza (Condividilo per giocare insieme)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key),
            ),
          ),
          const SizedBox(height: 30),
          const Text("2. SELEZIONA OVERLORD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<OverlordLoadout>(
            value: _selectedOverlord,
            items: _availableOverlords.map((b) => DropdownMenuItem(value: b, child: Text(b.nome))).toList(),
            onChanged: (v) => setState(() {
               _selectedOverlord = v;
               _selFast.clear(); _selMedium.clear(); _selUltimate.clear(); _selChaos.clear();
            }),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (_selectedOverlord != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8)),
              child: Text(_selectedOverlord!.descrizione, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
            ),
          ],
          const SizedBox(height: 30),
          const Text("3. NUMERO EROI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text("2 Eroi")),
              ButtonSegment(value: 3, label: Text("3 Eroi")),
              ButtonSegment(value: 4, label: Text("4 Eroi")),
            ],
            selected: {_playerCount},
            onSelectionChanged: (s) => setState(() => _playerCount = s.first),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: GRIMORI ---
  Widget _buildStep2_HeroDecks() {
    int readyCount = _heroDecks.values.where((l) => l.length == 10).length;
    bool isCountCorrect = readyCount >= _playerCount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("GRIMORI (Standard Caricati)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCountCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isCountCorrect ? Colors.green : Colors.red),
              ),
              child: Text(
                "Pronti: $readyCount / $_playerCount",
                style: TextStyle(fontWeight: FontWeight.bold, color: isCountCorrect ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text("I mazzi sono pre-configurati. Modificali se necessario.", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      color: hasDeck 
          ? (isComplete ? _getElementColor(e) : _getElementColor(e).withOpacity(0.5)) 
          : Colors.grey.shade800,
      elevation: hasDeck ? 4 : 1,
      child: InkWell(
        onTap: () => _openDeckBuilder(e),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isComplete ? Icons.check_circle : Icons.edit, color: hasDeck ? Colors.white : Colors.grey, size: 32),
              Text(e.name.toUpperCase(), style: TextStyle(color: hasDeck ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
              Text(isComplete ? "Mazzo Pronto" : "Personalizza", style: TextStyle(color: hasDeck ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
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

  // --- STEP 3: ABILITÀ BOSS ---
  Widget _buildStep3_BossLoadout() {
    if (_selectedOverlord == null) return const Center(child: Text("Seleziona un boss nella fase 1"));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PERSONALIZZA ${_selectedOverlord!.nome.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPoolSection("RAPIDE (2)", _selectedOverlord!.poolFast, _selFast, 2),
          _buildPoolSection("MEDIE (2)", _selectedOverlord!.poolMedium, _selMedium, 2),
          _buildPoolSection("ULTIMATE (1)", _selectedOverlord!.poolUltimate, _selUltimate, 1),
          _buildPoolSection("POTERI DEL CAOS (3)", _selectedOverlord!.poolChaos, _selChaos, 3),
        ],
      ),
    );
  }

  Widget _buildPoolSection(String title, List<OverlordAbility> pool, Set<OverlordAbility> selectedSet, int max) {
    bool isComplete = selectedSet.length == max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isComplete ? Colors.greenAccent : Colors.white)),
            Text("${selectedSet.length}/$max", style: TextStyle(fontWeight: FontWeight.bold, color: selectedSet.length > max ? Colors.red : Colors.grey)),
          ],
        ),
        const Divider(color: Colors.white10),
        ...pool.map((skill) {
          bool isSelected = selectedSet.contains(skill);
          return CheckboxListTile(
            title: Text(skill.nome, style: const TextStyle(fontSize: 14)),
            subtitle: Text(skill.effetto, style: const TextStyle(fontSize: 12, color: Colors.white60)),
            value: isSelected,
            activeColor: Colors.purpleAccent,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  if (selectedSet.length < max) selectedSet.add(skill);
                } else {
                  selectedSet.remove(skill);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // --- STEP 4: SELEZIONE MAPPA ---
  Widget _buildStep4_MapSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("4. SCEGLI IL CAMPO DI BATTAGLIA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _availableMaps.length,
            itemBuilder: (context, index) {
              final map = _availableMaps[index];
              bool isSelected = _selectedMap == map;
              return Card(
                color: isSelected ? Colors.purple.withOpacity(0.2) : Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected ? Colors.purpleAccent : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12)
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50, height: 50,
                      color: Colors.black,
                      child: map.backgroundAsset.isNotEmpty 
                        ? Image.asset(map.backgroundAsset, fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.map, color: Colors.grey))
                        : const Icon(Icons.map, color: Colors.grey),
                    ),
                  ),
                  title: Text(map.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(map.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.purpleAccent) : null,
                  onTap: () => setState(() => _selectedMap = map),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    bool canProceed = false;
    if (_step == 1) canProceed = _selectedOverlord != null && _roomController.text.isNotEmpty;
    if (_step == 2) {
      int readyCount = _heroDecks.values.where((l) => l.length == 10).length;
      canProceed = readyCount >= _playerCount;
    }
    if (_step == 3) {
      canProceed = _selFast.length == 2 && _selMedium.length == 2 && 
                   _selUltimate.length == 1 && _selChaos.length == 3;
    }
    if (_step == 4) canProceed = _selectedMap != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade900, border: const Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1) 
            OutlinedButton(onPressed: _prevStep, child: const Text("INDIETRO"))
          else 
            const SizedBox(),
          
          ElevatedButton(
            onPressed: canProceed ? (_step == 4 ? _startGame : _nextStep) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? Colors.purpleAccent : Colors.grey.shade800, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
            ),
            child: Text(_step == 4 ? "INIZIA BATTAGLIA" : "AVANTI"),
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