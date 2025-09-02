import 'package:flutter/material.dart';
import 'package:altgest/homepage/home_page.dart';
import 'package:altgest/caixa/caixa.dart';

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
    Center(child: Text('Perfil')), // Substitua pelo widget de perfil
    Center(
      child: Text('Notificações'),
    ), // Substitua pelo widget de notificações
    Center(
      child: Text('Configurações'),
    ), // Substitua pelo widget de configurações
  ];

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
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
            title: Text('Notificações'),
            selected: _currentIndex == 3,
            onTap: () {
              _onItemSelected(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configurações'),
            selected: _currentIndex == 4,
            onTap: () {
              _onItemSelected(4);
              Navigator.pop(context);
            },
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
        return Text('AltGest - Notificações');
      case 4:
        return Text('AltGest - Configurações');
      default:
        return Text('AltGest');
    }
  }
}
