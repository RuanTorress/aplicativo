import 'package:altgest/navbar/main_screen.dart';
import 'package:altgest/estoque/estoque.dart';
import 'package:altgest/notas/notas.dart';
import 'package:altgest/rotina_diarias.dart/rotina_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa Hive para Web/Mobile
  await Hive.initFlutter();

  // Registra os adapters
  Hive.registerAdapter(ItemEstoqueAdapter());
  Hive.registerAdapter(NotaAdapter());

  // Abre as boxes (como se fossem tabelas)
  await Hive.openBox('procedimentos');
  await Hive.openBox('pacotes');
  await Hive.openBox('meuBanco');
  await Hive.openBox('caixaBanco');
  await Hive.openBox<ItemEstoque>('estoque');
  await Hive.openBox<Nota>('notas');
  await Hive.openBox('rotinas');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novo aplicativo teste',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routes: {
        '/main': (context) => MainScreen(),
        '/rotinas': (context) => RotinasPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MainScreen();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
