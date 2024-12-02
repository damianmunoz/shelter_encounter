import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;
import 'player.dart';
import 'collision_block.dart';
import 'package:flutter/painting.dart';
import '../components/player.dart';
import '../components/projectile.dart';

enum EnemyState {
  idle,
  walking,
  attacking,
  dying
}

class Enemy extends SpriteAnimationComponent with HasGameRef, CollisionCallbacks {
  static const double _speed = 60.0;
  static const double _attackRange = 15.0;
  static const double _detectionRange = 250.0;
  static const double _stateChangeDelay = 0.5;
  static const double attackDuration = 0.8;
  
  static const double displayWidth = 96.0;
  static const double displayHeight = 96.0;
  static const double collisionWidth = 24.0;
  static const double collisionHeight = 24.0;
  late final RectangleHitbox movementHitbox;

  final Player target;
  int health = 5;
  bool isDying = false;
  bool isAttacking = false;
  double deathTimer = 0;
  double attackTimer = 0;
  double _stateTimer = 0;
  Vector2 moveDirection = Vector2.zero();
  Vector2 _lastPosition = Vector2.zero();
  bool _hasCollision = false;
  bool _isAvoidingObstacle = false;
  double _avoidanceTimer = 0;


  EnemyState _currentState = EnemyState.idle;
  late final Map<EnemyState, SpriteAnimation> _animations;
  
  Enemy({
    required Vector2 position,
    required this.target,
  }) : super(
    position: position,
    size: Vector2(displayWidth, displayHeight),
    anchor: Anchor.center,
  ) {
    debugMode = true;
    debugColor = const Color.fromARGB(255, 255, 0, 0);
    
    // Initialize movementHitbox
    movementHitbox = RectangleHitbox(
      size: Vector2(32, 32),
      position: Vector2(
        (displayWidth - 32) / 2,
        (displayHeight - 32) / 2,
      ),
      collisionType: CollisionType.active,
    )..debugColor = const Color.fromARGB(255, 255, 0, 0);
    add(movementHitbox);  // Now it's non-nullable
    
    add(RectangleHitbox(
      size: Vector2(48, 48),
      position: Vector2(
        (displayWidth - 48) / 2,
        (displayHeight - 48) / 2,
      ),
      isSolid: false,
      collisionType: CollisionType.passive,
    )..debugColor = const Color.fromARGB(255, 0, 255, 0));
  }

  @override
  Future<void> onLoad() async {
    _lastPosition = position.clone();
    
    try {
      _animations = {
        EnemyState.idle: await _loadAnimation(
          imagePath: 'enemy_idle_sprite.png',
          frameCount: 8,
          stepTime: 0.15,
          srcSize: Vector2(96, 96),
        ),
        EnemyState.walking: await _loadAnimation(
          imagePath: 'enemy_walk_sprite.png',
          frameCount: 8,
          stepTime: 0.15,
          srcSize: Vector2(96, 96),
        ),
        EnemyState.attacking: await _loadAnimation(
          imagePath: 'enemy_attack_sprite.png',
          frameCount: 8,
          stepTime: 0.12,
          srcSize: Vector2(96, 96),
        ),
        EnemyState.dying: await _loadAnimation(
          imagePath: 'enemy_death_sprite.png',
          frameCount: 12,
          stepTime: 0.1,
          srcSize: Vector2(96, 96),
        ),
      };
      
      animation = _animations[EnemyState.idle];
    } catch (e) {
      print('Error loading enemy animations: $e');
    }
  }

  Future<SpriteAnimation> _loadAnimation({
    required String imagePath,
    required int frameCount,
    required double stepTime,
    required Vector2 srcSize,
  }) async {
    try {
      final spriteImage = await gameRef.images.load(imagePath);
      final spriteSheet = SpriteSheet(
        image: spriteImage,
        srcSize: srcSize,
      );
      return spriteSheet.createAnimation(
        row: 0,
        stepTime: stepTime,
        to: frameCount,
        loop: true,
      );
    } catch (e) {
      print('Error loading animation $imagePath: $e');
      rethrow;
    }
  }

  void _updateState(double distance, double dt) {
    _stateTimer -= dt;
    
    if (isAttacking) {
      attackTimer += dt;
      if (attackTimer >= attackDuration) {
        isAttacking = false;
        attackTimer = 0;
        scale = Vector2.all(1.0);
      }
    }
    
    if (_stateTimer <= 0) {
      final newState = _determineState(distance);
      if (newState != _currentState) {
        _currentState = newState;
        animation = _animations[_currentState];
        
        if (_currentState == EnemyState.attacking) {
          isAttacking = true;
          attackTimer = 0;
          scale = Vector2(0.444, 1.0);
        }
        
        _stateTimer = _stateChangeDelay;
      }
    }
  }

  EnemyState _determineState(double distance) {
    if (isDying || health <= 0) return EnemyState.dying;
    if (isAttacking) return EnemyState.attacking;
    if (distance < _attackRange && !isAttacking) return EnemyState.attacking;
    if (distance < _detectionRange) return EnemyState.walking;
    return EnemyState.idle;
  }

  void _handleMovement(Vector2 toPlayer, double dt) {
    if (_currentState != EnemyState.walking || isAttacking) return;

    if (_isAvoidingObstacle) {
      _avoidanceTimer -= dt;
      if (_avoidanceTimer <= 0) {
        _isAvoidingObstacle = false;
      }
    }

    if (_hasCollision || _isAvoidingObstacle) {
      if (toPlayer.x.abs() > toPlayer.y.abs()) {
        moveDirection = Vector2(0, toPlayer.y.sign);
        position.add(moveDirection * _speed * dt);
        
        if (_hasCollision) {
          moveDirection = Vector2(toPlayer.x.sign, 0);
          position = _lastPosition;
          position.add(moveDirection * _speed * dt);
        }
      } else {
        moveDirection = Vector2(toPlayer.x.sign, 0);
        position.add(moveDirection * _speed * dt);
        
        if (_hasCollision) {
          moveDirection = Vector2(0, toPlayer.y.sign);
          position = _lastPosition;
          position.add(moveDirection * _speed * dt);
        }
      }
    } else {
      moveDirection = toPlayer.normalized();
      position.add(moveDirection * _speed * dt);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_currentState == EnemyState.dying) {
      deathTimer += dt;
      if (deathTimer >= 1.2) {
        removeFromParent();
      }
      return;
    }

    _lastPosition = position.clone();
    
    // Get player's real position - adjusting for your player's hitbox
    Vector2 playerPosition = target.position.clone();
    // Add offset to get to player's center considering the hitbox
    playerPosition.add(Vector2(
      target.size.x * 0.5 + 45,  // Half the player width plus hitbox offset
      target.size.y * 0.5 + 50   // Half the player height plus hitbox offset
    ));

    // Get enemy's center position
    Vector2 enemyPosition = position.clone();
    // Add offset to get to enemy's center
    enemyPosition.add(Vector2(
      movementHitbox.position.x + movementHitbox.size.x * 0.5,
      movementHitbox.position.y + movementHitbox.size.y * 0.5
    ));
    
    // Calculate direction and distance from centers
    final toPlayer = playerPosition - enemyPosition;
    final distance = toPlayer.length;
    
    // Update orientation
    if (toPlayer.x < 0 && !isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    } else if (toPlayer.x > 0 && isFlippedHorizontally) {
      flipHorizontallyAroundCenter();
    }
    
    _updateState(distance, dt);

    if (!isAttacking && _currentState == EnemyState.walking) {
      if (!_hasCollision) {
        moveDirection = toPlayer.normalized();
        position.add(moveDirection * _speed * dt);
      } else {
        position.add(moveDirection * _speed * dt);
      }
    }
    
    _hasCollision = false;
  }

  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CollisionBlock) {
      position = _lastPosition;
      _hasCollision = true;
      
      Vector2 playerPosition = target.position.clone();
      playerPosition.add(Vector2(
        target.size.x * 0.5 + 45,
        target.size.y * 0.5 + 50
      ));

      Vector2 enemyPosition = position.clone();
      enemyPosition.add(Vector2(
        movementHitbox.position.x + movementHitbox.size.x * 0.5,
        movementHitbox.position.y + movementHitbox.size.y * 0.5
      ));
    
      final toPlayer = playerPosition - enemyPosition;
      
      if (toPlayer.x.abs() > toPlayer.y.abs()) {
        moveDirection = Vector2(0, toPlayer.y.sign);
      } else {
        moveDirection = Vector2(toPlayer.x.sign, 0);
      }
    } else if (other is Player) {
      position = _lastPosition;
      _hasCollision = true;
    } else if (other is Projectile) {
      takeHit();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

    @override
    void onCollisionEnd(PositionComponent other) {
      if (other is CollisionBlock) {
        _hasCollision = false;
      }
      super.onCollisionEnd(other);
    }


    void takeHit() {
      health--;
      if (health <= 0 && _currentState != EnemyState.dying) {
        isDying = true;
        _updateState(0, 0);
      }
    } 
}
