import 'dart:math';
import 'package:flutter/material.dart';

enum NodeType { powerTap, multiplier, overclocker, reducer, efficiency, cacheMultiplier }

class Node {
  final String id;
  int level;
  final Offset position;
  final String? parentId;
  final NodeType type;
  final double radius;
  final int potencyLevel;
  final double currentCache;

  Node({
    required this.id,
    this.level = 1,
    required this.position,
    this.parentId,
    required this.type,
    required this.radius,
    this.potencyLevel = 0,
    this.currentCache = 0.0,
  });

  double get baseGeneration => (type == NodeType.powerTap) ? (pow(level, 1.25) * 0.9) : 0;
  double get boostMultiplier => (type == NodeType.multiplier) ? (level * 0.12) * (1 + potencyLevel * 0.2) : 0;
  double get overclockMultiplier => (type == NodeType.overclocker) ? level * 0.08 : 0;
  double get tickSpeedReducer => (type == NodeType.reducer) ? level * 0.035 : 0;
  double get costReducer => (type == NodeType.efficiency) ? level * 0.012 : 0;
  double get cacheBonusMultiplier => (type == NodeType.cacheMultiplier) ? level * 0.30 : 0;

  int get connectionSlots {
    switch (type) {
      case NodeType.powerTap:
        return 1 + ((level - 1) / 5).floor();
      case NodeType.multiplier:
      case NodeType.overclocker:
      case NodeType.reducer:
      case NodeType.efficiency:
      case NodeType.cacheMultiplier:
        return (level / 10).floor();
    }
  }

  double get maxCache {
    if (type != NodeType.powerTap) return 0;
    return baseGeneration * 1800;
  }
  bool get isCacheFull => currentCache >= maxCache;

  int get nextUpgradeCost {
    double costMultiplier;
    switch (type) {
      case NodeType.powerTap: costMultiplier = 1.45; break;
      case NodeType.multiplier: costMultiplier = 1.52; break;
      case NodeType.overclocker: costMultiplier = 1.50; break;
      case NodeType.reducer: costMultiplier = 1.51; break;
      case NodeType.efficiency: costMultiplier = 1.54; break;
      case NodeType.cacheMultiplier: costMultiplier = 1.53; break;
    }
    return (pow(costMultiplier, level) * 10).round();
  }

  int get nextPotencyUpgradeCost {
    if (type != NodeType.multiplier) return 0;
    return (pow(2.2, potencyLevel) * 300).round();
  }
}
