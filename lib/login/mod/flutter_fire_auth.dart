import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlutterFireAuth {
  late final BuildContext context;
  late final FirebaseAuth _auth;

  FlutterFireAuth(this.context) {
    _auth = FirebaseAuth.instance;
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preencha todos os campos!')));
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Usuário criado com sucesso!')));
    } catch (e) {
      print('Erro ao criar usuário: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar usuário: $e')));
    }
  }

  User? getLoggedInUser() {
    // Retorna o usuário atualmente logado (ou null)
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout realizado com sucesso!')));
    } catch (e) {
      print('Erro ao fazer logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('usuario não cadastrado fale com o administrador'),
        ),
      );
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preencha todos os campos!')));
      return false;
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login realizado com sucesso!')));
      return true;
    } catch (e) {
      String errorMsg = 'usuario não cadastrado fale com o administrador';
      if (e is FirebaseAuthException && e.code == 'user-disabled') {
        errorMsg = 'Usuário desativado. Procure o administrador.';
      }
      print(errorMsg);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
      return false;
    }
  }
}
