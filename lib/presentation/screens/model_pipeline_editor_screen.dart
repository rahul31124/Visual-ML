import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/neural_model_definition.dart';
import '../providers/gemini_provider.dart';
import '../providers/model_provider.dart';
import '../theme/app_theme.dart';
import 'knowledge_screen.dart';

class ModelPipelineEditorScreen extends StatefulWidget {
  final String modelId;

  const ModelPipelineEditorScreen({super.key, required this.modelId});

  @override
  State<ModelPipelineEditorScreen> createState() => _ModelPipelineEditorScreenState();
}

class _ModelPipelineEditorScreenState extends State<ModelPipelineEditorScreen> {
  final TransformationController _transformController = TransformationController();
  final Map<int, double> _blockYOffsets = {};
  int? _selectedBlockIndex;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  double _getBlockY(int index, NeuralLayerBlock block) {
    if (_blockYOffsets.containsKey(index)) {
      return _blockYOffsets[index]!;
    }
    if (block.position.dy > 0) {
      return block.position.dy;
    }
    return 200.0;
  }

  void _shiftBlock(int index, double deltaY) {
    setState(() {
      final currentY = _blockYOffsets[index] ?? 200.0;
      _blockYOffsets[index] = (currentY + deltaY).clamp(40.0, 520.0);
    });
  }

  void _resetBlockY(int index) {
    setState(() {
      _blockYOffsets[index] = 200.0;
    });
  }

  void _alignAllBlocks() {
    setState(() {
      _blockYOffsets.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelProv = context.watch<ModelProvider>();
    final model = modelProv.models.firstWhere(
      (m) => m.id == widget.modelId,
      orElse: () => modelProv.activeModel,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.deepGreen, size: 22),
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        model.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: AppColors.deepGreen, size: 22),
                    onPressed: _resetZoom,
                    tooltip: 'Reset View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view_sharp, color: AppColors.deepGreen, size: 18),
                    onPressed: () => _showLayerSummaryModal(context, model),
                    tooltip: 'Architecture Summary',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: AppColors.deepGreen, size: 22),
                    onSelected: (val) {
                      if (val == 'export') _showExportNnModal(context, model);
                      if (val == 'pytorch') _showPyTorchModal(context, model);
                      if (val == 'add') _showAddLayerDialog(context, modelProv);
                      if (val == 'gemini') {
                        final prompt = 'Explain the computer vision architecture of ${model.name}. '
                            'Break down its layer tensor dimensions, how features are extracted, receptive fields, and historical significance.';
                        context.read<GeminiProvider>().askQuestion(question: prompt);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KnowledgeScreen(section: 'knowledge', initialTab: 1),
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'gemini',
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 18, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('Explain with Gemini AI'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download_rounded, size: 18, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('Export as .nn file'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pytorch',
                        child: Row(
                          children: [
                            Icon(Icons.code, size: 18, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('View PyTorch Code'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text('Add Layer Block'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [

          InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.4,
            maxScale: 2.2,
            child: SizedBox(
              width: math.max(1400.0, model.blocks.length * 205.0 + 100),
              height: 650,
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DotGridPainter(),
                    ),
                  ),

                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BlockWiresPainter(
                        blocks: model.blocks,
                        connections: model.connections,
                        yOffsets: _blockYOffsets,
                        baseY: 200.0,
                      ),
                    ),
                  ),

                  for (int i = 0; i < model.blocks.length; i++)
                    _buildPositionedBlock(context, model.blocks[i], i, modelProv),
                ],
              ),
            ),
          ),

          Positioned(
            left: 12,
            bottom: 12,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedBlockIndex != null && _selectedBlockIndex! < model.blocks.length) ...[
                        Text(
                          model.blocks[_selectedBlockIndex!].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 6),

                        InkWell(
                          onTap: () => _shiftBlock(_selectedBlockIndex!, -25),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_upward, size: 11, color: Color(0xFF0284C7)),
                                SizedBox(width: 2),
                                Text('Up', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        InkWell(
                          onTap: () => _shiftBlock(_selectedBlockIndex!, 25),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_downward, size: 11, color: Color(0xFF0284C7)),
                                SizedBox(width: 2),
                                Text('Down', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        InkWell(
                          onTap: () => _resetBlockY(_selectedBlockIndex!),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.refresh, size: 15, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const SizedBox(
                          height: 14,
                          child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(width: 6),
                      ],

                      InkWell(
                        onTap: _alignAllBlocks,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.horizontal_rule, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Align All',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        height: 14,
                        child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showAddLayerDialog(context, modelProv),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                            SizedBox(width: 3),
                            Text(
                              'Add Block',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        height: 14,
                        child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showExportNnModal(context, model),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.share, size: 13, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Share .nn',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildPositionedBlock(
    BuildContext context,
    NeuralLayerBlock block,
    int index,
    ModelProvider prov,
  ) {

    final double blockX = 40.0 + index * 215.0;
    final double blockY = _getBlockY(index, block);
    final bool isSelected = _selectedBlockIndex == index;
    final double yDelta = blockY - 200.0;

    Color headerColor;
    if (block.type == LayerBlockType.input) {
      headerColor = const Color(0xFF10B981);
    } else if (block.type == LayerBlockType.output) {
      headerColor = const Color(0xFFEC4899);
    } else {
      headerColor = const Color(0xFF0284C7);
    }

    return Positioned(
      left: blockX,
      top: blockY,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedBlockIndex = index);
        },
        onDoubleTap: () {
          setState(() => _selectedBlockIndex = index);
          _showBlockDetailSheet(context, block, index, prov);
        },
        onVerticalDragStart: (_) {
          setState(() => _selectedBlockIndex = index);
        },
        onVerticalDragUpdate: (details) {
          final scale = _transformController.value.getMaxScaleOnAxis();
          final effectiveScale = scale > 0.0 ? scale : 1.0;
          _shiftBlock(index, details.delta.dy / effectiveScale);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [

            if (isSelected)
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert, size: 10, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 3),
                        Text(
                          yDelta.abs() < 1 ? 'Aligned' : 'Y: ${yDelta > 0 ? '+${yDelta.toInt()}' : yDelta.toInt()}px',
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                        if (yDelta.abs() >= 1) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _resetBlockY(index),
                            child: const Icon(Icons.refresh, size: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            Container(
              width: 185,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? const Color(0x330284C7) : const Color(0x0C000000),
                    blurRadius: isSelected ? 10 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    child: Row(
                      children: [

                        const Icon(Icons.drag_indicator, size: 12, color: Colors.white70),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            block.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        GestureDetector(
                          onTap: () => _shiftBlock(index, -25),
                          child: const Icon(Icons.arrow_drop_up, size: 14, color: Colors.white),
                        ),

                        GestureDetector(
                          onTap: () => _shiftBlock(index, 25),
                          child: const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 2),

                        GestureDetector(
                          onTap: () => _showBlockDetailSheet(context, block, index, prov),
                          child: const Icon(Icons.info_outline, size: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 3),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            block.tensorShape,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        if (block.parameters.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Default pass-through', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                          )
                        else
                          for (final entry in block.parameters.entries.take(3)) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDetailSheet(
    BuildContext context,
    NeuralLayerBlock block,
    int index,
    ModelProvider prov,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.layers, size: 20, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            block.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Tensor Dimension: ${block.tensorShape}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              Text(
                block.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Layer Hyperparameters:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    for (final p in block.parameters.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            Text('${p.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (index > 0 && index < prov.activeModel.blocks.length - 1)
                OutlinedButton.icon(
                  onPressed: () {
                    prov.removeBlockFromActiveModel(index);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Delete Layer Block', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showLayerSummaryModal(BuildContext context, NeuralModelDefinition model) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${model.name} Layer Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.0),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                    children: [
                      Padding(padding: EdgeInsets.all(6), child: Text('Layer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(6), child: Text('Output Shape', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(6), child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  for (final b in model.blocks)
                    TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(6), child: Text(b.name, style: const TextStyle(fontSize: 10.5))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(b.tensorShape, style: const TextStyle(fontFamily: 'monospace', fontSize: 10))),
                        Padding(padding: const EdgeInsets.all(6), child: Text(b.type.name, style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7)))),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showExportNnModal(BuildContext context, NeuralModelDefinition model) {
    final String nnContent = model.toNnFileString();
    final int byteSize = nnContent.length;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.download, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Export .nn File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filename: ${model.id}.nn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Size: ${(byteSize / 1024).toStringAsFixed(2)} KB', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      nnContent,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: nnContent));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('Saved "${model.id}.nn" (${(byteSize / 1024).toStringAsFixed(2)} KB) to Clipboard!'),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
              label: const Text('Copy .nn String', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPyTorchModal(BuildContext context, NeuralModelDefinition model) {
    final String pyCode = model.toPyTorchCode();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Generated PyTorch Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Container(
              height: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: Text(
                  pyCode,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pyCode));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PyTorch code copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
              label: const Text('Copy Code', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddLayerDialog(BuildContext context, ModelProvider prov) {
    final nameController = TextEditingController(text: 'Conv2D');
    String selectedType = 'Conv2D';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Pipeline Layer Block', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Block Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Layer Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Conv2D', child: Text('Conv2D (Spatial Filter)')),
                      DropdownMenuItem(value: 'MaxPool', child: Text('MaxPool (Downsampling)')),
                      DropdownMenuItem(value: 'Dense', child: Text('Linear / Dense Layer')),
                      DropdownMenuItem(value: 'BatchNorm', child: Text('BatchNorm2d')),
                      DropdownMenuItem(value: 'Dropout', child: Text('Dropout (0.5)')),
                      DropdownMenuItem(value: 'Softmax', child: Text('Softmax Probability')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedType = val;
                          nameController.text = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final block = NeuralLayerBlock(
                      id: 'block_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      type: selectedType == 'Conv2D'
                          ? LayerBlockType.conv2d
                          : (selectedType == 'MaxPool' ? LayerBlockType.maxpool : LayerBlockType.linear),
                      tensorShape: '[N, 64, 14, 14]',
                      parameters: {'type': selectedType, 'channels': 64},
                      description: 'Custom added $selectedType layer block.',
                    );
                    prov.addBlockToActiveModel(block);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Block'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BlockWiresPainter extends CustomPainter {
  final List<NeuralLayerBlock> blocks;
  final List<List<int>> connections;
  final Map<int, double> yOffsets;
  final double baseY;

  _BlockWiresPainter({
    required this.blocks,
    required this.connections,
    required this.yOffsets,
    this.baseY = 200.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    for (final conn in connections) {
      final int fromIdx = conn[0];
      final int toIdx = conn[1];
      if (fromIdx >= blocks.length || toIdx >= blocks.length) continue;

      final double fromX = 40.0 + fromIdx * 215.0 + 185.0;
      final double fromBlockY = yOffsets[fromIdx] ?? (blocks[fromIdx].position.dy > 0 ? blocks[fromIdx].position.dy : baseY);
      final double fromY = fromBlockY + 14.0;

      final double toX = 40.0 + toIdx * 215.0;
      final double toBlockY = yOffsets[toIdx] ?? (blocks[toIdx].position.dy > 0 ? blocks[toIdx].position.dy : baseY);
      final double toY = toBlockY + 14.0;

      final path = Path();
      path.moveTo(fromX, fromY);
      final double midX = (fromX + toX) / 2;
      path.cubicTo(midX, fromY, midX, toY, toX, toY);

      canvas.drawPath(path, wirePaint);

      canvas.drawCircle(Offset(fromX, fromY), 3.5, dotPaint);
      canvas.drawCircle(Offset(toX, toY), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlockWiresPainter oldDelegate) => true;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
