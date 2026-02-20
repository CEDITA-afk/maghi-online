import 'enums.dart';

class OverlordAbility {
  final String nome;
  final String tipo; 
  final List<Elemento> costo; 
  final String effetto;
  final String costoDescrizione;
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
    List<Elemento> parsedCost = _parseIcons(json['cost'] ?? "");
    return OverlordAbility(
      nome: json['name'] ?? "Senza nome",
      tipo: json['type'] ?? "Rapida",
      costo: parsedCost,
      costoDescrizione: json['cost'] ?? "",
      effetto: json['effect'] ?? "Nessun effetto.",
      fillState: List.filled(parsedCost.length, null),
    );
  }

  OverlordAbility copyWith({List<Elemento?>? fillState}) {
    return OverlordAbility(
      nome: nome, tipo: tipo, costo: costo, effetto: effetto, costoDescrizione: costoDescrizione,
      fillState: fillState ?? List.from(currentFill),
    );
  }

  bool get isReady => !currentFill.contains(null);

  bool tryFillSlot(int index, Elemento cube) {
    if (index < 0 || index >= costo.length) return false;
    if (currentFill[index] != null) return false;
    Elemento required = costo[index];
    bool compatible = (cube == Elemento.jolly) || (required == Elemento.jolly) || (cube == required);
    if (compatible) {
      currentFill[index] = cube;
      return true;
    }
    return false;
  }

  void reset() => currentFill = List.filled(costo.length, null);

  static List<Elemento> _parseIcons(String raw) {
    if (raw == "Vasca" || raw.isEmpty) return []; 
    List<Elemento> list = [];
    if (raw.contains('🔴')) list.addAll(List.filled('🔴'.allMatches(raw).length, Elemento.rosso));
    if (raw.contains('🔵')) list.addAll(List.filled('🔵'.allMatches(raw).length, Elemento.blu));
    if (raw.contains('🟢')) list.addAll(List.filled('🟢'.allMatches(raw).length, Elemento.verde));
    if (raw.contains('🟡')) list.addAll(List.filled('🟡'.allMatches(raw).length, Elemento.giallo));
    if (raw.contains('⚫')) list.addAll(List.filled('⚫'.allMatches(raw).length, Elemento.jolly));
    return list;
  }
}

class OverlordLoadout {
  final String id;
  final String nome;
  final String descrizione;
  final Map<String, dynamic> scaling;
  final Map<String, dynamic> phases; // Gestione Fasi dinamiche

  final List<OverlordAbility> poolFast;
  final List<OverlordAbility> poolMedium;
  final List<OverlordAbility> poolUltimate;
  final List<OverlordAbility> poolChaos;
  List<OverlordAbility> abilitaSelezionate = [];

  OverlordLoadout({
    required this.id, required this.nome, required this.descrizione, required this.scaling,
    required this.phases,
    required this.poolFast, required this.poolMedium, required this.poolUltimate, required this.poolChaos,
    List<OverlordAbility>? selected,
  }) : abilitaSelezionate = selected ?? [];

  factory OverlordLoadout.fromJson(Map<String, dynamic> json) {
    var pools = json['pools'] ?? {};
    return OverlordLoadout(
      id: json['id'] ?? DateTime.now().toString(), 
      nome: json['name'] ?? "Boss Sconosciuto", 
      descrizione: json['description'] ?? "Nessuna descrizione.", 
      scaling: json['scaling'] ?? {},
      phases: json['phases'] ?? {},
      poolFast: (pools['fast'] as List? ?? []).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolMedium: (pools['medium'] as List? ?? []).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolUltimate: (pools['ultimate'] as List? ?? []).map((i) => OverlordAbility.fromJson(i)).toList(),
      poolChaos: (pools['chaos'] as List? ?? []).map((i) => OverlordAbility.fromJson(i)).toList(),
    );
  }

  int getHpFase1(int players) {
    var val = scaling['hp_fase1']?[players.toString()];
    return val is int ? val : 30;
  }
  
  int getRendita(int players) {
    var val = scaling['rendita']?[players.toString()];
    return val is int ? val : 2;
  }
  
  OverlordLoadout copyWithSelection(List<OverlordAbility> selection) {
    return OverlordLoadout(
      id: id, nome: nome, descrizione: descrizione, scaling: scaling, phases: phases,
      poolFast: poolFast, poolMedium: poolMedium, poolUltimate: poolUltimate, poolChaos: poolChaos,
      selected: selection.map((s) => s.copyWith(fillState: List.filled(s.costo.length, null))).toList()
    );
  }
}