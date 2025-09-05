import 'package:altgest/caledario/calendario_view.dart';
import 'package:altgest/home_inicio/home.dart';
import 'package:altgest/navbar/alertas.dart';
import 'package:altgest/navbar/saida.dart';
import 'package:altgest/servico/taps.dart';
import 'package:flutter/material.dart';
import 'package:altgest/caixa/caixa.dart';
import 'package:altgest/estoque/estoque.dart';
import 'package:altgest/notas/notas_page.dart';
import 'package:altgest/rotina_diarias.dart/rotina_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  final List<Widget> _pages = [
    HomePage(),
    CaixaPage(),
    ProcedimentosTabs(),
    EstoquePage(),
    NotasPage(),
    RotinasPage(),
    CalendarioAgendamentosPage(),
    Center(child: Text('Configurações')),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'title': 'Inicio', 'index': 0},
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Caixa',
      'index': 1,
    },
    {'icon': Icons.medical_services_rounded, 'title': 'Serviços', 'index': 2},
    {'icon': Icons.inventory_2_rounded, 'title': 'Estoque', 'index': 3},
    {'icon': Icons.description_rounded, 'title': 'Notas', 'index': 4},
    {'icon': Icons.event_note_rounded, 'title': 'Rotinas', 'index': 5},
    {
      'icon': Icons.calendar_month_rounded,
      'title': 'Calendário',
      'index': 6,
    }, // <-- Adicione aqui
  ];

  final List<Map<String, dynamic>> _bottomMenuItems = [
    {'icon': Icons.settings_rounded, 'title': 'Configurações', 'index': 6},
    {'icon': Icons.help_outline_rounded, 'title': 'Ajuda', 'action': 'help'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final scaffoldBackgroundColor = isDarkMode
        ? Color(0xFF1E1E28)
        : Colors.grey[50];
    final appBarColor = isDarkMode ? Color(0xFF1E1E28) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: _getAppBarTitle(),
        elevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => AlertasPage.openAlertas(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor?.withOpacity(0.2),
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildSideDrawer(context),
      body: _pages[_currentIndex],
    );
  }

  Widget _buildSideDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];

    // User info - you can replace with actual user data
    final String userName = "Dev Ruan Torres";
    final String userEmail = "ruanfabio59@email.com";

    return Drawer(
      backgroundColor: isDarkMode ? Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: <Widget>[
          // User Profile Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [?primaryColor?.withOpacity(0.8), ?primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor!.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Text(
                        userName.substring(0, 2).toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Administrador",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    "MENU PRINCIPAL",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ..._menuItems.map(
                  (item) => _buildMenuItem(
                    icon: item['icon'],
                    title: item['title'],
                    isSelected: _currentIndex == item['index'],
                    onTap: () => _onItemSelected(item['index']),
                  ),
                ),

                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    "CONFIGURAÇÕES",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ..._bottomMenuItems.map(
                  (item) => _buildMenuItem(
                    icon: item['icon'],
                    title: item['title'],
                    isSelected:
                        item['index'] != null && _currentIndex == item['index'],
                    onTap: () {
                      if (item['action'] == 'help') {
                        Navigator.pop(context);
                        // Abrir página de ajuda
                      } else if (item['index'] != null) {
                        _onItemSelected(item['index']);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Logout Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              onTap: () => SaidaHelper.logout(context), // Mudança aqui
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red[700]),
                  SizedBox(width: 16),
                  Text(
                    'Sair do Aplicativo',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.2)
                      : isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[200]!,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? primaryColor
                      : isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[700],
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : isDarkMode
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey[800],
                ),
              ),
              if (isSelected) ...[
                Spacer(),
                Container(
                  width: 5,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getAppBarTitle() {
    final theme = Theme.of(context);
    final appName = "AltGest";
    String pageTitle;

    switch (_currentIndex) {
      case 0:
        pageTitle = 'Inicio';
        break;
      case 1:
        pageTitle = 'Caixa';
        break;
      case 2:
        pageTitle = 'Serviços';
        break;
      case 3:
        pageTitle = 'Estoque';
        break;
      case 4:
        pageTitle = 'Notas';
        break;
      case 5:
        pageTitle = 'Rotinas';
        break;
      case 6:
        pageTitle = 'Calendário'; // <-- Adicione aqui
        break;
      case 7:
        pageTitle = 'Configurações';
        break;
      default:
        pageTitle = '';
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: appName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          TextSpan(
            text: " | ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w300,
              color: Colors.grey,
            ),
          ),
          TextSpan(
            text: pageTitle,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
