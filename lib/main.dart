import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:twenty_forty_eight/tile.dart';
import 'package:uuid/uuid.dart';

void main() async {
  // 1) Activez les bindings pour les appels asynchrones Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2) Chargez vos assets dans le cache audio
  await FlameAudio.audioCache.loadAll([
    'laser.mp3',
    'victory.wav',
    'laugh.wav',
  ]);

  runApp(const MyApp());
}

Color green = const Color(0xff39FF14);
Color boardBg = Color.fromRGBO(4, 38, 2, 1);
Color black = Colors.black;
Color white = Colors.white;
String font = 'Architekt';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

double px = 18, py = 32, bp = 12, br = 4, step = 0.8;

enum Game { win, lost }

class _MyHomePageState extends State<MyHomePage> {
  int score = 0, best = 0;
  List<TileData> tilesData = [];
  bool won = false, lost = false;

  @override
  void initState() {
    super.initState();
    newGame();
  }

  List<List<int>> freeSlots() {
    // Generate all combinations
    List<List<int>> combinations = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        combinations.add([i, j]);
      }
    }

    for (final d in tilesData) {
      combinations.removeWhere((t) => d.x == t[0] && d.y == t[1]);
    }

    return combinations;
  }

  void newGame() {
    setState(() {
      won = false;
      lost = false;
      tilesData = [
        // TileData(Uuid().v4(), 0, 0, 1024),
        // TileData(Uuid().v4(), 0, 1, 1024),
      ];
      score = 0;
      insertNumber();
      insertNumber();
      insertNumber();
    });
  }

  bool insertNumber() {
    List<List<int>> slots = freeSlots();
    if (slots.isNotEmpty) {
      List<int> pos = slots[Random().nextInt(slots.length)];
      int val = Random().nextBool() ? 2 : 4;
      final id = Uuid().v4();
      tilesData.add(TileData(id, pos[0], pos[1], val));
      return true;
    } else {
      return false;
    }
  }

  bool canMove(SwipeDirection direction) {
    for (final tile in tilesData) {
      // Case cible
      int targetX =
          tile.x +
          (direction == SwipeDirection.right
              ? 1
              : direction == SwipeDirection.left
              ? -1
              : 0);
      int targetY =
          tile.y +
          (direction == SwipeDirection.down
              ? 1
              : direction == SwipeDirection.up
              ? -1
              : 0);

      // Continuer si mouvement hors plateau
      if (targetX < 0 || targetX > 3 || targetY < 0 || targetY > 3) {
        continue;
      }

      // Vérification case vide
      bool emptyTarget = tilesData.every(
        (t) => t.x != targetX || t.y != targetY,
      );
      if (emptyTarget) return true;

      // Possibilité de fusion
      final neighbor = tilesData.firstWhereOrNull(
        (t) => t.x == targetX && t.y == targetY,
      );
      if (neighbor != null && neighbor.val == tile.val) {
        return true;
      }
    }
    return false;
  }

  void moveTiles(SwipeDirection direction) async {
    // Réinitialiser les flags de fusion pour le prochain tour
    for (var t in tilesData) {
      t.merged = false;
    }

    // Trier par ordre contraire au mouvement
    tilesData.sort((a, b) {
      if (direction == SwipeDirection.right) return b.x.compareTo(a.x);
      if (direction == SwipeDirection.left) return a.x.compareTo(b.x);
      if (direction == SwipeDirection.down) return b.y.compareTo(a.y);
      return a.y.compareTo(b.y);
    });

    // Déplacement de chaque tile
    bool merged = false;
    for (var d in List<TileData>.from(tilesData)) {
      while (true) {
        // Case cible
        int nextX =
            d.x +
            (direction == SwipeDirection.right
                ? 1
                : direction == SwipeDirection.left
                ? -1
                : 0);
        int nextY =
            d.y +
            (direction == SwipeDirection.down
                ? 1
                : direction == SwipeDirection.up
                ? -1
                : 0);

        // Blocage déplacement hors plateau
        if (nextX < 0 || nextX > 3 || nextY < 0 || nextY > 3) break;

        // Identification du voisin
        final neighbor = tilesData.firstWhereOrNull(
          (n) => n.x == nextX && n.y == nextY,
        );

        if (neighbor == null) {
          d.x = nextX;
          d.y = nextY;
        } else if (neighbor.val == d.val && !neighbor.merged && !d.merged) {
          neighbor.val *= 2;
          neighbor.merged = true;
          tilesData.removeWhere((a) => a.id == d.id);
          score += neighbor.val;
          merged = true;
          if (score > best) best = score;
          break;
        } else {
          break;
        }
      }
    }

    if (merged) await FlameAudio.play('laser.mp3');

    if (tilesData.any((t) => t.val == 2048)) {
      won = true;
      FlameAudio.play('victory.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = MediaQuery.of(context).size.width - 2 * px;
    double innerSize = boardSize - 2 * bp;
    double tileSize = (innerSize - 3 * bp) / 4;
    TextStyle gameOverStyle(Game status) => TextStyle(
      fontFamily: font,
      fontSize: 20,
      letterSpacing: 0.7,
      color: status == Game.win ? green : Colors.red,
    );
    TextButton newGameButton = TextButton(
      onPressed: newGame,
      style: TextButton.styleFrom(
        backgroundColor: green,
        padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text('New Game', style: TextStyle(color: black, fontFamily: font)),
    );

    return Scaffold(
      backgroundColor: black,
      body: Padding(
        padding: EdgeInsets.fromLTRB(px, py * 3, px, py),
        child: Center(
          child: Stack(
            children: [
              // Game
              Column(
                spacing: 24,
                children: [
                  // App name and scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '2048',
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: FontWeight.w300,
                          fontSize: 56,
                          color: green,
                        ),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          NumBox(title: 'Score', val: score),
                          NumBox(title: 'Best', val: best),
                        ],
                      ),
                    ],
                  ),

                  // Instructions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Join the numbers and get to the ',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: '2048 tile!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: font,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      newGameButton,
                    ],
                  ),

                  // Game board
                  Stack(
                    children: [
                      Container(
                        width: boardSize,
                        height: boardSize,
                        padding: EdgeInsets.all(bp),
                        decoration: BoxDecoration(
                          color: boardBg,
                          borderRadius: BorderRadius.circular(br),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (int i = 0; i < 4; i++)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int j = 0; j < 4; j++)
                                    TilePlace(tileSize),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Tiles
                      SwipeDetector(
                        onSwipe: (direction, _) {
                          if (!canMove(direction)) return;

                          // Déplacement
                          setState(() {
                            moveTiles(direction);
                          });

                          Future.delayed(const Duration(milliseconds: 400), () {
                            setState(() {
                              insertNumber();
                              bool moveOK =
                                  canMove(SwipeDirection.up) ||
                                  canMove(SwipeDirection.down) ||
                                  canMove(SwipeDirection.left) ||
                                  canMove(SwipeDirection.right);

                              if (!moveOK) {
                                lost = true;
                                FlameAudio.play('laugh.wav');
                              }
                            });
                          });
                        },
                        child: Container(
                          width: boardSize,
                          height: boardSize,
                          padding: EdgeInsets.all(bp),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(br),
                          ),
                          child: Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              for (final t in tilesData)
                                AnimatedPositioned(
                                  key: ValueKey(t.id),
                                  duration: Duration(milliseconds: 400),
                                  top: posCalc(t.y, tileSize),
                                  left: posCalc(t.x, tileSize),
                                  child: Tile(
                                    id: t.id,
                                    x: t.x,
                                    y: t.y,
                                    val: t.val,
                                    tileSize: tileSize,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Win screen
              Visibility(
                visible: won,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('🎉🎉🎉', style: gameOverStyle(Game.win)),
                      Text('Congratulations', style: gameOverStyle(Game.win)),
                      Text('You won !', style: gameOverStyle(Game.win)),
                      Text('Score: $score', style: gameOverStyle(Game.win)),
                      Text('Best score: $best', style: gameOverStyle(Game.win)),
                      newGameButton,
                    ],
                  ),
                ),
              ),

              // Lose screen
              Visibility(
                visible: lost,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('😒😫', style: gameOverStyle(Game.lost)),
                      Text(
                        'Tu es éclaté frèèèère',
                        style: gameOverStyle(Game.lost),
                      ),
                      Text(
                        'Non mais regarde moi ça',
                        style: gameOverStyle(Game.lost),
                      ),
                      Text('😂😂😂', style: gameOverStyle(Game.lost)),
                      Text('Score: $score', style: gameOverStyle(Game.lost)),
                      Text(
                        'Best score: $best',
                        style: gameOverStyle(Game.lost),
                      ),
                      newGameButton,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NumBox extends StatelessWidget {
  final String title;
  final int val;

  const NumBox({required this.title, required this.val, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: green),
        borderRadius: BorderRadius.circular(4),
        color: black,
      ),
      child: Column(
        children: [
          Text(
            'Score',
            style: TextStyle(
              color: white,
              letterSpacing: 1,
              fontFamily: font,
              fontSize: 10,
            ),
          ),
          Text(
            val.toString(),
            style: TextStyle(
              color: white,
              fontFamily: font,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class TilePlace extends StatelessWidget {
  final double tileSize;

  const TilePlace(this.tileSize, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(br),
      ),
    );
  }
}

double posCalc(int i, double tileSize) {
  return i * (tileSize + bp);
}
