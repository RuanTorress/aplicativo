import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo ou ícone (opcional)
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: Icon(
                Icons.business_center,
                size: 80,
                color: Colors.blue[700],
              ),
            ),

            // Nome do aplicativo
            Text(
              'altGest',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: 2,
              ),
            ),

            // Espaçamento
            const SizedBox(height: 20),

            // Subtítulo
            Text(
              'Alternativa de gestão do dia',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Espaçamento adicional
            const SizedBox(height: 50),

            // Botão de ação (opcional)
            ElevatedButton(
              onPressed: () {
                // Navegação para próxima tela
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Começar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
