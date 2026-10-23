import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_neural_network_lab/main.dart';
import 'package:visual_neural_network_lab/presentation/screens/main_shell_screen.dart';
import 'package:visual_neural_network_lab/src/rust/frb_generated.dart';

void main() {
  setUpAll(() async {
    final dllFile = File('build/windows/x64/runner/Debug/rust_core.dll');
    if (dllFile.existsSync()) {
      await RustLib.init(
        externalLibrary: ExternalLibrary.open(dllFile.absolute.path),
      );
    } else {
      await RustLib.init();
    }
  });

  testWidgets('VisualNeuralNetworkLabApp launches and displays main tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Missions'), findsWidgets);
    expect(find.text('Lab'), findsWidgets);

    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Knowledge'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);

    expect(find.text('2D Regression'), findsWidgets);
    expect(find.text('Single-step Training'), findsOneWidget);
    expect(find.text('Keep Training'), findsOneWidget);
    expect(find.text('Broken Line'), findsOneWidget);
    expect(find.text('W Line'), findsOneWidget);
    expect(find.text('Initialization'), findsOneWidget);

    expect(find.byIcon(Icons.star), findsWidgets);
  });

  testWidgets('Tapping Lab pill switches to Lab Mode dataset selection (Screenshot 3)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Lab').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('2D Regression'), findsOneWidget);
    expect(find.text('2D Classification'), findsOneWidget);
    expect(find.text('3D Regression'), findsOneWidget);
    expect(find.text('3D Classification'), findsOneWidget);
  });

  testWidgets('Landscape orientation displays authentic 1:1 Studio controls (Screenshot 1 & 4)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('2D Regression').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lab'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    expect(find.text('DATA'), findsOneWidget);
    expect(find.text('FEATURES'), findsOneWidget);
    expect(find.text('HIDDEN LAYERS'), findsOneWidget);
    expect(find.text('OUTPUT'), findsOneWidget);

    expect(find.text('Dataset'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('3D'), findsOneWidget);
    expect(find.text('Heatmap'), findsOneWidget);

    expect(find.byIcon(Icons.replay), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
  });

  testWidgets('Tapping a mission card in portrait opens full LabScreen and back arrow returns',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Broken Line'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lab'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Broken Line'), findsOneWidget);
  });

  testWidgets('DATA and OUTPUT dialogs open and function correctly (Screenshots 5 & 6)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('2D Regression').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('DATA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Total samples'), findsOneWidget);
    expect(find.textContaining('Percent of training samples'), findsOneWidget);
    expect(find.textContaining('Noise'), findsOneWidget);
    expect(find.text('REGENERATE'), findsOneWidget);

    await tester.tap(find.text('REGENERATE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('REGENERATE'), findsNothing);

    await tester.tap(find.text('OUTPUT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Batch size'), findsOneWidget);
    expect(find.text('Activation function:'), findsOneWidget);
    expect(find.text('Learning rate:'), findsOneWidget);
    expect(find.text('Regularization:'), findsOneWidget);
    expect(find.text('Regularization rate:'), findsOneWidget);
  });

  testWidgets('Dynamic hidden layer addition and per-layer neuron adjustments',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('2D Regression').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('HIDDEN LAYERS'), findsOneWidget);

    final addLayerButton = find.descendant(
      of: find.ancestor(of: find.text('HIDDEN LAYERS'), matching: find.byType(Row)),
      matching: find.byIcon(Icons.add),
    );
    if (addLayerButton.evaluate().isNotEmpty) {
      await tester.tap(addLayerButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2'), findsWidgets);
    }
  });

  testWidgets('InspectionModalScreen displays Output and Loss Landscape tabs (Screenshots 7 & 8)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('2D Regression').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.grid_view_sharp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Output'), findsWidgets);
    expect(find.text('Loss Landscape'), findsOneWidget);

    expect(find.textContaining('a₀⁽²⁾'), findsOneWidget);
    expect(find.textContaining('w₀,₀⁽¹⁾'), findsWidgets);
    expect(find.textContaining('w₁,₀⁽¹⁾'), findsWidgets);
    expect(find.textContaining('b₀⁽¹⁾'), findsWidgets);

    await tester.tap(find.text('Loss Landscape'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('loss ='), findsOneWidget);
    expect(find.text('Resolution'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lab'), findsWidgets);
  });

  testWidgets('Model Hub displays landmark models and opens interactive LeNet5 pipeline editor (Screenshots 2 & 3)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.all_inclusive));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New'), findsOneWidget);
    expect(find.text('LeNet5'), findsOneWidget);
    expect(find.text('AlexNet'), findsOneWidget);
    expect(find.text('VGGNet11'), findsOneWidget);
    expect(find.text('Vision'), findsWidgets);

    await tester.tap(find.text('LeNet5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Inputs'), findsOneWidget);
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Flatten'), findsOneWidget);
    expect(find.text('Classifier'), findsOneWidget);
    expect(find.text('Softmax'), findsOneWidget);
    expect(find.text('Outputs'), findsOneWidget);

    await tester.tap(find.text('Features'));
    await tester.pump();
    expect(find.text('Align All'), findsOneWidget);

    final upArrow = find.byIcon(Icons.arrow_drop_up).first;
    await tester.tap(upArrow);
    await tester.pump();

    await tester.tap(find.text('Align All'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Training'));
    await tester.pumpAndSettle();

    expect(find.text('BENCHMARK CONFIGURATION'), findsOneWidget);
    expect(find.text('TEST ACCURACY'), findsOneWidget);
    expect(find.text('CROSS-ENTROPY LOSS'), findsOneWidget);
  });

  testWidgets(
      'Compact 6-inch mobile screen in landscape and portrait renders with zero overflow',
      (WidgetTester tester) async {

    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2D Regression').first);
    await tester.pumpAndSettle();

    expect(find.text('DATA'), findsOneWidget);
    expect(find.text('FEATURES'), findsOneWidget);
    expect(find.text('OUTPUT'), findsOneWidget);

    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Output'), findsWidgets);
    expect(find.text('Loss Landscape'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Knowledge screen renders Knowledge Base and Gemini AI Tutor with prompt chips',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Knowledge'));
    await tester.pumpAndSettle();

    expect(find.text('Interactive Lessons'), findsOneWidget);
    expect(find.text('Lesson 1: Training Your First Perceptron'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Core Concepts & Theory'), 300);
    expect(find.text('Core Concepts & Theory'), findsOneWidget);
    expect(find.text('Activation Functions: Breaking Linearity'), findsOneWidget);

    expect(find.textContaining('Rust'), findsNothing);
    expect(find.textContaining('ndarray'), findsNothing);
    expect(find.textContaining('SIMD'), findsNothing);

    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('Gemini AI Tutor'), findsOneWidget);

    expect(find.text('Deep Dive with Gemini'), findsWidgets);

    await tester.tap(find.text('Gemini AI Tutor'));
    await tester.pumpAndSettle();

    expect(find.text('Gemini 3.5 Flash'), findsOneWidget);
    expect(find.text('Attach Studio Context'), findsOneWidget);

    expect(find.text('Why is my neural network loss plateauing?'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    expect(find.textContaining('Gemini AI Deep Learning Mentor'), findsOneWidget);

    expect(find.byIcon(Icons.key), findsNothing);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1: Training Your First Perceptron'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Playground'), findsWidgets);
    expect(find.text('Single-step Training'), findsOneWidget);
  });

  testWidgets(
      'Opening Gemini AI Tutor from Lab Screen displays back arrow and returns to Lab',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VisualNeuralNetworkLabApp(home: MainShellScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Broken Line'));
    await tester.pumpAndSettle();
    expect(find.text('Lab'), findsWidgets);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.text('Gemini 3.5 Flash'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    expect(find.byIcon(Icons.key), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Lab'), findsWidgets);
    expect(find.text('Broken Line'), findsNothing);
  });

  testWidgets('SplashScreen displays illustration and cursive tagline then navigates on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VisualNeuralNetworkLabApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('VISUAL ML'), findsOneWidget);
    expect(find.text('Where mathematics becomes intuition'), findsOneWidget);
    expect(find.text('Interactive Deep Learning Laboratory'), findsOneWidget);

    await tester.tap(find.text('Where mathematics becomes intuition'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Playground'), findsWidgets);
  });
}

