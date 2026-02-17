import 'enums.dart';
import 'dice.dart';

class Spell {
  final String id;
  final String nome;
  final List<Elemento> costo;
  final CategoriaIncantesimo categoria;
  final String tipo;
  final String effetto;
  final Elemento sourceElement;

  Spell({
    required this.id,
    required this.nome,
    required this.costo,
    required this.categoria,
    required this.tipo,
    required this.effetto,
    required this.sourceElement,
  });

  bool canBeCast(List<ManaDice> hand) {
    if (costo.isEmpty) return true;
    if (hand.isEmpty) return false;

    List<Elemento> available = hand.map((d) => d.effectiveElement).toList();
    List<Elemento> missing = List.from(costo);

    List<Elemento> found = [];
    for (var req in missing) {
      if (available.contains(req)) {
        available.remove(req);
        found.add(req);
      }
    }
    
    for (var item in found) {
      missing.remove(item);
    }

    int jolly = available.where((e) => e == Elemento.jolly).length;
    return missing.length <= jolly;
  }

  factory Spell.fromExcelRow(List<dynamic> row, String fileName) {
    String getSafe(int i) => (i < row.length && row[i] != null) ? row[i].value.toString().trim() : "";
    
    String name = getSafe(3);
    if (name.isEmpty) return Spell(id: "err", nome: "", costo: [], categoria: CategoriaIncantesimo.base, tipo: "", effetto: "", sourceElement: Elemento.neutro);

    return Spell(
      id: "${fileName}_${name.toLowerCase()}",
      nome: name,
      costo: _parseCosto(getSafe(0)),
      categoria: _parseCategoria(getSafe(1)),
      tipo: getSafe(2),
      effetto: getSafe(4),
      sourceElement: fileName.toLowerCase().contains('rossa') ? Elemento.rosso : 
                     fileName.toLowerCase().contains('blu') ? Elemento.blu : 
                     fileName.toLowerCase().contains('verde') ? Elemento.verde : Elemento.giallo,
    );
  }

  static List<Elemento> _parseCosto(String raw) {
    List<Elemento> c = [];
    for (var i = 0; i < '🔴'.allMatches(raw).length; i++) c.add(Elemento.rosso);
    for (var i = 0; i < '🔵'.allMatches(raw).length; i++) c.add(Elemento.blu);
    for (var i = 0; i < '🟢'.allMatches(raw).length; i++) c.add(Elemento.verde);
    for (var i = 0; i < '🟡'.allMatches(raw).length; i++) c.add(Elemento.giallo);
    return c;
  }

  static CategoriaIncantesimo _parseCategoria(String raw) {
    String l = raw.toLowerCase();
    if (l.contains('base')) return CategoriaIncantesimo.base;
    if (l.contains('core')) return CategoriaIncantesimo.core;
    if (l.contains('utility')) return CategoriaIncantesimo.utility;
    if (l.contains('heavy')) return CategoriaIncantesimo.heavyFlex;
    if (l.contains('ultimate')) return CategoriaIncantesimo.ultimate;
    return CategoriaIncantesimo.base;
  }
}