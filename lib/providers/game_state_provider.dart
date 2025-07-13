import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';

class GameState {
  final double nrg;
  final Map<String, Node> nodes;
  final double nrgPerSecond;
  final Duration timeUntilCacheFull;

  GameState({
    this.nrg = 0.0, 
    required this.nodes, 
    this.nrgPerSecond = 0.0,
    this.timeUntilCacheFull = Duration.zero,
  });

  GameState copyWith({double? nrg, Map<String, Node>? nodes, double? nrgPerSecond, Duration? timeUntilCacheFull}) {
    return GameState(
      nrg: nrg ?? this.nrg,
      nodes: nodes ?? this.nodes,
      nrgPerSecond: nrgPerSecond ?? this.nrgPerSecond,
      timeUntilCacheFull: timeUntilCacheFull ?? this.timeUntilCacheFull,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  Timer? _gameLoop;

  GameStateNotifier() : super(GameState(nodes: {
    'origin': Node(id: 'origin', level: 1, position: const Offset(2500, 2500), type: NodeType.powerTap, radius: 35.0)
  })) {
    _restartGameLoop();
  }

  int multiplierCost() => (pow(1.6, state.nodes.length) * 75).round();
  int overclockerCost() => (pow(1.5, state.nodes.length) * 60).round();
  int reducerCost() => (pow(1.55, state.nodes.length) * 65).round();
  int efficiencyCost() => (pow(1.7, state.nodes.length) * 150).round();
  int cacheMultiplierCost() => (pow(1.75, state.nodes.length) * 180).round();

  void _restartGameLoop() {
    _gameLoop?.cancel();

    double totalReduction = 0;
    for (final node in state.nodes.values) {
      if (node.type == NodeType.reducer) {
        totalReduction += node.tickSpeedReducer;
      }
    }
    final tickDurationMs = 1000 * (1 - totalReduction);
    final finalDuration = Duration(milliseconds: max(50, tickDurationMs.toInt()));

    _gameLoop = Timer.periodic(finalDuration, (timer) {
      final allNodes = state.nodes;
      final newNodes = Map<String, Node>.from(allNodes);
      double totalNrgThisTick = 0;

      final Map<String, List<String>> adjacencyList = {};
      for (final node in allNodes.values) {
        adjacencyList[node.id] = [];
      }
      for (final node in allNodes.values) {
        if (node.parentId != null && allNodes.containsKey(node.parentId)) {
          adjacencyList[node.id]!.add(node.parentId!);
          adjacencyList[node.parentId]!.add(node.id);
        }
      }

      for (final node in allNodes.values) {
        if (node.type == NodeType.powerTap) {
          double totalBoost = 0;
          double totalOverclock = 0;
          final neighbors = adjacencyList[node.id] ?? [];

          for (final neighborId in neighbors) {
            final neighborNode = allNodes[neighborId];
            if (neighborNode != null) {
              totalBoost += neighborNode.boostMultiplier;
              totalOverclock += neighborNode.overclockMultiplier;
            }
          }
          
          final nrgGeneratedThisTick = node.baseGeneration * (1 + totalBoost) * (1 + totalOverclock);
          totalNrgThisTick += nrgGeneratedThisTick;
          
          if (!node.isCacheFull) {
            final newCacheValue = min(node.maxCache, node.currentCache + nrgGeneratedThisTick);
            newNodes[node.id] = Node(
              id: node.id, level: node.level, position: node.position, parentId: node.parentId,
              type: node.type, radius: node.radius, potencyLevel: node.potencyLevel, currentCache: newCacheValue,
            );
          }
        }
      }
      
      final nrgPerSecond = totalNrgThisTick * (1000 / finalDuration.inMilliseconds);
      
      final originNode = newNodes['origin']!;
      Duration timeToFull = Duration.zero;
      if (!originNode.isCacheFull) {
        final originNrgPerSecond = nrgPerSecond;
        if (originNrgPerSecond > 0) {
          final remainingCache = originNode.maxCache - originNode.currentCache;
          final secondsToFull = remainingCache / originNrgPerSecond;
          timeToFull = Duration(seconds: secondsToFull.ceil());
        }
      }

      state = state.copyWith(
        nrg: state.nrg + totalNrgThisTick,
        nodes: newNodes,
        nrgPerSecond: nrgPerSecond,
        timeUntilCacheFull: timeToFull,
      );
    });
  }

  void purgeNodeCache(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null || node.type != NodeType.powerTap) return;

    double cacheMultiplierBonus = 0;
    for(final n in state.nodes.values) {
      if (n.type == NodeType.cacheMultiplier && n.parentId == nodeId) {
        cacheMultiplierBonus += n.cacheBonusMultiplier;
      }
    }
    final bonusNrg = node.currentCache * (2 + cacheMultiplierBonus);

    final newNodes = Map<String, Node>.from(state.nodes);
    newNodes[nodeId] = Node(
      id: node.id, level: node.level, position: node.position, parentId: node.parentId,
      type: node.type, radius: node.radius, potencyLevel: node.potencyLevel, currentCache: 0.0,
    );

    state = state.copyWith(
      nrg: state.nrg + bonusNrg,
      nodes: newNodes,
    );
  }

  void upgradeNode(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null) return;

    if (node.id != 'origin') {
      final parentNode = state.nodes[node.parentId];
      if (parentNode != null && node.level >= parentNode.level) {
        return;
      }
    }

    double totalCostReduction = 0;
    if (node.type == NodeType.powerTap) {
      for (final n in state.nodes.values) {
        if (n.type == NodeType.efficiency && n.parentId == node.id) {
          totalCostReduction += n.costReducer;
        }
      }
    }
    
    final baseCost = node.nextUpgradeCost;
    final finalCost = (baseCost * (1 - totalCostReduction)).round();

    if (state.nrg >= finalCost) {
      final newNodes = Map<String, Node>.from(state.nodes);
      newNodes[nodeId] = Node(
        id: node.id, level: node.level + 1, position: node.position, parentId: node.parentId,
        type: node.type, radius: node.radius, potencyLevel: node.potencyLevel, currentCache: node.currentCache,
      );
      state = state.copyWith(nrg: state.nrg - finalCost, nodes: newNodes);
      if (node.type == NodeType.reducer) _restartGameLoop();
    }
  }

  void upgradeNodePotency(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null || node.type != NodeType.multiplier) return;

    final cost = node.nextPotencyUpgradeCost;
    if (state.nrg >= cost) {
      final newNodes = Map<String, Node>.from(state.nodes);
      newNodes[nodeId] = Node(
        id: node.id, level: node.level, position: node.position, parentId: node.parentId,
        type: node.type, radius: node.radius, potencyLevel: node.potencyLevel + 1, currentCache: node.currentCache,
      );
      state = state.copyWith(nrg: state.nrg - cost, nodes: newNodes);
    }
  }

  void addNewNode(NodeType type, String parentId) {
    final parentNode = state.nodes[parentId];
    if (parentNode == null) return;

    final connectedNodes = state.nodes.values.where((n) => n.parentId == parentId).length;
    if (connectedNodes >= parentNode.connectionSlots) return;

    int cost;
    switch(type) {
      case NodeType.powerTap: return; 
      case NodeType.multiplier: cost = multiplierCost(); break;
      case NodeType.overclocker: cost = overclockerCost(); break;
      case NodeType.reducer: cost = reducerCost(); break;
      case NodeType.efficiency: cost = efficiencyCost(); break;
      case NodeType.cacheMultiplier: cost = cacheMultiplierCost(); break;
    }
    if (state.nrg < cost) return;

    Offset newPosition;
    double newRadius = 15 + Random().nextDouble() * 10;
    int attempts = 0;
    bool positionIsGood;

    do {
      positionIsGood = true;
      final angle = Random().nextDouble() * 2 * pi;
      final distance = 80 + Random().nextDouble() * 100; 
      newPosition = parentNode.position + Offset.fromDirection(angle, distance);

      for (final existingNode in state.nodes.values) {
        final distanceBetweenNodes = (newPosition - existingNode.position).distance;
        if (distanceBetweenNodes < (newRadius + existingNode.radius + 15)) {
          positionIsGood = false;
          break;
        }
      }
      attempts++;
    } while (!positionIsGood && attempts < 50);

    if (!positionIsGood) return;

    final newId = 'node_${state.nodes.length}';
    final newNode = Node(
      id: newId, position: newPosition, parentId: parentNode.id, type: type, radius: newRadius,
    );

    final newNodes = Map<String, Node>.from(state.nodes);
    newNodes[newId] = newNode;

    state = state.copyWith(nrg: state.nrg - cost, nodes: newNodes);
    if (type == NodeType.reducer) _restartGameLoop();
  }

  void addDebugNrg() {
    state = state.copyWith(nrg: state.nrg + 100000);
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
