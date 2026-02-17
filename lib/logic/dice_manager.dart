import 'dart:math';
import '../models/dice.dart';
import '../models/enums.dart';

class DiceManager {
  final Random _rng = Random();

  // Genera dadi specifici basati su una lista di colori richiesti
  List<ManaDice> rollSpecific(List<Elemento> sources) {
    List<ManaDice> results = [];

    for (int i = 0; i < sources.length; i++) {
      Elemento source = sources[i];
      
      // LOGICA STATISTICA:
      // 1 (16%): JOLLY
      // 2-3 (33%): COLORE PURO (Stesso del dado fisico)
      // 4-5-6 (50%): IBRIDI (Gli altri 3 colori)
      
      int roll = _rng.nextInt(6) + 1; // 1-6
      Elemento effectiveElement;
      
      if (roll == 1) {
        effectiveElement = Elemento.jolly;
      } else if (roll == 2 || roll == 3) {
        effectiveElement = source; // Colore Puro
      } else {
        // Genera uno degli altri 3 colori (esclude il sorgente)
        List<Elemento> others = [
          Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo
        ]..remove(source);
        
        // Mappa 4, 5, 6 sugli indici 0, 1, 2 della lista rimanente
        effectiveElement = others[roll - 4]; 
      }

      results.add(ManaDice(
        id: "${source.name}_${DateTime.now().microsecondsSinceEpoch}_$i",
        sourceColor: source,
        effectiveElement: effectiveElement, // Passa il valore calcolato qui sopra
        faceValue: roll,
      ));
    }
    return results;
  }

  // Reroll mantenendo il colore sorgente originale
  ManaDice rerollDie(ManaDice originalDie) {
    return rollSpecific([originalDie.sourceColor]).first;
  }
  
  // Metodo generico di fallback
  List<ManaDice> roll(int count) {
    List<Elemento> randomSources = [];
    List<Elemento> all = [Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo];
    for(int i=0; i<count; i++) {
      randomSources.add(all[_rng.nextInt(all.length)]);
    }
    return rollSpecific(randomSources);
  }
}