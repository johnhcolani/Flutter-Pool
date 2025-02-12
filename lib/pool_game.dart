import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class PoolGame extends StatefulWidget {
  @override
  _PoolGameState createState() => _PoolGameState();
}

class _PoolGameState extends State<PoolGame> {
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
    _initializeGame();
  }

  void _initializeGame() {
    // Add white cue ball
    balls.add(Ball(
      number: 0,
      color: Colors.white,
      position: Offset(220, 600),
      velocity: Offset.zero,
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
          position: Offset(startX, startY)), // Top row
      Ball(
          number: 2,
          color: Colors.blue,
          position: Offset(
              startX - ballRadius, startY + rowSpacing)), // Second row, left
      Ball(
          number: 3,
          color: Colors.red,
          position: Offset(
              startX + ballRadius, startY + rowSpacing)), // Second row, right
      Ball(
          number: 4,
          color: Colors.purple,
          position: Offset(startX - 2 * ballRadius,
              startY + 2 * rowSpacing)), // Third row, far left
      Ball(
          number: 5,
          color: Colors.orange,
          position:
              Offset(startX, startY + 2 * rowSpacing)), // Third row, center
      Ball(
          number: 6,
          color: Colors.green,
          position: Offset(startX + 2 * ballRadius,
              startY + 2 * rowSpacing)), // Third row, far right
      Ball(
          number: 7,
          color: Colors.brown,
          position: Offset(startX - 3 * ballRadius,
              startY + 3 * rowSpacing)), // Fourth row, far left
      Ball(
          number: 9,
          color: Colors.yellow.shade800,
          position: Offset(startX - ballRadius,
              startY + 3 * rowSpacing)), // Fourth row, center-left
      Ball(
          number: 10,
          color: Colors.blue.shade800,
          position: Offset(startX + ballRadius,
              startY + 3 * rowSpacing)), // Fourth row, center-right
      Ball(
          number: 11,
          color: Colors.pink,
          position: Offset(startX + 3 * ballRadius,
              startY + 3 * rowSpacing)), // Fourth row, far right
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
        tableRight = 380.0,
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
        final ball1 = balls[i], ball2 = balls[j];
        final delta = ball2.position - ball1.position;
        final distance = delta.distance;

        if (distance < 30) {
          final overlap = (30 - distance) / 2 * 0.8;
          final correction = delta / distance * overlap;
          ball1.position -= correction;
          ball2.position += correction;

          final normal = delta / distance;
          final relativeVelocity = ball1.velocity - ball2.velocity;
          final speed = relativeVelocity.dot(normal);

          if (speed > 0) continue;
          final impulse = normal * speed * collisionRestitution;
          ball1.velocity -= impulse;
          ball2.velocity += impulse;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: GamePainter(
                  balls: balls,
                  cueStickPosition: cueStickPosition,
                  selectedBall: selectedBall,
                ),
                size: Size.infinite,
              ),
            ),
            Positioned(
              top: 740,
              left: 20,
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
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _updateGame();
                    });
                  },
                  child: Text("Update Game!")),
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
      cueStickPosition = details.localPosition;
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

  void _drawCueStick(Canvas canvas) {
    if (selectedBall == null || cueStickPosition == null) return;

    final direction = (cueStickPosition! - selectedBall!.position).normalized();
    final power =
        (cueStickPosition! - selectedBall!.position).distance.clamp(0.0, 150.0);
    final endPoint = selectedBall!.position + direction * power;

    // Draw power indicator
    canvas.drawCircle(
      cueStickPosition!,
      power / 15,
      Paint()..color = Colors.red.withOpacity(0.3),
    );

    // Draw cue stick
    canvas.drawLine(
      selectedBall!.position,
      endPoint,
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
