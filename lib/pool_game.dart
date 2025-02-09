import 'package:flutter/material.dart';
import 'dart:async';

class PoolGame extends StatefulWidget {
  @override
  _PoolGameState createState() => _PoolGameState();
}

class _PoolGameState extends State<PoolGame> {
  List<Ball> balls = [];
  Offset? cueStickPosition;
  Ball? selectedBall;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final startX = 200.0; // X-coordinate of the triangle's base center
    final startY = 200.0; // Y-coordinate of the triangle's base center
    final ballRadius = 15.0; // Radius of each ball
    final rowSpacing = ballRadius * 2; // Vertical distance between rows

    // Add balls in a triangular formation
    balls = [
      // First row (1 ball)
      Ball(color: "black", position: Offset(startX, startY), velocity: Offset.zero),

      // Second row (2 balls)
      Ball(color: "red", position: Offset(startX - ballRadius, startY + rowSpacing), velocity: Offset.zero),
      Ball(color: "yellow", position: Offset(startX + ballRadius, startY + rowSpacing), velocity: Offset.zero),

      // Third row (3 balls)
      Ball(color: "green", position: Offset(startX - 2 * ballRadius, startY + 2 * rowSpacing), velocity: Offset.zero),
      Ball(color: "blue", position: Offset(startX, startY + 2 * rowSpacing), velocity: Offset.zero),
      Ball(color: "orange", position: Offset(startX + 2 * ballRadius, startY + 2 * rowSpacing), velocity: Offset.zero),

      // Fourth row (2 balls)
      Ball(color: "purple", position: Offset(startX - ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero),
      Ball(color: "white", position: Offset(startX + ballRadius, startY + 3 * rowSpacing), velocity: Offset.zero),

    ];
  }

  void _updateGame() {
    setState(() {
      for (var ball in balls) {
        ball.updatePosition();
        _checkBoundaryCollision(ball);
        _checkPocketCollision(ball);
      }
      _checkBallCollisions();
    });
  }

  void _checkBoundaryCollision(Ball ball) {
    final tableLeft = 65.0;
    final tableRight = 342.0;
    final tableTop = 63.0;
    final tableBottom = 500.0;

    if (ball.position.dx < tableLeft || ball.position.dx > tableRight) {
      ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
    }
    if (ball.position.dy < tableTop || ball.position.dy > tableBottom) {
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
    }
  }

  void _checkPocketCollision(Ball ball) {
    final pockets = [
      Offset(50, 50),
      Offset(350, 50),
      Offset(50, 500),
      Offset(350, 500),
      Offset(200, 50),
      Offset(200, 500),
    ];

    for (var pocket in pockets) {
      if ((ball.position - pocket).distance < 20) {
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

        if (distance < 30) {
          final overlap = 30 - distance; // Prevent sticking
          final correction = delta / distance * overlap / 2;
          ball1.position -= correction;
          ball2.position += correction;

          final collisionNormal = delta / distance;
          final relativeVelocity = ball1.velocity - ball2.velocity;
          final speed = relativeVelocity.dx * collisionNormal.dx +
              relativeVelocity.dy * collisionNormal.dy;

          if (speed > 0) continue;

          final impulse = collisionNormal * speed;
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
        child: GestureDetector(
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
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final touchPosition = details.localPosition;
    for (var ball in balls) {
      if ((ball.position - touchPosition).distance < 15) {
        selectedBall = ball;
        cueStickPosition = touchPosition;
        break;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (selectedBall != null) {
      cueStickPosition = details.localPosition;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (selectedBall != null && cueStickPosition != null) {
      final velocity = (selectedBall!.position - cueStickPosition!) / 10;
      selectedBall!.velocity = velocity;
      selectedBall = null;
      cueStickPosition = null;

      Timer.periodic(Duration(milliseconds: 16), (timer) {
        if (balls.every((ball) => ball.velocity.distance < 0.1)) {
          timer.cancel();
        }
        _updateGame();
      });
    }
  }
}

class Ball {
  final String color;
  Offset position;
  Offset velocity;
  bool inPocket;

  Ball({
    required this.color,
    required this.position,
    required this.velocity,
    this.inPocket = false,
  });

  void updatePosition() {
    if (!inPocket) {
      position += velocity;
      velocity *= 0.98; // Friction
    }
  }
}

class GamePainter extends CustomPainter {
  final List<Ball> balls;
  final Offset? cueStickPosition;
  final Ball? selectedBall;

  GamePainter({
    required this.balls,
    this.cueStickPosition,
    this.selectedBall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tablePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final pocketPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw table
    canvas.drawRect(Rect.fromLTWH(50, 50, 300, 450), tablePaint);

    // Draw pockets
    final pockets = [
      Offset(50, 50),
      Offset(350, 50),
      Offset(50, 500),
      Offset(350, 500),
      Offset(200, 50),
      Offset(200, 500),
    ];

    for (var pocket in pockets) {
      canvas.drawCircle(pocket, 20, pocketPaint);
    }

    // Draw balls
    for (var ball in balls) {
      if (!ball.inPocket) {
        final ballPaint = Paint()..color = _getBallColor(ball.color);
        canvas.drawCircle(ball.position, 15, ballPaint);
      }
    }

    // Draw cue stick
    if (selectedBall != null && cueStickPosition != null) {
      final stickPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawLine(
        selectedBall!.position,
        cueStickPosition!,
        stickPaint,
      );
    }
  }

  Color _getBallColor(String color) {
    switch (color) {
      case "black":
        return Colors.black;
      case "red":
        return Colors.red;
      case "yellow":
        return Colors.yellow;
      case "green":
        return Colors.green.shade800;
      case "blue":
        return Colors.blue;
      case "orange":
        return Colors.orange;
      case "purple":
        return Colors.purple;
      case "white":
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
