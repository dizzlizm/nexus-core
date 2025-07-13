import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'dart:math';
import '../config/theme.dart';
import '../models/node.dart';

class NexusPainter extends CustomPainter {
  final Map<String, Node> nodes;
  final Matrix4 transform;

  NexusPainter({required this.nodes, required this.transform});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = AppTheme.gridColor.withOpacity(0.2)..strokeWidth = 0.5;
    const double gridSize = 50.0;

    final Matrix4 invertedTransform = Matrix4.inverted(transform);
    final Vector3 topLeft = invertedTransform.transform3(Vector3(0, 0, 0));
    final Vector3 topRight = invertedTransform.transform3(Vector3(size.width, 0, 0));
    final Vector3 bottomLeft = invertedTransform.transform3(Vector3(0, size.height, 0));
    final Vector3 bottomRight = invertedTransform.transform3(Vector3(size.width, size.height, 0));

    final double minX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce(min);
    final double maxX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce(max);
    final double minY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce(min);
    final double maxY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce(max);

    final Rect visibleRect = Rect.fromLTRB(minX, minY, maxX, maxY);
    final double left = (visibleRect.left / gridSize).floorToDouble() * gridSize;
    final double top = (visibleRect.top / gridSize).floorToDouble() * gridSize;
    final double right = (visibleRect.right / gridSize).ceilToDouble() * gridSize;
    final double bottom = (visibleRect.bottom / gridSize).ceilToDouble() * gridSize;

    for (double i = left; i <= right; i += gridSize) {
      canvas.drawLine(Offset(i, top), Offset(i, bottom), gridPaint);
    }
    for (double i = top; i <= bottom; i += gridSize) {
      canvas.drawLine(Offset(left, i), Offset(right, i), gridPaint);
    }

    final synapsePaint = Paint()..color = AppTheme.synapseColor..strokeWidth = 2.0;
    for (final node in nodes.values) {
      if (node.parentId != null && nodes.containsKey(node.parentId)) {
        final parentNode = nodes[node.parentId]!;
        canvas.drawLine(node.position, parentNode.position, synapsePaint);
      }
    }

    for (final node in nodes.values) {
      Color baseColor;
      Color glowColor;

      switch (node.type) {
        case NodeType.powerTap: baseColor = AppTheme.powerTapColor; glowColor = AppTheme.powerTapGlow; break;
        case NodeType.multiplier: baseColor = AppTheme.multiplierColor; glowColor = AppTheme.multiplierGlow; break;
        case NodeType.overclocker: baseColor = AppTheme.overclockerColor; glowColor = AppTheme.overclockerGlow; break;
        case NodeType.reducer: baseColor = AppTheme.reducerColor; glowColor = AppTheme.reducerGlow; break;
        case NodeType.efficiency: baseColor = AppTheme.efficiencyColor; glowColor = AppTheme.efficiencyGlow; break;
        case NodeType.cacheMultiplier: baseColor = AppTheme.cacheMultiplierColor; glowColor = AppTheme.cacheMultiplierGlow; break;
      }

      if (node.isCacheFull) {
        baseColor = baseColor.withOpacity(0.3);
        glowColor = glowColor.withOpacity(0.1);
      }

      final glowPaint = Paint()..color = glowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25.0);
      final Rect nodeRect = Rect.fromCircle(center: node.position, radius: node.radius);
      
      final orbShader = RadialGradient(
        colors: [ Colors.white.withOpacity(0.8), baseColor, baseColor.withOpacity(0.9) ],
        stops: const [0.0, 0.6, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(nodeRect);

      final nodePaint = Paint()..shader = orbShader;

      canvas.drawCircle(node.position, node.radius, glowPaint);
      canvas.drawCircle(node.position, node.radius, nodePaint);

      final textSpan = TextSpan(
        text: node.level.toString(),
        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      final textOffset = node.position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant NexusPainter oldDelegate) {
    return true;
  }
}
