// lib/components/projectile.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';
import '../components/collision_block.dart';
import '../components/enemy.dart';  // Add this import

class Projectile extends CircleComponent with HasGameRef, CollisionCallbacks {
  final Vector2 direction;
  final double speed;

  Projectile({
    required Vector2 position,
    required this.direction,
    this.speed = 500,
  }) : super(
    radius: 2,
    position: position,
    paint: Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill,
  ) {
    add(CircleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(direction * speed * dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      other.takeHit();
      removeFromParent();
    } else if (other is CollisionBlock) {
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}