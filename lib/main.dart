import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/gemini_provider.dart';
import 'presentation/providers/lab_provider.dart';
import 'presentation/providers/missions_provider.dart';
import 'presentation/providers/model_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const VisualNeuralNetworkLabApp());
}

class VisualNeuralNetworkLabApp extends StatelessWidget {
  final Widget? home;

  const VisualNeuralNetworkLabApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LabProvider()),
        ChangeNotifierProvider(create: (_) => MissionsProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
        ChangeNotifierProvider(create: (_) => GeminiProvider()),
      ],
      child: MaterialApp(
        title: 'Visual ML',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: home ?? const SplashScreen(),
      ),
    );
  }
}
