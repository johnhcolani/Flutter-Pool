import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MaterialApp(
    home: PoolGame(),
  ));
}

class PoolGame extends StatefulWidget {
  const PoolGame({super.key});

  @override
  _PoolGameState createState() => _PoolGameState();
}

class _PoolGameState extends State<PoolGame> {
  int score = 0; // Track the player's score
  Duration elapsedTime = Duration.zero; // Track elapsed time
  late final AudioPlayer audioPlayer;
  List<Ball> balls = [];
  Offset? cueStickPosition;
  Ball? selectedBall;
  final double tableFriction = 0.98; // Friction to slow down balls
  final double cushionDamping = 0.85; // Damping when balls hit the table edges
  final double collisionRestitution = 0.9; // Bounciness during collisions
  Timer? gameTimer; // Timer for game updates
  Timer? elapsedTimer; // Timer for tracking elapsed time

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _initializeGame(); // Initialize the game
    startElapsedTimer(); // Start the elapsed time timer
  }

  @override
  void dispose() {
    gameTimer?.cancel(); // Cancel the game timer
    elapsedTimer?.cancel(); // Cancel the elapsed time timer
    audioPlayer.dispose(); // Dispose the audio player
    super.dispose();
  }

  // Start the elapsed time timer
  void startElapsedTimer() {
    elapsedTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedTime += Duration(seconds: 1); // Increment elapsed time by 1 second
      });
    });
  }

  // Format the duration as HH:MM:SS
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Initialize the game by setting up the balls
  void _initializeGame() {
    balls.clear(); // Clear existing balls

    // Add white cue ball
    balls.add(Ball(
      number: 0,
      color: Colors.white,
      position: Offset(220, 600),
      velocity: Offset.zero,
      inPocket: false,
    ));

    // Rack colored balls in triangle formation
    final ballRadius = 15.0;
    final startX = 220.0;
    final startY = 200.0;
    final rowSpacing = ballRadius * 2;

    balls.addAll([
      Ball(number: 8, color: Colors.black, position: Offset(startX, startY), velocity: Offset.zero, inPocket: false),
      Ball(number: 2, color: Colors.blue, position: Offset(startX - ballRadius, startY + rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 3, color: Colors.red, position: Offset(startX + ballRadius, startY + rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 4, color: Colors.purple, position: Offset(startX - 2 * ballRadius, startY + 2 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 5, color: Colors.orange, position: Offset(startX, startY + 2 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 6, color: Colors.green, position: Offset(startX + 2 * ballRadius, startY + 2 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 7, color: Colors.brown, position: Offset(startX - 3 * ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 9, color: Colors.yellow.shade800, position: Offset(startX - ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 10, color: Colors.blue.shade800, position: Offset(startX + ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero, inPocket: false),
      Ball(number: 11, color: Colors.pink, position: Offset(startX + 3 * ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero, inPocket: false),
    ]);
  }

  // Update the game state (called every frame)
  void _updateGame() {
    setState(() {
      for (var ball in balls) {
        ball.updatePosition(tableFriction); // Update ball position
        _checkBoundaryCollision(ball); // Check for boundary collisions
        _checkPocketCollision(ball); // Check for pocket collisions
      }
      _checkBallCollisions(); // Check for ball collisions
    });
  }

  // Check if a ball hits the table boundaries
  void _checkBoundaryCollision(Ball ball) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final tableLeft = 0.0, tableRight = screenWidth, tableTop = 0.0, tableBottom = screenHeight * 0.8;

    if (ball.position.dx < tableLeft) {
      ball.position = Offset(tableLeft, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx * cushionDamping, ball.velocity.dy);
    } else if (ball.position.dx > tableRight) {
      ball.position = Offset(tableRight, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx * cushionDamping, ball.velocity.dy);
    }

    if (ball.position.dy < tableTop) {
      ball.position = Offset(ball.position.dx, tableTop);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * cushionDamping);
    } else if (ball.position.dy > tableBottom) {
      ball.position = Offset(ball.position.dx, tableBottom);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * cushionDamping);
    }
  }

  // Check if a ball falls into a pocket
  void _checkPocketCollision(Ball ball) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final pockets = [
      Offset(20, 20), // Top-left
      Offset(screenWidth - 20, 20), // Top-right
      Offset(20, screenHeight * 0.8 - 20), // Bottom-left
      Offset(screenWidth - 20, screenHeight * 0.8 - 20), // Bottom-right
      Offset(screenWidth / 2, 20), // Top-middle
      Offset(screenWidth / 2, screenHeight * 0.8 - 20), // Bottom-middle
      Offset(20, screenHeight * 0.4), // Middle-left
      Offset(screenWidth - 20, screenHeight * 0.4), // Middle-right
    ];
    if (ball.inPocket) return;
    for (var pocket in pockets) {
      if ((ball.position - pocket).distance < 35) {
        ball.inPocket = true;
        ball.velocity = Offset.zero;
        setState(() {
          score += getBallPoints(ball.number); // Update the score
        });
        _playPocketSound(); // Play pocket sound
      }
    }
  }

  // Assign points to each ball
  int getBallPoints(int ballNumber) {
    switch (ballNumber) {
      case 0: // Cue ball (no points)
        return 0;
      case 8: // 8-ball (special points)
        return 50;
      default: // Other balls (points equal to their number)
        return ballNumber;
    }
  }

  // Check for collisions between balls
  void _checkBallCollisions() {
    for (var i = 0; i < balls.length; i++) {
      for (var j = i + 1; j < balls.length; j++) {
        final ball1 = balls[i];
        final ball2 = balls[j];

        final delta = ball2.position - ball1.position;
        final distance = delta.distance;

        if (distance < 30 && !ball1.inPocket && !ball2.inPocket) {
          // Resolve overlap
          final overlap = (30 - distance) / 2;
          final correction = delta / distance * overlap;
          ball1.position -= correction;
          ball2.position += correction;

          // Collision response: Conservation of Momentum
          final normal = delta / distance;
          final relativeVelocity = ball1.velocity - ball2.velocity;
          final speed = relativeVelocity.dot(normal);

          if (speed > 0) continue; // Prevent double-collision response

          final impulse = normal * (2 * speed) / 2;
          ball1.velocity -= impulse;
          ball2.velocity += impulse;

          // Play sound if the collision is significant
          if (speed.abs() > 1.0) {
            _playCollisionSound();
          }
        }
      }
    }
  }

  // Play collision sound
  void _playCollisionSound() async {
    try {
      await audioPlayer.play(AssetSource('assets/sounds/ball_hit.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // Play pocket sound
  void _playPocketSound() async {
    try {
      await audioPlayer.play(AssetSource('assets/sounds/pocket_sound.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade300,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score: $score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20), // Add spacing between score and timer
                  Text(
                    'Time: ${formatDuration(elapsedTime)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: GamePainter(
                    balls: balls,
                    cueStickPosition: cueStickPosition,
                    selectedBall: selectedBall,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  size: Size(screenWidth, screenHeight * 0.8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Drag white ball to shoot!\n'
                        'Pull back further for more power',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.green,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10), // Add spacing between text and buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: gameTimer?.isActive ?? false
                            ? null // Disable the button if the timer is running
                            : () {
                          gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
                            _updateGame();
                          });
                        },
                        child: Text("Update Game!"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _initializeGame(); // Reset the balls
                            score = 0; // Reset the score
                            elapsedTime = Duration.zero; // Reset the timer
                            gameTimer?.cancel(); // Stop the game timer
                          });
                        },
                        child: Text("Reset Game"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle touch input for aiming the cue stick
  void _onPanStart(DragStartDetails details) {
    final touchPos = details.localPosition;
    for (var ball in balls) {
      if ((ball.position - touchPos).distance < 15 && !ball.inPocket) {
        selectedBall = ball;
        cueStickPosition = touchPos;
        break;
      }
    }
  }

  // Update the cue stick position while dragging
  void _onPanUpdate(DragUpdateDetails details) {
    if (selectedBall != null) {
      setState(() {
        cueStickPosition = details.localPosition;
      });
    }
  }

  // Handle the end of the drag (shoot the cue ball)
  void _onPanEnd(DragEndDetails _) {
    if (selectedBall == null || cueStickPosition == null) return;

    final direction = (selectedBall!.position - cueStickPosition!).normalized();
    final power = (selectedBall!.position - cueStickPosition!).distance.clamp(0, 150);
    if (power > 5) {
      selectedBall!.velocity = direction * (power / 10);
    }
    selectedBall = null;
    cueStickPosition = null;

    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (balls.every((b) => b.velocity.distance < 0.1)) timer.cancel();
      _updateGame();
    });
  }
}

// Represents a ball in the game
class Ball {
  final int number;
  final Color color;
  final double mass;
  Offset position;
  Offset velocity;
  bool inPocket;

  Ball({
    required this.number,
    required this.color,
    required this.position,
    this.velocity = Offset.zero,
    this.inPocket = false,
    this.mass = 1.0,
  });

  // Update the ball's position based on velocity and friction
  void updatePosition(double friction) {
    const timeDelta = 0.016; // Assuming 16ms per frame
    if (inPocket) return;
    position += velocity;
    velocity *= friction; // Apply friction
    if (velocity.distance < 0.1) velocity = Offset.zero;
  }
}

// Custom painter for rendering the game
class GamePainter extends CustomPainter {
  final List<Ball> balls;
  final Offset? cueStickPosition;
  final Ball? selectedBall;
  final double screenWidth;
  final double screenHeight;

  GamePainter({
    required this.balls,
    this.cueStickPosition,
    this.selectedBall,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawTable(canvas);
    _drawBalls(canvas);
    _drawCueStick(canvas);
  }

  // Draw the pool table
  void _drawTable(Canvas canvas) {
    // Table frame (brown border)
    final framePaint = Paint()..color = Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTRB(0, 0, screenWidth, screenHeight * 0.75), framePaint);

    // Playing surface (green)
    final surfacePaint = Paint()..color = Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTRB(10, 10, screenWidth - 10, screenHeight * 0.75 - 10), surfacePaint);

    // Pockets
    final pocketPaint = Paint()..color = Colors.black;
    final pockets = [
      Offset(20, 20), // Top-left
      Offset(screenWidth - 20, 20), // Top-right
      Offset(20, screenHeight * 0.75 - 20), // Bottom-left
      Offset(screenWidth - 20, screenHeight * 0.75 - 20), // Bottom-right
      Offset(screenWidth / 2, 20), // Top-middle
      Offset(screenWidth / 2, screenHeight * 0.75 - 20), // Bottom-middle
      Offset(20, screenHeight * 0.4), // Middle-left
      Offset(screenWidth - 20, screenHeight * 0.4), // Middle-right
    ];
    for (var pos in pockets) {
      canvas.drawCircle(pos, 20, pocketPaint);
    }

    // Center spot
    canvas.drawCircle(Offset(screenWidth / 2, screenHeight * 0.4), 3, Paint()..color = Colors.white);
  }

  // Draw the balls
  void _drawBalls(Canvas canvas) {
    for (var ball in balls) {
      if (!ball.inPocket) {
        final ballPaint = Paint()..color = ball.color;
        canvas.drawCircle(ball.position, 15, ballPaint);

        // Draw ball number
        final textPainter = TextPainter(
          text: TextSpan(
            text: ball.number.toString(),
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          ball.position - Offset(6, 6),
        );
      }
    }
  }

  // Draw the cue stick
  void _drawCueStick(Canvas canvas) {
    if (selectedBall == null || cueStickPosition == null) return;

    final cueBallCenter = selectedBall!.position;
    final direction = (cueStickPosition! - cueBallCenter).normalized();
    final power = (cueStickPosition! - cueBallCenter).distance.clamp(0.0, 150.0);

    // Draw cue stick
    canvas.drawLine(
      cueBallCenter,
      cueStickPosition!,
      Paint()
        ..color = Colors.brown
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Draw power indicator
    canvas.drawCircle(
      cueStickPosition!,
      power / 15,
      Paint()..color = Colors.red.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension for vector math operations
extension VectorMath on Offset {
  Offset normalized() => distance == 0 ? Offset.zero : this / distance;
  double dot(Offset other) => dx * other.dx + dy * other.dy;
}