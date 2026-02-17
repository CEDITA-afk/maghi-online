import 'enums.dart';
import 'dice.dart';

enum EntityStatus { bruciato, bagnato, conduttore, unto, congelato, corrosione, stordito }

abstract class GameEntity {
  final String id; // ID univoco per identificare l'entità sulla mappa
  String nome;
  int hp;
  int maxHp;
  Set<EntityStatus> stati;

  GameEntity({
    required this.id,
    required this.nome,
    required this.hp,
    required this.maxHp,
    Set<EntityStatus>? stati,
  }) : stati = stati ?? {};

  bool get isDead => hp <= 0;
}

class Mago extends GameEntity {
  final Elemento elemento;
  bool isSpirito;
  int stamina; 
  int energy;
  List<ManaDice> savedDice;

  Mago({
    required String nome,
    required int hp,
    required int maxHp,
    required this.elemento,
    this.isSpirito = false,
    this.stamina = 3,
    this.energy = 0,
    List<ManaDice>? savedDice,
  }) : savedDice = savedDice ?? [],
       super(
         id: elemento.name, // L'elemento funge da ID univoco per i maghi
         nome: nome, 
         hp: hp, 
         maxHp: maxHp
       );

  void checkSpiritStatus() {
    if (hp <= 0 && !isSpirito) {
      isSpirito = true;
      hp = 0;
    }
  }
}

class BossOverlord extends GameEntity {
  int fase;
  Map<Elemento, int> cubettiMana;

  BossOverlord({
    required String nome,
    required int hp,
    required int maxHp,
    this.fase = 1,
  }) : cubettiMana = {
    Elemento.rosso: 0,
    Elemento.blu: 0,
    Elemento.verde: 0,
    Elemento.giallo: 0,
    Elemento.jolly: 0,
  }, super(
    id: 'boss', // ID fisso per il boss
    nome: nome, 
    hp: hp, 
    maxHp: maxHp
  );

  void riceviMana(Elemento tipo) {
    if (cubettiMana.containsKey(tipo)) {
      cubettiMana[tipo] = cubettiMana[tipo]! + 1;
    }
  }

  void spendeMana(List<Elemento> costo) {
    for (var req in costo) {
      if (cubettiMana[req]! > 0) {
        cubettiMana[req] = cubettiMana[req]! - 1;
      } else if (cubettiMana[Elemento.jolly]! > 0) {
        cubettiMana[Elemento.jolly] = cubettiMana[Elemento.jolly]! - 1;
      }
    }
  }
}

class Minion extends GameEntity {
  final String nomeTipo; // Es. "Scheletro", "Orco"
  final int numeroProgressivo; // Campo aggiunto per differenziare i minion

  Minion({
    required super.id, 
    required super.nome,
    required super.hp, 
    required super.maxHp,
    required this.nomeTipo,
    required this.numeroProgressivo, // Parametro aggiunto nel costruttore
  });
}