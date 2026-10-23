import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/instrument_box.dart';
import 'knowledge_screen.dart';
import 'model_pipeline_editor_screen.dart';

class ModelHubScreen extends StatefulWidget {
  const ModelHubScreen({super.key});

  @override
  State<ModelHubScreen> createState() => _ModelHubScreenState();
}

class _ModelHubScreenState extends State<ModelHubScreen> {

  void _openModelEditor(BuildContext context, String modelId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelPipelineEditorScreen(modelId: modelId),
      ),
    );
  }

  void _createNewModel(BuildContext context, ModelProvider prov) {
    final controller = TextEditingController(text: 'My Custom Net');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Architecture Name',
              hintText: 'e.g. MiniVGG, ResNet-Custom',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: () {
                final name = controller.text.trim().isEmpty ? 'My Custom Net' : controller.text.trim();
                final newId = prov.createCustomModel(name: name);
                Navigator.pop(ctx);
                _openModelEditor(context, newId);
              },
              child: const Text('Create & Edit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _importNnDialog(BuildContext context, ModelProvider prov) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.file_upload_outlined, color: AppColors.deepGreen),
              SizedBox(width: 8),
              Text('Import .nn File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste the raw JSON content of a .nn model file below:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  hintText: '{\n  "format": "visual_neural_network_lab.nn",\n  ...\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: () {
                final success = prov.importNnFile(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.green : Colors.red,
                    content: Text(success ? 'Model successfully imported!' : 'Invalid .nn file format.'),
                  ),
                );
              },
              child: const Text('Import', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showModelInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Model Architecture Studio', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Explore landmark Computer Vision architectures (LeNet-5, AlexNet, VGGNet, GoogLeNet, ResNet). '
            'Inspect layer tensor dimensions, export/import portable .nn model files, and simulate vision training benchmarks.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.deepGreen),
              label: const Text('Ask Gemini AI', style: TextStyle(color: AppColors.deepGreen)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KnowledgeScreen(section: 'knowledge', initialTab: 1),
                  ),
                );
              },
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProv = context.watch<ModelProvider>();

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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'Model Studio',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.file_upload_outlined, color: AppColors.deepGreen),
                    tooltip: 'Import .nn File',
                    onPressed: () => _importNnDialog(context, modelProv),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.info_outline, color: AppColors.deepGreen),
                    tooltip: 'Information',
                    onPressed: () => _showModelInfoDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              InstrumentBox(
                title: 'Models',
                titleColor: AppColors.deepGreen,
                borderColor: AppColors.green,
                titleBoxColor: Colors.white,
                titleFontSize: 13.5,
                borderWidth: 1.2,
                borderRadius: 12.0,
                contentPadding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                margin: const EdgeInsets.only(bottom: 22),
                child: _buildModelGridView(modelProv),
              ),

              InstrumentBox(
                title: 'Training',
                titleColor: AppColors.deepGreen,
                borderColor: AppColors.green,
                titleBoxColor: Colors.white,
                titleFontSize: 13.5,
                borderWidth: 1.2,
                borderRadius: 12.0,
                contentPadding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                margin: const EdgeInsets.only(bottom: 20),
                child: _buildTrainingContent(modelProv),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelGridView(ModelProvider prov) {
    final models = prov.models;

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth < 460
            ? 2
            : constraints.maxWidth < 720
                ? 3
                : 4;
        final double childAspectRatio = constraints.maxWidth < 460 ? 0.86 : 0.92;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: 1 + models.length,
          itemBuilder: (context, index) {
            if (index == 0) {

              return InstrumentBox(
                title: 'New Model',
                borderColor: AppColors.greenBorder,
                titleColor: AppColors.deepGreen,
                titleBoxColor: Colors.white,
                titleFontSize: 11.0,
                margin: EdgeInsets.zero,
                contentPadding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                onTap: () => _createNewModel(context, prov),
                child: const Center(
                  child: Icon(Icons.add_circle_outline_rounded, size: 38, color: AppColors.green),
                ),
              );
            }

            final model = models[index - 1];
            final bool isPink = model.category == 'Vision' || index % 3 == 0;
            final bool isGreen = model.category == 'Sequence' || index % 3 == 1;
            final Color cardBorder = isPink
                ? AppColors.pinkBorder
                : (isGreen ? AppColors.greenBorder : AppColors.blueBorder);
            final Color cardTitle = isPink
                ? AppColors.darkPink
                : (isGreen ? AppColors.deepGreen : AppColors.primaryBlue);
            final Color badgeColor = isPink
                ? AppColors.pink
                : (isGreen ? AppColors.green : AppColors.primaryBlue);

            return InstrumentBox(
              title: model.name,
              borderColor: cardBorder,
              titleColor: cardTitle,
              titleBoxColor: Colors.white,
              titleFontSize: 11.0,
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
              onTap: () => _openModelEditor(context, model.id),
              child: Stack(
                children: [
                  Center(
                    child: CustomPaint(
                      size: const Size(60, 60),
                      painter: _ModelCardThumbnailPainter(),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        model.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrainingContent(ModelProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BENCHMARK CONFIGURATION',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: prov.selectedModelId,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: prov.models
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) prov.selectModel(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: prov.activeDataset,
                      decoration: const InputDecoration(
                        labelText: 'Dataset',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: prov.datasets
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) prov.setActiveDataset(val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'ACCURACY',
                value: '${prov.currentAccuracy.toStringAsFixed(1)}%',
                color: AppColors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'LOSS',
                value: prov.currentLoss.toStringAsFixed(3),
                color: AppColors.primaryBlue,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'EPOCH',
                value: '${prov.currentEpoch}',
                color: AppColors.pink,
                icon: Icons.history,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          height: 105,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Loss & Convergence Sparkline',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Params: ~${prov.activeModel.parameterCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: CustomPaint(
                  painter: _LossCurvePainter(history: prov.lossHistory),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEST SAMPLE PREDICTIONS (MINI-BATCH)',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in prov.samplePredictions)
                    Container(
                      width: 68,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item['isCorrect'] as bool ? AppColors.green : const Color(0xFFEF4444),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${item['digit']}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pred: ${item['predicted']}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: item['isCorrect'] as bool ? AppColors.green : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay, size: 26, color: AppColors.textSecondary),
              tooltip: 'Reset Training',
              onPressed: prov.resetTraining,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: prov.toggleTraining,
              icon: Icon(prov.isTraining ? Icons.pause : Icons.play_arrow, size: 22),
              label: Text(
                prov.isTraining ? 'Pause Simulation' : 'Run Benchmark',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 26, color: AppColors.textSecondary),
              tooltip: 'Step 1 Epoch',
              onPressed: prov.stepTraining,
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ModelCardThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final pinkNode = Paint()..color = AppColors.pink..style = PaintingStyle.fill;
    final greenNode = Paint()..color = AppColors.green..style = PaintingStyle.fill;
    final blueLightNode = Paint()..color = AppColors.blueBorder..style = PaintingStyle.fill;
    final blueDarkNode = Paint()..color = AppColors.primaryBlue..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 1.5..style = PaintingStyle.stroke;

    final Offset n1 = Offset(size.width * 0.22, size.height * 0.30);
    final Offset n2 = Offset(size.width * 0.22, size.height * 0.70);
    final Offset n3 = Offset(size.width * 0.48, size.height * 0.18);
    final Offset n4 = Offset(size.width * 0.48, size.height * 0.50);
    final Offset n5 = Offset(size.width * 0.48, size.height * 0.82);
    final Offset n6 = Offset(size.width * 0.80, size.height * 0.45);

    canvas.drawLine(n1, n3, edgePaint);
    canvas.drawLine(n1, n4, edgePaint);
    canvas.drawLine(n2, n4, edgePaint);
    canvas.drawLine(n2, n5, edgePaint);
    canvas.drawLine(n3, n6, edgePaint);
    canvas.drawLine(n4, n6, edgePaint);
    canvas.drawLine(n5, n6, edgePaint);

    void drawNode(Offset pos, Paint p, double r) {
      canvas.drawCircle(pos, r, p);
      canvas.drawCircle(pos, r, borderPaint);
    }

    drawNode(n1, pinkNode, 8);
    drawNode(n2, pinkNode, 8);
    drawNode(n3, greenNode, 8);
    drawNode(n4, blueLightNode, 9);
    drawNode(n5, greenNode, 8);
    drawNode(n6, blueDarkNode, 9);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LossCurvePainter extends CustomPainter {
  final List<double> history;

  _LossCurvePainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0284C7).withValues(alpha: 0.3), const Color(0xFF0284C7).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (history.length > 1 ? (history.length - 1) : 1);
    for (int i = 0; i < history.length; i++) {
      final double norm = (history[i] / 2.5).clamp(0.0, 1.0);
      final double y = size.height * (1.0 - (1.0 - norm));
      final double x = i * stepX;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LossCurvePainter oldDelegate) => true;
}
