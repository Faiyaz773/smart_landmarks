import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'services/workmanager_service.dart';
import 'screens/map_screen.dart';
import 'screens/landmarks_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/add_view_screen.dart';

Future<void> initializeAppDependencies() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await WorkManagerService.init();
  } on MissingPluginException {
    // WorkManager is unavailable in unit tests and some desktop targets.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartLandmarksApp();
  }
}

class SmartLandmarksApp extends StatelessWidget {
  const SmartLandmarksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Geo-Tagged Landmarks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  final _screens = const [
    MapScreen(),
    LandmarksScreen(),
    ActivityScreen(),
    AddViewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.place), label: 'Landmarks'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.add_location_alt), label: 'Add/View'),
        ],
      ),
    );
  }
}
