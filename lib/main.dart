import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/models/chat_message.dart';
import 'data/models/chat_session.dart';
import 'data/models/model_info.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MessageRoleAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ChatMessageAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ChatSessionAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ModelInfoAdapter());

  // Open Hive boxes
  await Hive.openBox<ChatSession>('chat_sessions');

  runApp(const LocalLlmApp());
}

class LocalLlmApp extends StatelessWidget {
  const LocalLlmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Local LLM Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          // Global error boundary widget
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          );
        },
      ),
    );
  }
}
