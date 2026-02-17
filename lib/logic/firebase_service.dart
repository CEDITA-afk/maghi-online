import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String sessionId; 

  FirebaseService(this.sessionId);

  Stream<DocumentSnapshot> get gameStream => 
      _db.collection('sessions').doc(sessionId).snapshots();

  // Aggiorna posizioni in modo atomico
  Future<void> updatePosition(String id, int x, int y) async {
    await _db.collection('sessions').doc(sessionId).set({
      'positions': { id: {'x': x, 'y': y} }
    }, SetOptions(merge: true));
  }

  // Sincronizza lo stato completo (HP, Dadi, Turni)
  Future<void> updateFullState(Map<String, dynamic> data) async {
    await _db.collection('sessions').doc(sessionId).set(data, SetOptions(merge: true));
  }

  // Elimina la sessione (opzionale per pulizia)
  Future<void> deleteSession() async {
    await _db.collection('sessions').doc(sessionId).delete();
  }
}