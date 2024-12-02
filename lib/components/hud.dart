// lib/components/hud.dart
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class Hud extends Component with HasGameRef {
  late final JoystickComponent joystick;
  
  @override
  Future<void> onLoad() async {
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: Paint()..color = const Color(0xFF0000FF)),
      background: CircleComponent(radius: 50, paint: Paint()..color = const Color(0xFFAAAAAA)),
      position: Vector2(75, gameRef.size.y - 75),
    );
    add(PositionComponent(children: [joystick], priority: 20));
  }

  Vector2? get joystickDelta => joystick.delta;
  bool get hasInput => joystick.direction != JoystickDirection.idle;
}