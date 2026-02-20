import 'package:flutter/material.dart';

// Definizione universale del punto per la griglia
class Point {
  final int x, y;
  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Point($x, $y)';
}

// AGGIUNTO IL TIPO "textLabel"
enum MapObjectType { wall, obstacle, hazard, objective, spawnPoint, custom, textLabel }

class MapObject {
  final String id;
  final MapObjectType type;
  int x;
  int y;
  bool isLocked;
  Color color;
  int length; 
  bool isVertical; 
  String? text; // NUOVO: Permette di dare un testo all'oggetto

  MapObject({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.isLocked = false,
    this.color = Colors.brown,
    this.length = 1,
    this.isVertical = false,
    this.text,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'x': x, 'y': y,
    'color': color.value, 'length': length, 'isVertical': isVertical,
    'text': text,
  };
}

class MapScenario {
  final String id;
  final String name;
  final String description;
  final String backgroundAsset; 
  final int rows;
  final int cols;
  final List<MapObject> initialObjects; 

  MapScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundAsset,
    required this.rows,
    required this.cols,
    required this.initialObjects,
  });
}