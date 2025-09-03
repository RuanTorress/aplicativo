import 'package:flutter/material.dart';
import 'package:altgest/homepage/home_page.dart';
import 'package:altgest/caixa/caixa.dart';
import 'package:altgest/procedimentos/taps.dart';
import 'package:altgest/estoque/estoque.dart';
import 'package:altgest/notas/notas.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    HomePage(),
    CaixaPage(),
    Center(child: Text('Perfil')),
    ProcedimentosTabs(),
    EstoquePage(),
    NotasPage(),
    Center(child: Text('Configurações')),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance
        .signOut()
        .then((_) {
          Navigator.of(context).pushReplacementNamed('/');
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao sair: $error')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _getAppBarTitle(),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
      ),
      drawer: _buildSideDrawer(context),
      body: _pages[_currentIndex],
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            selected: _currentIndex == 0,
            onTap: () {
              _onItemSelected(0);
              Navigator.pop(context); // Fecha o drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: Text('Caixa'),
            selected: _currentIndex == 1,
            onTap: () {
              _onItemSelected(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Perfil'),
            selected: _currentIndex == 2,
            onTap: () {
              _onItemSelected(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Procedimentos'),
            selected: _currentIndex == 3,
            onTap: () {
              _onItemSelected(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory),
            title: Text('Estoque'),
            selected: _currentIndex == 4,
            onTap: () {
              _onItemSelected(4);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.note),
            title: Text('Notas'),
            selected: _currentIndex == 5,
            onTap: () {
              _onItemSelected(5);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configurações'),
            selected: _currentIndex == 6,
            onTap: () {
              _onItemSelected(6);
              Navigator.pop(context);
            },
          ),
          Divider(), // Separator line
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return Text('AltGest - Home');
      case 1:
        return Text('AltGest - Caixa');
      case 2:
        return Text('AltGest - Perfil');
      case 3:
        return Text('AltGest - Procedimentos');
      case 4:
        return Text('AltGest - Estoque');
      case 5:
        return Text('AltGest - Notas');
      case 6:
        return Text('AltGest - Configurações');
      default:
        return Text('AltGest');
    }
  }
}
