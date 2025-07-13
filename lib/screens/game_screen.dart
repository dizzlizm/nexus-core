import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../widgets/nexus_painter.dart';
import '../widgets/upgrade_panel.dart';
import '../config/theme.dart';

const bool kDeveloperMode = true;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  Animation<Matrix4>? _recenterAnimation;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      centerOnOrigin(instant: true);
    });
  }

  void centerOnOrigin({bool instant = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final originNode = ref.read(gameStateProvider).nodes['origin'];
    if (originNode == null) return;

    final worldCenter = originNode.position;
    const double initialScale = 1.5;

    final xTranslation = screenWidth / 2 - worldCenter.dx * initialScale;
    final yTranslation = screenHeight / 2 - worldCenter.dy * initialScale;
    
    final targetMatrix = Matrix4.identity()
      ..translate(xTranslation, yTranslation)
      ..scale(initialScale);

    if (instant) {
      _transformationController.value = targetMatrix;
      return;
    }

    _recenterAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    
    _recenterAnimation!.addListener(() {
      _transformationController.value = _recenterAnimation!.value;
    });

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final nodes = gameState.nodes;

    String formatDuration(Duration d) {
      if (d.inSeconds <= 0) return 'Full';
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
      if (d.inHours > 0) {
        return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      }
      return "$twoDigitMinutes:$twoDigitSeconds";
    }

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final worldPosition = _transformationController.toScene(details.localPosition);
              
              for (final node in nodes.values) {
                final distance = (worldPosition - node.position).distance;
                if (distance <= node.radius) {
                  showUpgradePanel(context, node);
                  return;
                }
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 4.0,
              child: ValueListenableBuilder<Matrix4>(
                valueListenable: _transformationController,
                builder: (context, value, child) {
                  return CustomPaint(
                    size: const Size(5000, 5000),
                    painter: NexusPainter(
                      nodes: nodes,
                      transform: value,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkTheme.colorScheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gridColor)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'NRG ${gameState.nrg.toStringAsFixed(1)}',
                    style: AppTheme.darkTheme.textTheme.headlineSmall,
                  ),
                  Text(
                    '${gameState.nrgPerSecond.toStringAsFixed(2)}/sec',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.reducerColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cache Full: ${formatDuration(gameState.timeUntilCacheFull)}',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.powerTapColor),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              tooltip: 'Recenter on Mainframe',
              onPressed: () => centerOnOrigin(),
              child: const Icon(Icons.gps_fixed),
            ),
          ),
          if (kDeveloperMode)
            Positioned(
              bottom: 30,
              left: 30,
              child: FloatingActionButton(
                tooltip: 'Add 100k NRG',
                onPressed: () => ref.read(gameStateProvider.notifier).addDebugNrg(),
                backgroundColor: Colors.red,
                mini: true,
                child: const Icon(Icons.bug_report),
              ),
            ),
        ],
      ),
    );
  }
}
