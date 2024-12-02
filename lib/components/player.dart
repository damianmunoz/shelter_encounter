import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/collisions.dart';
import '../components/collision_block.dart';
import '../components/projectile.dart';
import 'package:flutter/painting.dart';
import '../components/enemy.dart';
import '../game/game_logic.dart';

class Player extends SpriteAnimationComponent with HasGameRef, CollisionCallbacks {
  // Walking animations
  late SpriteAnimation walkDownAnimation;
  late SpriteAnimation leftDownAnimation;
  late SpriteAnimation leftUpAnimation;
  late SpriteAnimation walkUpAnimation;
  late SpriteAnimation rightUpAnimation;
  late SpriteAnimation rightDownAnimation;
  late SpriteAnimation walkRightAnimation;
  late SpriteAnimation walkLeftAnimation;
  
  // Idle animations
  late SpriteAnimation idleDownAnimation;
  late SpriteAnimation idleLeftDownAnimation;
  late SpriteAnimation idleLeftUpAnimation;
  late SpriteAnimation idleUpAnimation;
  late SpriteAnimation idleRightUpAnimation;
  late SpriteAnimation idleRightDownAnimation;
  late SpriteAnimation idleRightAnimation;
  late SpriteAnimation idleLeftAnimation;

  // Shooting animations
  late SpriteAnimation shootDownAnimation;
  late SpriteAnimation shootDownLeftAnimation;
  late SpriteAnimation shootLeftAnimation;
  late SpriteAnimation shootUpLeftAnimation;
  late SpriteAnimation shootUpAnimation;
  late SpriteAnimation shootUpRightAnimation;
  late SpriteAnimation shootRightAnimation;
  late SpriteAnimation shootDownRightAnimation;

  // Death animations
  late SpriteAnimation deathDownAnimation;
  late SpriteAnimation deathLeftDownAnimation;
  late SpriteAnimation deathLeftUpAnimation;
  late SpriteAnimation deathUpAnimation;
  late SpriteAnimation deathRightUpAnimation;
  late SpriteAnimation deathRightDownAnimation;
  late SpriteAnimation deathRightAnimation;
  late SpriteAnimation deathLeftAnimation;
  
  Vector2 _lastPosition = Vector2.zero();
  bool _hasCollision = false;
  SpriteAnimation? _lastAnimation;
  bool isShooting = false;
  double shootCooldown = 0.3;
  double currentCooldown = 0;
  double pushBackDistance = 5.0; 
  
  // Health and death properties
  static const int maxHealth = 4;
  int currentHealth = maxHealth;
  bool isDead = false;
  double deathTimer = 0;
  double respawnTimer = 0;
  static const double respawnDelay = 30.0;
  Vector2? _respawnPosition;
  
  Player() : super(size: Vector2(48, 64)) {
    debugMode = true;
    debugColor = const Color.fromARGB(255, 0, 255, 0);
    add(RectangleHitbox(
      size: Vector2(32, 48),
      position: Vector2(8, 8),
      collisionType: CollisionType.active,
    )..debugColor = const Color.fromARGB(255, 0, 255, 0));
  }

  @override
  Future<void> onLoad() async {
    _lastPosition = position.clone();
    
    final walkSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_walk_sprite.png'),
      srcSize: Vector2(48, 64),
    );
    
    final idleSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_idle_sprite.png'),
      srcSize: Vector2(48, 64),
    );

    final shootSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_shoot_sprite.png'),
      srcSize: Vector2(48, 64),
    );

    final deathSpriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_death_sprite.png'),
      srcSize: Vector2(48, 64),
    );
    
    // Walking animations
    walkDownAnimation = walkSpriteSheet.createAnimation(row: 0, stepTime: 0.08, to: 8);
    leftDownAnimation = walkSpriteSheet.createAnimation(row: 1, stepTime: 0.08, to: 8);
    leftUpAnimation = walkSpriteSheet.createAnimation(row: 2, stepTime: 0.08, to: 8);
    walkUpAnimation = walkSpriteSheet.createAnimation(row: 3, stepTime: 0.08, to: 8);
    rightUpAnimation = walkSpriteSheet.createAnimation(row: 4, stepTime: 0.08, to: 8);
    rightDownAnimation = walkSpriteSheet.createAnimation(row: 5, stepTime: 0.08, to: 8);
    walkRightAnimation = walkSpriteSheet.createAnimation(row: 5, stepTime: 0.08, to: 8);
    walkLeftAnimation = walkSpriteSheet.createAnimation(row: 1, stepTime: 0.08, to: 8);
    
    // Idle animations
    idleDownAnimation = idleSpriteSheet.createAnimation(row: 0, stepTime: 0.12, to: 8);
    idleLeftDownAnimation = idleSpriteSheet.createAnimation(row: 1, stepTime: 0.12, to: 8);
    idleLeftUpAnimation = idleSpriteSheet.createAnimation(row: 2, stepTime: 0.12, to: 8);
    idleUpAnimation = idleSpriteSheet.createAnimation(row: 3, stepTime: 0.12, to: 8);
    idleRightUpAnimation = idleSpriteSheet.createAnimation(row: 4, stepTime: 0.12, to: 8);
    idleRightDownAnimation = idleSpriteSheet.createAnimation(row: 5, stepTime: 0.12, to: 8);
    idleRightAnimation = idleSpriteSheet.createAnimation(row: 5, stepTime: 0.12, to: 8);  // Using rightDown for right
    idleLeftAnimation = idleSpriteSheet.createAnimation(row: 1, stepTime: 0.12, to: 8); 

    // Shooting animations - fixed to match the same pattern as movement
    shootDownAnimation = shootSpriteSheet.createAnimation(row: 0, stepTime: 0.08, to: 8);
    shootDownLeftAnimation = shootSpriteSheet.createAnimation(row: 1, stepTime: 0.08, to: 8);
    shootUpLeftAnimation = shootSpriteSheet.createAnimation(row: 2, stepTime: 0.08, to: 8);  // matches leftUp
    shootUpAnimation = shootSpriteSheet.createAnimation(row: 3, stepTime: 0.08, to: 8);
    shootUpRightAnimation = shootSpriteSheet.createAnimation(row: 4, stepTime: 0.08, to: 8);
    shootDownRightAnimation = shootSpriteSheet.createAnimation(row: 5, stepTime: 0.08, to: 8);
    shootRightAnimation = shootSpriteSheet.createAnimation(row: 6, stepTime: 0.08, to: 8);   // use downRight for right
    shootLeftAnimation = shootSpriteSheet.createAnimation(row: 7, stepTime: 0.08, to: 8);    // use downLeft for left
    
    // Death animations
    deathDownAnimation = deathSpriteSheet.createAnimation(row: 0, stepTime: 0.08, to: 8, loop: false);
    deathLeftDownAnimation = deathSpriteSheet.createAnimation(row: 1, stepTime: 0.08, to: 8, loop: false);
    deathLeftUpAnimation = deathSpriteSheet.createAnimation(row: 2, stepTime: 0.08, to: 8, loop: false);
    deathUpAnimation = deathSpriteSheet.createAnimation(row: 3, stepTime: 0.08, to: 8, loop: false);
    deathRightUpAnimation = deathSpriteSheet.createAnimation(row: 4, stepTime: 0.08, to: 8, loop: false);
    deathRightDownAnimation = deathSpriteSheet.createAnimation(row: 5, stepTime: 0.08, to: 8, loop: false);
    deathRightAnimation = deathSpriteSheet.createAnimation(row: 5, stepTime: 0.08, to: 8, loop: false);
    deathLeftAnimation = deathSpriteSheet.createAnimation(row: 1, stepTime: 0.08, to: 8, loop: false);
    
    animation = idleDownAnimation;
    _lastAnimation = idleDownAnimation;
    
    await super.onLoad();
  }

  void shoot() {
    if (currentCooldown <= 0 && !isShooting) {
      isShooting = true;
      currentCooldown = shootCooldown;

      Vector2 shootDirection = _getShootingDirection();
      _setShootingAnimation();

      final projectile = Projectile(
        position: position + Vector2(size.x / 2, size.y / 2),
        direction: shootDirection,
      );
      
      parent?.add(projectile);
    }
  }

  Vector2 _getShootingDirection() {
    if (_lastAnimation == walkDownAnimation || _lastAnimation == idleDownAnimation) {
      return Vector2(0, 1);
    } else if (_lastAnimation == walkUpAnimation || _lastAnimation == idleUpAnimation) {
      return Vector2(0, -1);
    } else if (_lastAnimation == walkLeftAnimation || _lastAnimation == idleLeftAnimation) {
      return Vector2(-1, 0);
    } else if (_lastAnimation == walkRightAnimation || _lastAnimation == idleRightAnimation) {
      return Vector2(1, 0);
    } else if (_lastAnimation == leftDownAnimation || _lastAnimation == idleLeftDownAnimation) {
      return Vector2(-0.707, 0.707);
    } else if (_lastAnimation == leftUpAnimation || _lastAnimation == idleLeftUpAnimation) {
      return Vector2(-0.707, -0.707);
    } else if (_lastAnimation == rightDownAnimation || _lastAnimation == idleRightDownAnimation) {
      return Vector2(0.707, 0.707);
    } else if (_lastAnimation == rightUpAnimation || _lastAnimation == idleRightUpAnimation) {
      return Vector2(0.707, -0.707);
    }
    return Vector2(0, 1);
  }

  void _setShootingAnimation() {
    // First check for cardinal directions
    if (_lastAnimation == walkRightAnimation || _lastAnimation == idleRightAnimation) {
      animation = shootRightAnimation;
    } else if (_lastAnimation == walkLeftAnimation || _lastAnimation == idleLeftAnimation) {
      animation = shootLeftAnimation;
    } else if (_lastAnimation == walkUpAnimation || _lastAnimation == idleUpAnimation) {
      animation = shootUpAnimation;
    } else if (_lastAnimation == walkDownAnimation || _lastAnimation == idleDownAnimation) {
      animation = shootDownAnimation;
    }
    // Then check diagonals
    else if (_lastAnimation == leftDownAnimation || _lastAnimation == idleLeftDownAnimation) {
      animation = shootDownLeftAnimation;
    } else if (_lastAnimation == leftUpAnimation || _lastAnimation == idleLeftUpAnimation) {
      animation = shootUpLeftAnimation;
    } else if (_lastAnimation == rightDownAnimation || _lastAnimation == idleRightDownAnimation) {
      animation = shootDownRightAnimation;
    } else if (_lastAnimation == rightUpAnimation || _lastAnimation == idleRightUpAnimation) {
      animation = shootUpRightAnimation;
    }
  }

void _setDeathAnimation() {
    if (_lastAnimation == walkRightAnimation || _lastAnimation == idleRightAnimation) {
      animation = deathRightAnimation;
    } else if (_lastAnimation == walkLeftAnimation || _lastAnimation == idleLeftAnimation) {
      animation = deathLeftAnimation;
    } else if (_lastAnimation == walkUpAnimation || _lastAnimation == idleUpAnimation) {
      animation = deathUpAnimation;
    } else if (_lastAnimation == walkDownAnimation || _lastAnimation == idleDownAnimation) {
      animation = deathDownAnimation;
    } else if (_lastAnimation == leftDownAnimation || _lastAnimation == idleLeftDownAnimation) {
      animation = deathLeftDownAnimation;
    } else if (_lastAnimation == leftUpAnimation || _lastAnimation == idleLeftUpAnimation) {
      animation = deathLeftUpAnimation;
    } else if (_lastAnimation == rightDownAnimation || _lastAnimation == idleRightDownAnimation) {
      animation = deathRightDownAnimation;
    } else if (_lastAnimation == rightUpAnimation || _lastAnimation == idleRightUpAnimation) {
      animation = deathRightUpAnimation;
    }
  }

  void move(Vector2 delta) {
    if (isDead) return;
    if (_hasCollision) return;
    if (isShooting) return;
    
    _lastPosition = position.clone();
    
    if (delta.x == 0 && delta.y == 0) {
      if (animation != idleDownAnimation && _lastAnimation == walkDownAnimation) {
        animation = idleDownAnimation;
      } else if (animation != idleLeftDownAnimation && _lastAnimation == leftDownAnimation) {
        animation = idleLeftDownAnimation;
      } else if (animation != idleLeftUpAnimation && _lastAnimation == leftUpAnimation) {
        animation = idleLeftUpAnimation;
      } else if (animation != idleUpAnimation && _lastAnimation == walkUpAnimation) {
        animation = idleUpAnimation;
      } else if (animation != idleRightUpAnimation && _lastAnimation == rightUpAnimation) {
        animation = idleRightUpAnimation;
      } else if (animation != idleRightDownAnimation && _lastAnimation == rightDownAnimation) {
        animation = idleRightDownAnimation;
      } else if (animation != idleRightAnimation && _lastAnimation == walkRightAnimation) {
        animation = idleRightAnimation;
      } else if (animation != idleLeftAnimation && _lastAnimation == walkLeftAnimation) {
        animation = idleLeftAnimation;
      }
    } else {
      final absX = delta.x.abs();
      final absY = delta.y.abs();
      
      if (absY < absX * 0.3) {
        if (delta.x > 0) {
          animation = walkRightAnimation;
          _lastAnimation = walkRightAnimation;
        } else {
          animation = walkLeftAnimation;
          _lastAnimation = walkLeftAnimation;
        }
      } else if (absX < absY * 0.3) {
        if (delta.y > 0) {
          animation = walkDownAnimation;
          _lastAnimation = walkDownAnimation;
        } else {
          animation = walkUpAnimation;
          _lastAnimation = walkUpAnimation;
        }
      } else {
        if (delta.x > 0) {
          if (delta.y > 0) {
            animation = rightDownAnimation;
            _lastAnimation = rightDownAnimation;
          } else {
            animation = rightUpAnimation;
            _lastAnimation = rightUpAnimation;
          }
        } else {
          if (delta.y > 0) {
            animation = leftDownAnimation;
            _lastAnimation = leftDownAnimation;
          } else {
            animation = leftUpAnimation;
            _lastAnimation = leftUpAnimation;
          }
        }
      }
    }
    
    position.add(delta);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      deathTimer += dt;
      if (deathTimer >= 0.8) {  // Length of death animation
        removeFromParent();  // Remove the player after death animation
      }
      return;
    }

    if (currentCooldown > 0) {
      currentCooldown -= dt;
    }
    if (isShooting && currentCooldown <= shootCooldown - 0.1) {
      isShooting = false;
      if (_lastAnimation != null) {
        animation = _lastAnimation;
      }
    }
  }

  void takeDamage() {
    if (isDead) return;
    
    currentHealth--;
    print('Player took damage. Health: $currentHealth'); // Debug print
    
    if (currentHealth <= 0) {
      die();
    }
  }

  void die() {
    isDead = true;
    deathTimer = 0;
    _setDeathAnimation();
    // Make sure to cast game to GameLogic
    if (game is GameLogic) {
      (game as GameLogic).handlePlayerDeath();
    }
  }

  void respawn() {
    isDead = false;
    currentHealth = maxHealth;
    deathTimer = 0;
    respawnTimer = 0;
    if (_respawnPosition != null) {
      position = _respawnPosition!.clone();
    }
    animation = idleDownAnimation;
    _lastAnimation = idleDownAnimation;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CollisionBlock) {
      position = _lastPosition;
      _hasCollision = true;
    } else if (other is Enemy && !isDead) {
      takeDamage();
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
}
