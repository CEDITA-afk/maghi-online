import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/map_model.dart';
import '../../models/entities.dart';
import '../../models/enums.dart';

class InteractiveMapView extends StatefulWidget {
  final MapScenario scenario;
  final Map<Elemento, Mago> heroes;
  final BossOverlord boss;
  final List<Minion> minions;
  final List<MapObject> customObjects;
  final Map<String, Point> savedPositions;

  final Function(String id, int x, int y) onPositionChanged;
  final Function(Minion minion) onSpawnMinion;
  final Function(MapObject obj) onSpawnObject;
  final Function(Minion minion) onMinionTap;

  const InteractiveMapView({
    super.key,
    required this.scenario,
    required this.heroes,
    required this.boss,
    required this.minions,
    required this.customObjects,
    required this.savedPositions,
    required this.onPositionChanged,
    required this.onSpawnMinion,
    required this.onSpawnObject,
    required this.onMinionTap,
  });

  @override
  State<InteractiveMapView> createState() => _InteractiveMapViewState();
}

class _InteractiveMapViewState extends State<InteractiveMapView> {
  final TransformationController _transformController = TransformationController();
  final Map<dynamic, Offset?> _dragOffsets = {};
  
  bool _isLockedMode = true;
  bool _isRulerMode = false;
  Offset? _rulerStart;
  Offset? _rulerEnd;

  final double _cellSize = 60.0;

  @override
  Widget build(BuildContext context) {
    double mapWidth = widget.scenario.cols * _cellSize;
    double mapHeight = widget.scenario.rows * _cellSize;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "ruler",
            mini: true,
            backgroundColor: _isRulerMode ? Colors.yellow : Colors.grey.shade800,
            onPressed: () => setState(() { _isRulerMode = !_isRulerMode; _rulerStart = _rulerEnd = null; }),
            child: const Icon(Icons.straighten),
          ),
          const SizedBox(height: 12),
          PopupMenuButton<String>(
            icon: Container(
              decoration: BoxDecoration(color: Colors.purple.shade900, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            onSelected: (value) {
              if (value == 'minion') _showMinionSpawnDialog();
              if (value == 'object') _showObjectSpawnDialog();
              // NUOVO GESTORE PER LE ETICHETTE TESTUALI
              if (value == 'text') _showTextSpawnDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'minion', child: ListTile(leading: Icon(Icons.adb), title: Text("Minion"))),
              const PopupMenuItem(value: 'object', child: ListTile(leading: Icon(Icons.view_quilt), title: Text("Elemento Scenico"))),
              // NUOVA VOCE NEL MENU
              const PopupMenuItem(value: 'text', child: ListTile(leading: Icon(Icons.text_fields), title: Text("Etichetta Testuale"))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.1, maxScale: 4.0,
              panEnabled: !_isRulerMode,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: SizedBox(
                  width: mapWidth, height: mapHeight,
                  child: GestureDetector(
                    onTapDown: _isRulerMode ? (d) => setState(() => _rulerStart = _rulerEnd = d.localPosition) : null,
                    onPanUpdate: _isRulerMode ? (d) => setState(() => _rulerEnd = d.localPosition) : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildMapBase(),
                        if (_isRulerMode && _rulerStart != null && _rulerEnd != null)
                          CustomPaint(painter: RulerPainter(start: _rulerStart!, end: _rulerEnd!, cellSize: _cellSize)),

                        ...widget.scenario.initialObjects.map((o) => _buildToken(o.id, _buildMapObjectWidget(o), _isLockedMode && o.isLocked)),
                        ...widget.customObjects.map((o) => _buildToken(o.id, _buildMapObjectWidget(o), _isLockedMode)),
                        ...widget.minions.map((m) => _buildToken(m.id, _buildMinionWidget(m), false, onTap: () => widget.onMinionTap(m))),
                        _buildToken(widget.boss.id, _buildEntityWidget(widget.boss), false),
                        ...widget.heroes.values.map((h) => _buildToken(h.id, _buildEntityWidget(h), false)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToken(String id, Widget child, bool isLocked, {VoidCallback? onTap}) {
    Point gridPos = widget.savedPositions[id] ?? Point(0, 0);
    Offset pos = _dragOffsets[id] ?? Offset(gridPos.x * _cellSize, gridPos.y * _cellSize);

    return Positioned(
      left: pos.dx, top: pos.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: isLocked ? null : (d) => setState(() => _dragOffsets[id] = pos),
        onPanUpdate: isLocked ? null : (d) {
          double scale = _transformController.value.getMaxScaleOnAxis();
          setState(() => _dragOffsets[id] = _dragOffsets[id]! + (d.delta / scale));
        },
        onPanEnd: isLocked ? null : (d) {
          setState(() {
            Offset finalPos = _dragOffsets[id]!;
            _dragOffsets[id] = null;
            int nx = (finalPos.dx / _cellSize).round().clamp(0, widget.scenario.cols - 1);
            int ny = (finalPos.dy / _cellSize).round().clamp(0, widget.scenario.rows - 1);
            widget.onPositionChanged(id, nx, ny);
          });
        },
        child: child,
      ),
    );
  }

  void _showMinionSpawnDialog() {
    widget.onSpawnMinion(Minion(id: "", nome: "", hp: 5, maxHp: 5, nomeTipo: "Scherano", numeroProgressivo: 0));
  }

  void _showObjectSpawnDialog() {
    MapObjectType type = MapObjectType.wall;
    Color selectedColor = Colors.brown;
    int len = 2;
    bool vert = false;

    final List<Color> palette = [
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.orange.shade900,
      Colors.green.shade900,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setSt) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Nuovo Elemento", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<MapObjectType>(
            dropdownColor: Colors.grey.shade900,
            style: const TextStyle(color: Colors.white),
            value: type, 
            items: [MapObjectType.wall, MapObjectType.obstacle].map((e)=>DropdownMenuItem(value:e, child:Text(e.name))).toList(), 
            onChanged: (v)=>setSt(()=>type=v!)
          ),
          const SizedBox(height: 10),
          const Text("Colore:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: palette.map((c) => GestureDetector(
              onTap: () => setSt(() => selectedColor = c),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: selectedColor == c ? Colors.white : Colors.transparent, width: 2)
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 15),
          Text("Lunghezza: $len", style: const TextStyle(color: Colors.white)),
          Slider(activeColor: Colors.purple, value: len.toDouble(), min: 1, max: 6, divisions: 5, onChanged: (v)=>setSt(()=>len=v.round())),
          SwitchListTile(
            title: const Text("Verticale", style: TextStyle(color: Colors.white)), 
            value: vert, 
            onChanged: (v)=>setSt(()=>vert=v)
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          ElevatedButton(onPressed: () {
            widget.onSpawnObject(MapObject(
              id: "obj_${DateTime.now().millisecondsSinceEpoch}", 
              type: type, x: 5, y: 5, 
              color: selectedColor, 
              length: len, 
              isVertical: vert
            ));
            Navigator.pop(ctx);
          }, child: const Text("PIAZZA"))
        ],
      )),
    );
  }

  // NUOVO: Dialog per generare l'etichetta di testo in mappa
  void _showTextSpawnDialog() {
    TextEditingController txtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Inserisci Testo", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: txtCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Es: Ancora Fuoco (5 HP)", 
            hintStyle: TextStyle(color: Colors.white38)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          ElevatedButton(onPressed: () {
            if (txtCtrl.text.isNotEmpty) {
              widget.onSpawnObject(MapObject(
                id: "txt_${DateTime.now().millisecondsSinceEpoch}", 
                type: MapObjectType.textLabel, // Il nuovo tipo inserito nel modello
                x: 4, y: 4, 
                text: txtCtrl.text, // L'assegnazione della stringa
                color: Colors.transparent, 
              ));
            }
            Navigator.pop(ctx);
          }, child: const Text("PIAZZA"))
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(height: 40, color: Colors.grey.shade900, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(icon: Icon(_isLockedMode ? Icons.lock : Icons.lock_open, color: _isLockedMode ? Colors.red : Colors.green, size: 20), onPressed: () => setState(() => _isLockedMode = !_isLockedMode)),
      const Text("MAPPA SANDBOX", style: TextStyle(color: Colors.white, fontSize: 11)),
      const SizedBox(width: 40),
    ]));
  }

  Widget _buildMapBase() {
    return Positioned.fill(child: Stack(fit: StackFit.expand, children: [
      if (widget.scenario.backgroundAsset.isNotEmpty) Image.asset(widget.scenario.backgroundAsset, fit: BoxFit.fill, errorBuilder: (c,e,s)=>Container(color: Colors.grey.shade800)) else Container(color: Colors.grey.shade800),
      CustomPaint(painter: GridPainter(rows: widget.scenario.rows, cols: widget.scenario.cols, cellSize: _cellSize)),
    ]));
  }

  Widget _buildMinionWidget(Minion m) {
    return Container(width: _cellSize, height: _cellSize, child: Stack(alignment: Alignment.center, children: [
      Container(margin: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.brown.shade900, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Center(child: Text("${m.hp}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
      Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: Text("${m.numeroProgressivo}", style: const TextStyle(color: Colors.white, fontSize: 8)))),
    ]));
  }

  Widget _buildEntityWidget(GameEntity entity) {
    Color c = Colors.purple; 
    
    if (entity is Mago) {
      switch (entity.elemento) {
        case Elemento.rosso: c = Colors.red.shade700; break;
        case Elemento.blu: c = Colors.blue.shade700; break;
        case Elemento.verde: c = Colors.green.shade700; break;
        case Elemento.giallo: c = Colors.orange.shade700; break;
        default: c = Colors.blue;
      }
    }

    return Container(
      width: _cellSize, height: _cellSize, 
      decoration: BoxDecoration(
        color: c, 
        shape: BoxShape.circle, 
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)]
      ), 
      child: Center(
        child: Text(
          entity.nome.substring(0,1), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        )
      )
    );
  }

  Widget _buildMapObjectWidget(MapObject obj) {
    // NUOVO: RENDERIZZAZIONE ETICHETTA TESTUALE
    if (obj.type == MapObjectType.textLabel) {
      return Container(
        width: _cellSize * 2, // Leggermente più largo della casella per contenere testo
        height: _cellSize * 0.8,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black87, 
          border: Border.all(color: Colors.yellowAccent, width: 1.5), 
          borderRadius: BorderRadius.circular(4)
        ),
        child: Text(
          obj.text ?? "Testo", 
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), 
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // ALTRIMENTI COMPORTAMENTO STANDARD (Muri/Ostacoli)
    double w = obj.isVertical ? _cellSize * 0.8 : _cellSize * obj.length;
    double h = obj.isVertical ? _cellSize * obj.length : _cellSize * 0.8;
    return Container(
      width: w, height: h, 
      decoration: BoxDecoration(
        color: obj.color.withOpacity(0.7), 
        border: Border.all(color: Colors.white30), 
        borderRadius: BorderRadius.circular(obj.type == MapObjectType.obstacle ? 40 : 4)
      )
    );
  }
}

class GridPainter extends CustomPainter {
  final int rows, cols; final double cellSize;
  GridPainter({required this.rows, required this.cols, required this.cellSize});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke;
    for (int c = 0; c <= cols; c++) canvas.drawLine(Offset(c * cellSize, 0), Offset(c * cellSize, size.height), paint);
    for (int r = 0; r <= rows; r++) canvas.drawLine(Offset(0, r * cellSize), Offset(size.width, r * cellSize), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class RulerPainter extends CustomPainter {
  final Offset start, end; final double cellSize;
  RulerPainter({required this.start, required this.end, required this.cellSize});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow..strokeWidth = 2;
    canvas.drawLine(start, end, paint);
    double dist = math.sqrt(math.pow(end.dx - start.dx, 2) + math.pow(end.dy - start.dy, 2)) / cellSize;
    TextPainter(text: TextSpan(text: " ${dist.toStringAsFixed(1)} m ", style: const TextStyle(backgroundColor: Colors.black, color: Colors.yellow, fontSize: 14)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset((start.dx+end.dx)/2, (start.dy+end.dy)/2));
  }
  @override bool shouldRepaint(covariant RulerPainter old) => true;
}