import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/lab_provider.dart';
import '../theme/app_theme.dart';
import '../../data/services/gemini_service.dart';

class KnowledgeScreen extends StatefulWidget {
  final String section;
  final int initialTab;
  final VoidCallback? onBack;

  const KnowledgeScreen({
    super.key,
    this.section = 'all',
    this.initialTab = 0,
    this.onBack,
  });

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {

  late int _activeTab;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  final List<String> _quickPrompts = [
    'Why is my neural network loss plateauing?',
    'Explain how Backpropagation uses the chain rule',
    'What is the difference between ReLU, Tanh, and Sigmoid?',
    'How does L1 vs L2 regularization prevent overfitting?',
    'How do Convolutional kernels work in LeNet-5 & ResNet?',
    'What does the 3D loss landscape represent?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _handleBack() {

    if (_activeTab == 1 && widget.initialTab == 0) {
      setState(() => _activeTab = 0);
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    if (_activeTab == 1) {
      setState(() => _activeTab = 0);
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildLiveLabContext(LabProvider lab) {
    final state = lab.state;
    final layersStr = state.hiddenLayerNeurons.isNotEmpty
        ? state.hiddenLayerNeurons.map((n) => '$n neurons').join(', ')
        : 'None (Direct Perceptron)';

    return '''
Dataset: ${state.datasetType}
Task Type: ${state.problemType}
Current Epoch: ${state.currentEpoch}
Training Loss: ${state.trainLoss.toStringAsFixed(4)}
Test Loss: ${state.testLoss.toStringAsFixed(4)}
Training Accuracy: ${(state.trainAccuracy * 100).toStringAsFixed(1)}%
Learning Rate: ${state.learningRate}
Global Activation: ${state.activation}
Regularization: ${state.regularization} (Rate: ${state.regRate})
Hidden Layers Architecture: [$layersStr]
Status: ${state.isTraining ? 'Actively Training' : 'Paused / Idle'}
''';
  }

  void _submitQuestion(String text) {
    if (text.trim().isEmpty) return;
    final gemini = context.read<GeminiProvider>();
    final lab = context.read<LabProvider>();

    final liveContext = _buildLiveLabContext(lab);
    _inputController.clear();
    gemini.askQuestion(question: text, liveContext: liveContext).then((_) {
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _triggerDeepDive(String topicTitle) {
    setState(() => _activeTab = 1);
    final gemini = context.read<GeminiProvider>();
    final lab = context.read<LabProvider>();
    final liveContext = _buildLiveLabContext(lab);

    gemini.deepDiveTopic(topicTitle, liveContext: liveContext).then((_) {
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final gemini = context.watch<GeminiProvider>();
    final lab = context.watch<LabProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.deepGreen, size: 22),
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: _handleBack,
                  ),

                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.softGreen,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.greenBorderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopPill(
                                title: 'Articles',
                                icon: Icons.article_outlined,
                                isSelected: _activeTab == 0,
                                onTap: () => setState(() => _activeTab = 0),
                              ),
                              _buildTopPill(
                                title: 'Gemini AI Tutor',
                                icon: Icons.auto_awesome,
                                isSelected: _activeTab == 1,
                                onTap: () => setState(() => _activeTab = 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 36),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            Expanded(
              child: _activeTab == 0
                  ? _buildCuratedArticlesView()
                  : _buildGeminiTutorView(gemini, lab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratedArticlesView() {
    if (widget.section == 'tutorials') {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildTutorialCards(),
      );
    }
    if (widget.section == 'knowledge') {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: _buildKnowledgeCards(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader('Interactive Lessons', Icons.school_outlined),
        const SizedBox(height: 8),
        ..._buildTutorialCards(),
        const SizedBox(height: 18),
        _buildSectionHeader('Core Concepts & Theory', Icons.menu_book_outlined),
        const SizedBox(height: 8),
        ..._buildKnowledgeCards(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKnowledgeCards() {
    return [
      _buildArticleCard(
        title: 'Activation Functions: Breaking Linearity',
        tag: 'CORE MATH',
        tagColor: AppColors.primaryBlue,
        formula: 'f(z) = max(0, z) [ReLU]  |  tanh(z) = (eᶻ - e⁻ᶻ)/(eᶻ + e⁻ᶻ)',
        content:
            'Without non-linear activations, stacking multiple dense layers collapses mathematically into a single linear matrix multiplication. ReLU avoids vanishing gradients in deep networks, while Tanh is zero-centered.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Backpropagation & Gradient Descent',
        tag: 'OPTIMIZATION',
        tagColor: AppColors.green,
        formula: '∂L/∂wᵢⱼ = δⱼ · aᵢ ,   δⱼ = ∂L/∂zⱼ',
        content:
            'Backpropagation applies the calculus chain rule recursively backward from the loss layer to the input layer, computing exact parameter gradients so gradient descent can iteratively update weights to minimize prediction error.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Loss Landscapes & Gradient Descent Topology',
        tag: '3D GEOMETRY',
        tagColor: AppColors.pink,
        formula: 'L(w) = (1/N) ∑ (ŷᵢ - yᵢ)²',
        content:
            'The loss landscape is an N-dimensional hyper-surface where coordinates are parameter weights and elevation is error loss. Visualizing 2D slices shows convex valleys, saddle points, and local minima.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Regularization: Taming Overfitting',
        tag: 'GENERALIZATION',
        tagColor: AppColors.green,
        formula: 'L_reg = L₀ + λ ∑ ||w||²  [L2 Weight Decay]',
        content:
            'When network capacity exceeds dataset complexity, weights grow excessively large to memorize noise. L2 penalizes large weights proportionally, yielding smooth, generalized decision boundaries.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Convolutional Kernels & Feature Hierarchies',
        tag: 'COMPUTER VISION',
        tagColor: AppColors.primaryBlue,
        formula: '(I * K)(i, j) = ∑ₘ ∑ₙ I(i-m, j-n) K(m, n)',
        content:
            'Convolutions use shared weight kernels to scan localized 2D spatial receptive fields, detecting edges, textures, and object parts invariantly across shifts in image space.',
      ),
    ];
  }

  List<Widget> _buildTutorialCards() {
    return [
      _buildArticleCard(
        title: 'Lesson 1: Training Your First Perceptron',
        tag: 'BEGINNER',
        tagColor: AppColors.primaryBlue,
        formula: 'ŷ = σ(w₁ x₁ + w₂ x₂ + b)',
        content:
            'Go to the Lab, select the Linear dataset, configure 1 hidden layer with 2 neurons, and press Train. Watch the blue decision line cleanly divide the two clusters in under 20 epochs.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Lesson 2: Beating the XOR Paradox',
        tag: 'INTERMEDIATE',
        tagColor: AppColors.green,
        formula: 'XOR(x₁, x₂) = (x₁ ∨ x₂) ∧ ¬(x₁ ∧ x₂)',
        content:
            'A single straight line cannot separate opposite corners. Switch to the XOR dataset, add 4 hidden neurons with Tanh activation, and observe how the neurons collaborate to form a curved boundary.',
      ),
      const SizedBox(height: 12),
      _buildArticleCard(
        title: 'Lesson 3: Navigating the 3D Loss Valley',
        tag: 'ADVANCED',
        tagColor: AppColors.pink,
        formula: 'w_{t+1} = w_t - η ∇L + β v_t',
        content:
            'Toggle the Output tab to "3D Landscape". Touch and drag to rotate the 3D topology. Watch the glowing ball roll down the mountain into the blue valley as the loss approaches zero.',
      ),
    ];
  }

  Widget _buildArticleCard({
    required String title,
    required String tag,
    required Color tagColor,
    required String formula,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          Padding(
            padding: const EdgeInsets.only(top: 22, left: 14, right: 14, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    formula,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => _triggerDeepDive(title),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blueBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome, size: 12, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Deep Dive with Gemini',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 1,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tagColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: tagColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiTutorView(GeminiProvider gemini, LabProvider lab) {
    return Column(
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppColors.background,
          child: Row(
            children: [

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.blueBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome, size: 12, color: AppColors.primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'Gemini 3.5 Flash',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: InkWell(
                  onTap: gemini.toggleLiveContext,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gemini.isLiveContextEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 15,
                          color: gemini.isLiveContextEnabled ? AppColors.green : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Attach Studio Context',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                tooltip: 'Clear Chat',
                onPressed: gemini.clearChat,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Container(
          height: 38,
          color: Colors.white,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return InkWell(
                onTap: () => _submitQuestion(prompt),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.blueBorder),
                  ),
                  child: Center(
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: gemini.messages.length + (gemini.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == gemini.messages.length && gemini.isLoading) {

                return _buildThinkingBubble();
              }
              final message = gemini.messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _submitQuestion(val),
                    decoration: const InputDecoration(
                      hintText: 'Ask Gemini about neural nets or your lab...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: gemini.isLoading
                    ? null
                    : () => _submitQuestion(_inputController.text),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: gemini.isLoading ? AppColors.textMuted : AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(GeminiMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(2)),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isError ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(topLeft: const Radius.circular(2)),
          border: Border.all(
            color: message.isError ? const Color(0xFFFCA5A5) : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: message.isError ? const Color(0xFFDC2626) : AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isError ? 'Gemini Error' : 'Gemini AI Tutor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: message.isError ? const Color(0xFFDC2626) : AppColors.primaryBlue,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied response to clipboard!'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy, size: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            message.isError
                ? SelectableText(
                    message.text,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(fontSize: 12.5, height: 1.48, color: Color(0xFF1E293B)),
                      h1: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      h2: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      h3: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      h4: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      em: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        backgroundColor: AppColors.softBlue,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      codeblockPadding: const EdgeInsets.all(10),
                      listBullet: const TextStyle(fontSize: 12.5, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      horizontalRuleDecoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(topLeft: const Radius.circular(2)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
            SizedBox(width: 8),
            Text(
              'Gemini is analyzing and formulating explanation...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
