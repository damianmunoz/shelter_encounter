// lib/components/collision_block.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class CollisionBlock extends PositionComponent with CollisionCallbacks {
  CollisionBlock({required Vector2 position, required Vector2 size}) 
      : super(position: position, size: size) {
    add(RectangleHitbox(
      size: size,
      collisionType: CollisionType.passive,
    ));
  }
}