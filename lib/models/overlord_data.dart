import 'enums.dart';

class OverlordAbility {
  final String nome;
  final String tipo; // Rapida, Tattica, Ultimate
  final List<Elemento> costo;
  final String effetto;

  OverlordAbility({required this.nome, required this.tipo, required this.costo, required this.effetto});
}

class OverlordEvent {
  final String nome;
  final int turnoAttivazione;
  final int dadiDisinnesco;
  final String effetto;

  OverlordEvent({required this.nome, required this.turnoAttivazione, required this.dadiDisinnesco, required this.effetto});
}

class OverlordData {
  final String nome;
  final String elementoDominante;
  // Scaling HP basato sul numero di giocatori
  final Map<int, int> hpFase1; 
  final Map<int, int> hpFase2;
  final List<OverlordAbility> abilita;
  final List<OverlordEvent> eventi;

  OverlordData({
    required this.nome,
    required this.elementoDominante,
    required this.hpFase1,
    required this.hpFase2,
    required this.abilita,
    required this.eventi,
  });
}