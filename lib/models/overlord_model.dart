import 'enums.dart';

class OverlordAbility {
  final String nome;
  final String tipo; // Rapida, Media, Ultimate, Caos
  final List<Elemento> costo; // Il pattern richiesto (es. [Rosso, Rosso, Blu])
  final String effetto;
  final String costoDescrizione;
  
  // STATO DEL TRACCIATO
  // Una lista della stessa lunghezza del costo. 
  // null = slot vuoto. Elemento = slot riempito con quel cubetto.
  List<Elemento?> currentFill;

  OverlordAbility({
    required this.nome,
    required this.tipo,
    required this.costo,
    required this.effetto,
    required this.costoDescrizione,
    List<Elemento?>? fillState,
  }) : currentFill = fillState ?? List.filled(costo.length, null);

  factory OverlordAbility.fromJson(Map<String, dynamic> json) {
    List<Elemento> parsedCost = _parseIcons(json['cost']);
    return OverlordAbility(
      nome: json['name'],
      tipo: json['type'],
      costo: parsedCost,
      costoDescrizione: json['cost'],
      effetto: json['effect'],
      // Inizializza tracciato vuoto
      fillState: List.filled(parsedCost.length, null),
    );
  }

  // Clona l'abilità mantenendo lo stato (o resettandolo se necessario)
  OverlordAbility copyWith({List<Elemento?>? fillState}) {
    return OverlordAbility(
      nome: nome, tipo: tipo, costo: costo, effetto: effetto, costoDescrizione: costoDescrizione,
      fillState: fillState ?? List.from(currentFill),
    );
  }

  // Controlla se il tracciato è completo
  bool get isReady => !currentFill.contains(null);

  // Prova a inserire un cubetto in uno slot specifico
  bool tryFillSlot(int index, Elemento cube) {
    if (index < 0 || index >= costo.length) return false;
    if (currentFill[index] != null) return false; // Già pieno

    Elemento required = costo[index];

    // Regole di piazzamento:
    // 1. Se il cubetto è Jolly (nero), va ovunque.
    // 2. Se lo slot richiede Jolly (nero), accetta qualsiasi colore.
    // 3. Altrimenti il colore deve corrispondere esattamente.
    bool compatible = (cube == Elemento.jolly) || 
                      (required == Elemento.jolly) || 
                      (cube == required);

    if (compatible) {
      currentFill[index] = cube;
      return true;
    }
    return false;
  }

  // Svuota il tracciato dopo il lancio
  void reset() {
    for (int i = 0; i < currentFill.length; i++) {
      currentFill[i] = null;
    }
  }

  static List<Elemento> _parseIcons(String raw) {
    if (raw == "Vasca") return []; 
    List<Elemento> list = [];
    int r = '🔴'.allMatches(raw).length;
    int b = '🔵'.allMatches(raw).length;
    int v = '🟢'.allMatches(raw).length;
    int g = '🟡'.allMatches(raw).length;
    int j = '⚫'.allMatches(raw).length;
    list.addAll(List.filled(r, Elemento.rosso));
    list.addAll(List.filled(b, Elemento.blu));
    list.addAll(List.filled(v, Elemento.verde));
    list.addAll(List.filled(g, Elemento.giallo));
    list.addAll(List.filled(j, Elemento.jolly));
    return list;
  }
}

class OverlordLoadout {
  final String id;
  final String nome;
  final String descrizione;
  final Map<String, dynamic> scaling;
  
  final List<OverlordAbility> poolFast;
  final List<OverlordAbility> poolMedium;
  final List<OverlordAbility> poolUltimate;
  final List<OverlordAbility> poolChaos;

  List<OverlordAbility> abilitaSelezionate = [];

  OverlordLoadout({
    required this.id, required this.nome, required this.descrizione, required this.scaling,
    required this.poolFast, required this.poolMedium, required this.poolUltimate, required this.poolChaos,
    List<OverlordAbility>? selected,
  }) : abilitaSelezionate = selected ?? [];

  factory OverlordLoadout.fromJson(Map<String, dynamic> json) {
    var pools = json['pools'];
    return OverlordLoadout(
      id: json['id'], nome: json['name'], descrizione: json['description'] ?? "", scaling: json['scaling'],
      poolFast: (pools['fast'] as List).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolMedium: (pools['medium'] as List).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolUltimate: (pools['ultimate'] as List).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolChaos: (pools['chaos'] as List).map((i) => OverlordAbility.fromJson(i)).toList(),
    );
  }

  int getHpFase1(int players) => scaling['hp_fase1'][players.toString()] ?? 30;
  int getHpFase2(int players) => scaling['hp_fase2'][players.toString()] ?? 25;
  int getRendita(int players) => scaling['rendita'][players.toString()] ?? 2;
  
  // Quando copiamo per il gioco, assicuriamoci di creare nuove istanze delle abilità
  // così che il loro stato (currentFill) sia indipendente dal repository
  OverlordLoadout copyWithSelection(List<OverlordAbility> selection) {
    // Clona le abilità per resettare i tracciati all'inizio
    List<OverlordAbility> freshSelection = selection.map((s) => s.copyWith(fillState: List.filled(s.costo.length, null))).toList();
    
    return OverlordLoadout(
      id: id, nome: nome, descrizione: descrizione, scaling: scaling,
      poolFast: poolFast, poolMedium: poolMedium, poolUltimate: poolUltimate, poolChaos: poolChaos,
      selected: freshSelection
    );
  }
}