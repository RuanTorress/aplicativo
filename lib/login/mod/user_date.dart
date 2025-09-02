class UserData {
  String? nome;
  String? email;
  String? senha;
  String? telefone;
  String? dataNascimento;

  UserData({
    this.nome,
    this.email,
    this.senha,
    this.telefone,
    this.dataNascimento,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
      'telefone': telefone,
      'dataNascimento': dataNascimento,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      nome: map['nome'],
      email: map['email'],
      senha: map['senha'],
      telefone: map['telefone'],
      dataNascimento: map['dataNascimento'],
    );
  }
}
