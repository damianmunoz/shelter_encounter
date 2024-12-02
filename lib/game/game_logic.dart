import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
import '../components/player.dart';
import '../components/enemy.dart';
import '../components/collision_block.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class GameLogic extends FlameGame with HasCollisionDetection {
  JoystickComponent? joystick;
  ButtonComponent? shootButton;
  late final Player player;
  late final World gameWorld;
  late final CameraComponent gameCamera;
  static const double movementSpeed = 100.0;
  late ButtonComponent respawnButton;
  bool isGameOver = false;

  
  
  final List<Vector2> enemySpawnPoints = [
   Vector2(32 * 14, 32 * 11),
  ];

  GameLogic() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    gameWorld = World();
    gameCamera = CameraComponent(world: gameWorld);
  }

  Future<void> spawnEnemy() async {
    final random = math.Random();
    final spawnPoint = enemySpawnPoints[random.nextInt(enemySpawnPoints.length)];
    
    final enemy = Enemy(
      position: spawnPoint,
      target: player,
    );
    
    await gameWorld.add(enemy);
  }

  @override
  Future<void> onLoad() async {
    // Create game layer
    final gameLayer = Component()..priority = 1;
    await add(gameLayer);
    await gameLayer.addAll([gameWorld, gameCamera]);

    // Load map in game layer
    final map = await TiledComponent.load('indoor_level.tmx', Vector2.all(32));
    await gameWorld.add(map);

    // Process collision layers
    final wallsLayer = map.tileMap.getLayer<TileLayer>('Walls');
    final furnitureLayer = map.tileMap.getLayer<TileLayer>('furniture');

    if (wallsLayer != null) {
      await _createCollisionsForLayer(wallsLayer);
    }
    if (furnitureLayer != null) {
      await _createCollisionsForLayer(furnitureLayer);
    }

    // Add player
    player = Player();
    player.position = Vector2(32 * 9, 32 * 28);
    await gameWorld.add(player);

    // Spawn initial enemies
    await spawnEnemy();

    // Create UI layer with higher priority
    final uiLayer = PositionComponent()..priority = 10;
    await add(uiLayer);

    // Create and add joystick to UI layer
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 15,
        paint: Paint()
          ..color = const Color(0xFF0000FF)
          ..style = PaintingStyle.fill,
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()
          ..color = const Color(0xFFAAAAAA)
          ..style = PaintingStyle.fill,
      ),
      position: Vector2(75, size.y - 75),
    );

    // Create and add shoot button to UI layer
    shootButton = ButtonComponent(
      button: CircleComponent(
        radius: 25,
        paint: Paint()
          ..color = const Color(0xFFFF0000).withOpacity(0.8)
          ..style = PaintingStyle.fill,
      ),
      position: Vector2(size.x - 100, size.y - 75),
      onPressed: () => player.shoot(),
    );

    await uiLayer.add(joystick!);
    await uiLayer.add(shootButton!);

    gameCamera.follow(player);

    // Set up periodic enemy spawning
    add(
      TimerComponent(
        period: 30,  // Spawn a new enemy every 15 seconds
        repeat: true,
        onTick: () async => await spawnEnemy(),
      ),
    );

    // Create respawn button
    respawnButton = ButtonComponent(
      button: RectangleComponent(
        size: Vector2(200, 50),
        paint: Paint()..color = const Color(0xFF4A4A4A),
      ),
      position: Vector2(size.x / 2 - 100, size.y / 2 + 50),
      onPressed: respawnPlayer,
    );

    final buttonText = TextComponent(
      text: 'Respawn',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 24,
        ),
      ),
    );
    buttonText.position = Vector2(70, 15);  // Position within button
    respawnButton.add(buttonText);

    // Don't add respawn button initially
    respawnButton.removeFromParent();

  }

  Future<void> _createCollisionsForLayer(TileLayer layer) async {
    final layerData = layer.data;
    if (layerData != null) {
      for (var y = 0; y < layer.height; y++) {
        for (var x = 0; x < layer.width; x++) {
          final index = y * layer.width + x;
          final tile = layerData[index];
          if (tile != 0) {
            final collisionBlock = CollisionBlock(
              position: Vector2(x * 32, y * 32),
              size: Vector2(32, 32),
            );
            await gameWorld.add(collisionBlock);
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameOver && joystick != null) {
      Vector2 delta = Vector2.zero();
      if (joystick!.direction != JoystickDirection.idle) {
        delta = joystick!.relativeDelta * movementSpeed * dt;
      }
      player.move(delta);
    }
  }

  void handlePlayerDeath() {
  isGameOver = true;
  
  // Get UI layer and add respawn button
  final uiLayer = children.whereType<PositionComponent>().firstWhere((component) => component.priority == 10);
  uiLayer.add(respawnButton);
  
  // Remove controls from UI layer
  joystick?.removeFromParent();
  shootButton?.removeFromParent();
}

  void respawnPlayer() {
    isGameOver = false;

    // Get UI layer
    final uiLayer = children.whereType<PositionComponent>().firstWhere((component) => component.priority == 10);
    
    // Reset player
    player.position = Vector2(32 * 9, 32 * 28);
    player.respawn();
    gameWorld.add(player);
    
    // Remove respawn button from UI layer
    respawnButton.removeFromParent();

    // Add controls back to UI layer
    uiLayer.add(joystick!);
    uiLayer.add(shootButton!);

    // Reset enemies
    gameWorld.children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    spawnEnemy();
  }


  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (joystick != null) {
      joystick!.position = Vector2(75, size.y - 75);
    }
    if (shootButton != null) {
      shootButton!.position = Vector2(size.x - 100, size.y - 75);
    }
  }

}