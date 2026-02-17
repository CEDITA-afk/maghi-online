import 'enums.dart';

class ManaDice {
  final String id; 
  final Elemento sourceColor;
  final Elemento effectiveElement; // Il risultato del lancio (calcolato dal Manager)
  final int faceValue; // 1-6
  
  bool isSelected = false; 
  bool isSpent = false;    

  ManaDice({
    required this.id,
    required this.sourceColor,
    required this.effectiveElement,
    required this.faceValue,
  });
  
  @override
  String toString() => 'Dice($sourceColor -> $effectiveElement [$faceValue])';

  // --- LOGICA DI UTILITÀ ---

  bool get isJolly => effectiveElement == Elemento.jolly;
  
  // Rimosso il getter "effectiveElement" che causava l'errore. 
  // Ora usa la variabile final dichiarata in alto.

  // Per compatibilità con UI: cosa posso pagare con questo dado?
  List<Elemento> get usableAs {
    if (isJolly) {
      return [Elemento.rosso, Elemento.blu, Elemento.verde, Elemento.giallo];
    }
    return [effectiveElement];
  }

  // Label per Debug/UI
  String get label {
    if (isJolly) return "★";
    return effectiveElement.name.substring(0, 1).toUpperCase();
  }
}