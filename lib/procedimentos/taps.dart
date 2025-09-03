import 'package:flutter/material.dart';
import 'procedimentos.dart';
import 'pacote.dart';

class ProcedimentosTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Procedimentos'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Lista'),
              Tab(text: 'Pacote/Combo'),
            ],
          ),
        ),
        body: TabBarView(children: [ProcedimentosScreen(), PacoteScreen()]),
      ),
    );
  }
}
