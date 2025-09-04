import 'package:flutter/material.dart';
import 'procedimentos.dart';
import 'pacote.dart';

class ProcedimentosTabs extends StatelessWidget {
  const ProcedimentosTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent[700]
        : Colors.indigo[700];
    final backgroundColor = isDarkMode ? Color(0xFF1E1E28) : Colors.grey[50];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading:
              false, // Remove a seta de voltar automática
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Meus ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Serviços',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ...existing code...
          bottom: TabBar(
            labelColor: Colors.white, // Cor do texto da tab selecionada
            unselectedLabelColor:
                Colors.white70, // Cor do texto da tab não selecionada
            indicatorColor:
                Colors.greenAccent, // Cor do indicador da tab selecionada
            indicatorWeight: 3.0, // Espessura do indicador
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs: [
              Tab(text: 'Lista'),
              Tab(text: 'Pacote/Combo'),
            ],
          ),
          // ...existing code...,
        ),
        body: TabBarView(children: [ProcedimentosScreen(), PacoteScreen()]),
      ),
    );
  }
}
