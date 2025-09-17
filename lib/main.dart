import 'package:check_in_point/providers/check_in_provider.dart';
import 'package:check_in_point/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import 'models/check_in_entry.dart';
import 'models/check_in_point.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters BEFORE opening boxes or reading data
  Hive.registerAdapter(CheckInPointAdapter());
  Hive.registerAdapter(CheckInEntryAdapter());

  final provider = CheckInProvider();
  await provider.loadFromHive();
  final box = await Hive.openBox('checkinBox');
  await box.clear();
// box to store point & check-ins
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
      ],
      child: MaterialApp(
        title: 'Check In Point App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home:HomeScreen()
      ),
    );
  }
}


