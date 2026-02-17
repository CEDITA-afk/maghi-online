import '../models/entities.dart';
import '../models/enums.dart';

class GameStateManager {
  // Entità
  late Overlord boss;
  late Map<Elemento, Mago> maghi;
  
  // Stato Round
  int roundAttuale = 1;
  List<Elemento> maghiCheHannoAgito = [];
  Elemento? magoAttivo;
  bool isFaseOverlord = false;

  GameStateManager() {
    _inizializzaPartita();
  }

  void _inizializzaPartita() {
    boss = Overlord(nome: "EXO-01", hp: 30, maxHp: 30);
    maghi = {
      Elemento.rosso: Mago(nome: "Mago Rosso", hp: 15, maxHp: 15, elemento: Elemento.rosso),
      Elemento.blu: Mago(nome: "Mago Blu", hp: 15, maxHp: 15, elemento: Elemento.blu),
      Elemento.verde: Mago(nome: "Mago Verde", hp: 15, maxHp: 15, elemento: Elemento.verde),
      Elemento.giallo: Mago(nome: "Mago Giallo", hp: 15, maxHp: 15, elemento: Elemento.giallo),
    };
  }

  // Metodo per applicare danni e gestire la morte
  void applicaDannoAMago(Elemento colore, int danno) {
    final mago = maghi[colore];
    if (mago != null) {
      mago.hp -= danno;
      mago.checkStatus();
    }
  }

  void aggiungiStato(dynamic entita, EntityStatus stato) {
    entita.stati.add(stato);
  }
}