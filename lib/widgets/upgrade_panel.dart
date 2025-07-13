import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/game_state_provider.dart';
import '../models/node.dart';

void showUpgradePanel(BuildContext context, Node node) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return UpgradePanelContent(node: node);
    },
  );
}

class UpgradePanelContent extends ConsumerStatefulWidget {
  final Node node;
  const UpgradePanelContent({super.key, required this.node});

  @override
  ConsumerState<UpgradePanelContent> createState() => _UpgradePanelContentState();
}

class _UpgradePanelContentState extends ConsumerState<UpgradePanelContent> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestNode = ref.watch(gameStateProvider.select((gs) => gs.nodes[widget.node.id]!));
    final canExpand = latestNode.connectionSlots > 0;
    
    // This is the definitive fix for the TabController. It is rebuilt
    // only when the length needs to change, preventing the Ticker error.
    if (_tabController.length != (canExpand ? 2 : 1)) {
      _tabController = TabController(length: canExpand ? 2 : 1, vsync: this);
    }

    String nodeName;
    switch (latestNode.type) {
      case NodeType.powerTap: nodeName = 'Mainframe Tap'; break;
      case NodeType.multiplier: nodeName = 'Multiplier'; break;
      case NodeType.overclocker: nodeName = 'Overclocker'; break;
      case NodeType.reducer: nodeName = 'Reducer'; break;
      case NodeType.efficiency: nodeName = 'Efficiency Core'; break;
      case NodeType.cacheMultiplier: nodeName = 'Cache Multiplier'; break;
    }
    if (latestNode.id != 'origin') {
      nodeName += ' ${latestNode.id.split('_').last}';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.gridColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(nodeName, style: AppTheme.darkTheme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (canExpand) ...[
            TabBar(
              controller: _tabController,
              tabs: const [ Tab(text: 'Upgrade'), Tab(text: 'Expand') ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: canExpand ? 360 : 300,
            child: TabBarView(
              controller: _tabController,
              physics: canExpand ? null : const NeverScrollableScrollPhysics(),
              children: [
                _buildUpgradeTab(latestNode),
                if (canExpand)
                  _buildExpandTab(latestNode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(NodeType type) {
    String description = '';
    String backstory = '';

    switch (type) {
      case NodeType.powerTap:
        description = 'Generates NRG and stores it in a local cache for a bonus.';
        backstory = 'A direct tap into a core power conduit. The more you reinforce it, the more raw energy you can siphon from the system.';
        break;
      case NodeType.multiplier:
        description = 'Multiplies the NRG output of its direct parent.';
        backstory = 'By hijacking a data bus, you can force its parent node to work harder, multiplying its output. A risky but powerful exploit.';
        break;
      case NodeType.overclocker:
        description = 'Provides a secondary multiplicative boost to its direct parent.';
        backstory = 'You\'ve compromised a CPU clock cycle controller. This allows you to overclock its parent node, pushing them beyond their designed limits.';
        break;
      case NodeType.reducer:
        description = 'Reduces the time between NRG generation ticks for the entire network.';
        backstory = 'A breach in the system\'s core timing mechanism. This allows you to accelerate your own processes, making everything happen faster.';
        break;
      case NodeType.efficiency:
        description = 'Reduces the NRG cost of upgrading its direct parent.';
        backstory = 'This exploit rewrites the system\'s resource allocation protocols, making its parent\'s upgrades require less energy to execute.';
        break;
      case NodeType.cacheMultiplier:
        description = 'Increases the bonus NRG received when purging a cache.';
        backstory = 'This reroutes purged energy through a series of capacitors, amplifying the payload before it hits your main storage.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(backstory, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildUpgradeTab(Node latestNode) {
    final gameState = ref.watch(gameStateProvider);
    
    double totalCostReduction = 0;
    final parentNode = gameState.nodes[latestNode.parentId];
    if (parentNode != null) {
       for (final n in gameState.nodes.values) {
        if (n.type == NodeType.efficiency && n.parentId == latestNode.id) {
          totalCostReduction += n.costReducer;
        }
      }
    }
    
    final finalCost = (latestNode.nextUpgradeCost * (1 - totalCostReduction)).round();
    final canAffordUpgrade = gameState.nrg >= finalCost;
    
    final isAtLevelCap = parentNode != null && latestNode.level >= parentNode.level;

    List<Widget> stats = [];
    List<Widget> primaryActions = [];
    List<Widget> secondaryUpgrades = [];

    switch (latestNode.type) {
      case NodeType.powerTap:
        final cachePercentage = (latestNode.currentCache / latestNode.maxCache).clamp(0.0, 1.0);
        stats.add(Text('Generation: ${latestNode.baseGeneration.toStringAsFixed(2)} NRG/sec', style: AppTheme.darkTheme.textTheme.bodyMedium));
        stats.add(Text('Cache: ${latestNode.currentCache.toStringAsFixed(1)} / ${latestNode.maxCache.toStringAsFixed(1)}', style: AppTheme.darkTheme.textTheme.bodyMedium));
        stats.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: LinearProgressIndicator(value: cachePercentage, backgroundColor: Colors.grey[800], color: AppTheme.powerTapColor),
        ));
        
        double cacheMultiplierBonus = 0;
        for(final n in gameState.nodes.values) {
          if (n.type == NodeType.cacheMultiplier && n.parentId == latestNode.id) {
            cacheMultiplierBonus += n.cacheBonusMultiplier;
          }
        }
        final bonusNrg = latestNode.currentCache * (2 + cacheMultiplierBonus);

        primaryActions.add(
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                  onPressed: canAffordUpgrade && !isAtLevelCap ? () => ref.read(gameStateProvider.notifier).upgradeNode(latestNode.id) : null,
                  child: Text(isAtLevelCap ? 'Parent Level Too Low' : 'Upgrade Level for $finalCost NRG'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Purge Cache for Bonus',
                style: IconButton.styleFrom(backgroundColor: AppTheme.darkTheme.colorScheme.secondary),
                onPressed: latestNode.currentCache > 0 ? () => ref.read(gameStateProvider.notifier).purgeNodeCache(latestNode.id) : null,
              ),
            ],
          )
        );
        stats.add(Text('Purge Bonus: ${bonusNrg.toStringAsFixed(1)} NRG', style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.cacheMultiplierColor)));
        break;
      case NodeType.multiplier:
         stats.add(Text('Boost: +${(latestNode.boostMultiplier * 100).toStringAsFixed(1)}%', style: AppTheme.darkTheme.textTheme.bodyMedium));
        final canAffordPotency = gameState.nrg >= latestNode.nextPotencyUpgradeCost;
        secondaryUpgrades.add(const SizedBox(height: 12));
        secondaryUpgrades.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.multiplierColor.withOpacity(0.5)),
              onPressed: canAffordPotency ? () => ref.read(gameStateProvider.notifier).upgradeNodePotency(latestNode.id) : null,
              child: Text('Upgrade Potency Lvl ${latestNode.potencyLevel} (${latestNode.nextPotencyUpgradeCost} NRG)'),
            ),
          )
        );
        primaryActions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkTheme.colorScheme.primary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
              onPressed: canAffordUpgrade && !isAtLevelCap ? () => ref.read(gameStateProvider.notifier).upgradeNode(latestNode.id) : null,
              child: Text(isAtLevelCap ? 'Parent Level Too Low' : 'Upgrade Level for $finalCost NRG'),
            ),
          )
        );
        break;
      default:
        if (latestNode.type == NodeType.overclocker) {
          stats.add(Text('Overclock: +${(latestNode.overclockMultiplier * 100).toStringAsFixed(1)}%', style: AppTheme.darkTheme.textTheme.bodyMedium));
        } else if (latestNode.type == NodeType.reducer) {
          stats.add(Text('Tick Speed: -${(latestNode.tickSpeedReducer * 100).toStringAsFixed(1)}%', style: AppTheme.darkTheme.textTheme.bodyMedium));
        } else if (latestNode.type == NodeType.efficiency) {
          stats.add(Text('Cost Reduction: ${(latestNode.costReducer * 100).toStringAsFixed(1)}%', style: AppTheme.darkTheme.textTheme.bodyMedium));
        } else if (latestNode.type == NodeType.cacheMultiplier) {
          stats.add(Text('Cache Bonus: +${(latestNode.cacheBonusMultiplier * 100).toStringAsFixed(1)}%', style: AppTheme.darkTheme.textTheme.bodyMedium));
        }

        primaryActions.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkTheme.colorScheme.primary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
              onPressed: canAffordUpgrade && !isAtLevelCap ? () => ref.read(gameStateProvider.notifier).upgradeNode(latestNode.id) : null,
              child: Text(isAtLevelCap ? 'Parent Level Too Low' : 'Upgrade Level for $finalCost NRG'),
            ),
          )
        );
        break;
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDescription(latestNode.type),
          const Divider(color: AppTheme.gridColor),
          const SizedBox(height: 16),
          Text('Level: ${latestNode.level}', style: AppTheme.darkTheme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ...stats.map((s) => Center(child: s)),
          const SizedBox(height: 24),
          ...primaryActions,
          ...secondaryUpgrades,
        ],
      ),
    );
  }

  Widget _buildExpandTab(Node parentNode) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final connectedNodes = gameState.nodes.values.where((n) => n.parentId == parentNode.id).length;
    final hasAvailableSlots = connectedNodes < parentNode.connectionSlots;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('Connection Slots: $connectedNodes / ${parentNode.connectionSlots}', style: AppTheme.darkTheme.textTheme.bodyMedium)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.multiplierColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
            onPressed: hasAvailableSlots && gameState.nrg >= notifier.multiplierCost() ? () { notifier.addNewNode(NodeType.multiplier, parentNode.id); Navigator.pop(context); } : null,
            child: Text('Multiplier (${notifier.multiplierCost()} NRG)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.overclockerColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
            onPressed: hasAvailableSlots && gameState.nrg >= notifier.overclockerCost() ? () { notifier.addNewNode(NodeType.overclocker, parentNode.id); Navigator.pop(context); } : null,
            child: Text('Overclocker (${notifier.overclockerCost()} NRG)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reducerColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
            onPressed: hasAvailableSlots && gameState.nrg >= notifier.reducerCost() ? () { notifier.addNewNode(NodeType.reducer, parentNode.id); Navigator.pop(context); } : null,
            child: Text('Reducer (${notifier.reducerCost()} NRG)'),
          ),
           const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.efficiencyColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
            onPressed: hasAvailableSlots && gameState.nrg >= notifier.efficiencyCost() ? () { notifier.addNewNode(NodeType.efficiency, parentNode.id); Navigator.pop(context); } : null,
            child: Text('Efficiency Core (${notifier.efficiencyCost()} NRG)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cacheMultiplierColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
            onPressed: hasAvailableSlots && gameState.nrg >= notifier.cacheMultiplierCost() ? () { notifier.addNewNode(NodeType.cacheMultiplier, parentNode.id); Navigator.pop(context); } : null,
            child: Text('Cache Multiplier (${notifier.cacheMultiplierCost()} NRG)'),
          ),
        ],
      ),
    );
  }
}