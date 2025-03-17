import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PoolGame extends StatefulWidget {
  const PoolGame({super.key});

  @override
  _PoolGameState createState() => _PoolGameState();
}

class _PoolGameState extends State<PoolGame> {
  late final AudioPlayer audioPlayer;
  List<Ball> balls = [];
  Offset? cueStickPosition;
  Ball? selectedBall;
  final double tableFriction = 0.98;
  final double cushionDamping = 0.85;
  final double collisionRestitution = 0.9;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _initializeGame();
  }

  void _initializeGame() {
    // Clear the existing balls
    balls.clear();

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
      Ball(
        number: 8,
        color: Colors.black,
        position: Offset(startX, startY),
        velocity: Offset.zero,
        inPocket: false,
      ), // Top row
      Ball(
        number: 2,
        color: Colors.blue,
        position: Offset(startX - ballRadius, startY + rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Second row, left
      Ball(
        number: 3,
        color: Colors.red,
        position: Offset(startX + ballRadius, startY + rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Second row, right
      Ball(
        number: 4,
        color: Colors.purple,
        position: Offset(startX - 2 * ballRadius, startY + 2 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Third row, far left
      Ball(
        number: 5,
        color: Colors.orange,
        position: Offset(startX, startY + 2 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Third row, center
      Ball(
        number: 6,
        color: Colors.green,
        position: Offset(startX + 2 * ballRadius, startY + 2 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Third row, far right
      Ball(
        number: 7,
        color: Colors.brown,
        position: Offset(startX - 3 * ballRadius, startY + 3 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Fourth row, far left
      Ball(
        number: 9,
        color: Colors.yellow.shade800,
        position: Offset(startX - ballRadius, startY + 3 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Fourth row, center-left
      Ball(
        number: 10,
        color: Colors.blue.shade800,
        position: Offset(startX + ballRadius, startY + 3 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Fourth row, center-right
      Ball(
        number: 11,
        color: Colors.pink,
        position: Offset(startX + 3 * ballRadius, startY + 3 * rowSpacing),
        velocity: Offset.zero,
        inPocket: false,
      ), // Fourth row, far right
    ]);
  }
  void _updateGame() {
    setState(() {
      for (var ball in balls) {
        ball.updatePosition(tableFriction);
        _checkBoundaryCollision(ball);
        _checkPocketCollision(ball);
      }
      _checkBallCollisions();
    });
  }

  void _checkBoundaryCollision(Ball ball) {
    const tableLeft = 65.0,
        tableRight = 360.0,
        tableTop = 63.0,
        tableBottom = 680.0;

    if (ball.position.dx < tableLeft) {
      ball.position = Offset(tableLeft, ball.position.dy);
      ball.velocity =
          Offset(-ball.velocity.dx * cushionDamping, ball.velocity.dy);
    } else if (ball.position.dx > tableRight) {
      ball.position = Offset(tableRight, ball.position.dy);
      ball.velocity =
          Offset(-ball.velocity.dx * cushionDamping, ball.velocity.dy);
    }

    if (ball.position.dy < tableTop) {
      ball.position = Offset(ball.position.dx, tableTop);
      ball.velocity =
          Offset(ball.velocity.dx, -ball.velocity.dy * cushionDamping);
    } else if (ball.position.dy > tableBottom) {
      ball.position = Offset(ball.position.dx, tableBottom);
      ball.velocity =
          Offset(ball.velocity.dx, -ball.velocity.dy * cushionDamping);
    }
  }

  void _checkPocketCollision(Ball ball) {
    final pockets = [
      Offset(50, 50), // Top-left
      Offset(380, 50), // Top-right
      Offset(50, 700), // Bottom-left
      Offset(380, 700), // Bottom-right
      Offset(220, 50), // Top-middle
      Offset(220, 700), // Bottom-middle
      Offset(50, 375), // Middle-left
      Offset(380, 375), // Middle-right
    ];
    if (ball.inPocket) return;
    for (var pocket in pockets) {
      if ((ball.position - pocket).distance < 35) {
        ball.inPocket = true;
        ball.velocity = Offset.zero;
      }
    }
  }

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
          if (speed.abs() > 1.0) { // Adjust threshold for triggering sound
            _playCollisionSound();
          }
        }
      }
    }
  }

  void _playCollisionSound() async {
    try {
      await audioPlayer.play(AssetSource('assets/sounds/ball_hit.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 5,
              left:-10,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: SizedBox(
                  width: 400,
                  height: 700,
                  child: CustomPaint(
                    painter: GamePainter(
                      balls: balls,
                      cueStickPosition: cueStickPosition,
                      selectedBall: selectedBall,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 740,
              left: 30,
              child: Center(
                child: Text(
                  'Drag white ball to shoot!\n'
                  'Pull back further for more power',
                  style: TextStyle(color: Colors.black, fontSize: 16, shadows: [
                    Shadow(
                        color: Colors.green,
                        blurRadius: 2,
                        offset: Offset(1, 1))
                  ]),
                ),
              ),
            ),
            Positioned(
              top: 800,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  ElevatedButton(
                      onPressed: gameTimer?.isActive ?? false
                          ? null // Disable the button if the timer is running
                          : () {
                        gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
                          _updateGame();
                        });
                      },
                      child: Text("Update Game!")),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeGame(); // Reset the balls to their initial positions
                        gameTimer?.cancel(); // Stop the timer
                      });
                    },
                    child: Text("Reset Game"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

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

  void _onPanUpdate(DragUpdateDetails details) {
    if (selectedBall != null) {
      setState(() {
        cueStickPosition = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (selectedBall == null || cueStickPosition == null) return;

    final direction = (selectedBall!.position - cueStickPosition!).normalized();
    final power =
    (selectedBall!.position - cueStickPosition!).distance.clamp(0, 150);
    if (power > 5) {
      // Minimum power threshold
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

  @override
  void dispose() {
    gameTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}

class Ball {
  final int number;
  final Color color;
  final double mass;
  Offset position;
  Offset velocity;
  bool inPocket;

  Ball(
      {required this.number,
      required this.color,
      required this.position,
      this.velocity = Offset.zero,
      this.inPocket = false,
      this.mass = 1.0});

  void updatePosition(double friction) {
    final timeDelta = 0.016; // Assuming 16ms per frame
    if (inPocket) return;
    position += velocity;
    velocity -= velocity * 0.01; // Small drag force
    if (velocity.distance < 0.1) velocity = Offset.zero;
  }
}

class GamePainter extends CustomPainter {
  final List<Ball> balls;
  final Offset? cueStickPosition;
  final Ball? selectedBall;

  GamePainter({required this.balls, this.cueStickPosition, this.selectedBall});

  @override
  void paint(Canvas canvas, Size size) {
    _drawTable(canvas);
    _drawBalls(canvas);
    _drawCueStick(canvas);
  }

  void _drawTable(Canvas canvas) {
    // Table frame
    canvas.drawRect(
        Rect.fromLTRB(30, 30, 400, 700), Paint()..color = Color(0xFF5D4037));

    // Playing surface
    canvas.drawRect(
        Rect.fromLTRB(50, 50, 380, 680), Paint()..color = Color(0xFF2E7D32));

    // Pockets
    final pocketPaint = Paint()..color = Colors.black;
    final pockets = [
      Offset(50, 50), // Top-left
      Offset(380, 50), // Top-right
      Offset(50, 700), // Bottom-left
      Offset(380, 700), // Bottom-right
      Offset(220, 50), // Top-middle
      Offset(220, 700), // Bottom-middle
      Offset(50, 375), // Middle-left
      Offset(380, 375), // Middle-right
    ];
    for (var pos in pockets) {
      canvas.drawCircle(pos, 20, pocketPaint);
    }

    // Center spot
    canvas.drawCircle(Offset(220, 375), 3, Paint()..color = Colors.white);
  }

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
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    final dashWidth = 10.0;
    final dashSpace = 5.0;
    final pathMetric = path.computeMetrics().first;
    var distance = 0.0;

    while (distance < pathMetric.length) {
      final startOffset = pathMetric.getTangentForOffset(distance)!.position;
      distance += dashWidth;
      if (distance > pathMetric.length) distance = pathMetric.length;
      final endOffset = pathMetric.getTangentForOffset(distance)!.position;
      canvas.drawLine(startOffset, endOffset, paint);
      distance += dashSpace;
    }
  }
  void _drawCueStick(Canvas canvas) {
    if (selectedBall == null || cueStickPosition == null) return;

    final cueBallCenter = selectedBall!.position;
    final direction = (cueStickPosition! - cueBallCenter).normalized();
    final power = (cueStickPosition! - cueBallCenter).distance.clamp(0.0, 150.0);

    // Draw direction line
    final directionLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw a line from the cue ball center to the cue stick position
    _drawDashedLine(canvas, cueBallCenter, cueStickPosition!, directionLinePaint);
    // Optional: Add an arrowhead at the end of the line
    final arrowHeadPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final arrowHeadPath = Path();
    final arrowSize = 10.0;
    final arrowEnd = cueStickPosition!;
    final arrowDirection = (cueBallCenter - cueStickPosition!).normalized();

    arrowHeadPath.moveTo(arrowEnd.dx, arrowEnd.dy);
    arrowHeadPath.lineTo(
      arrowEnd.dx + arrowDirection.dy * arrowSize - arrowDirection.dx * arrowSize,
      arrowEnd.dy - arrowDirection.dx * arrowSize - arrowDirection.dy * arrowSize,
    );
    arrowHeadPath.lineTo(
      arrowEnd.dx - arrowDirection.dy * arrowSize - arrowDirection.dx * arrowSize,
      arrowEnd.dy + arrowDirection.dx * arrowSize - arrowDirection.dy * arrowSize,
    );
    arrowHeadPath.close();
    canvas.drawPath(arrowHeadPath, arrowHeadPaint);

    // Draw power indicator (optional)
    canvas.drawCircle(
      cueStickPosition!,
      power / 15,
      Paint()..color = Colors.red.withOpacity(0.3),
    );

    // Draw cue stick
    canvas.drawLine(
      cueBallCenter,
      cueStickPosition!,
      Paint()
        ..color = Colors.brown
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension VectorMath on Offset {
  Offset normalized() => distance == 0 ? Offset.zero : this / distance;
  double dot(Offset other) => dx * other.dx + dy * other.dy;
}
