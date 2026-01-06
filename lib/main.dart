import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/media_provider.dart';
import 'services/upload_provider.dart';
import 'views/main_screen.dart';

void main() async {
  // Initialiser les locales pour DateFormat
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MediaProvider()),
        ChangeNotifierProvider(create: (context) => UploadProvider()),
      ],
      child: MaterialApp(
        title: 'NDLS Gallery',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563eb)),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
