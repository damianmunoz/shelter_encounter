import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/game_logic.dart';

void main() {
  final game = GameLogic(); // Initialize the game
  runApp(GameWidget(game: game)); // Attach the game to the widget tree
}
