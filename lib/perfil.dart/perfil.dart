import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:altgest/login/mod/flutter_fire_auth.dart';
import 'package:altgest/login/mod/user_date.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/services.dart'; // Para TextInputFormatter

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> with TickerProviderStateMixin {
  User? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _saving = false;
  File? _profileImage;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();

  late Box _userBox;
  final ImagePicker _picker = ImagePicker();

  // Adicione estes formatadores
  final TextInputFormatter _phoneFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    ); // Remove não-dígitos
    if (text.length <= 11) {
      if (text.length <= 2) {
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } else if (text.length <= 6) {
        return TextEditingValue(
          text: '(${text.substring(0, 2)}) ${text.substring(2)}',
          selection: TextSelection.collapsed(offset: text.length + 4),
        );
      } else {
        return TextEditingValue(
          text:
              '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7)}',
          selection: TextSelection.collapsed(offset: text.length + 5),
        );
      }
    }
    return oldValue;
  });

  final TextInputFormatter _dateFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    ); // Remove não-dígitos
    if (text.length <= 8) {
      if (text.length <= 2) {
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } else if (text.length <= 4) {
        return TextEditingValue(
          text: '${text.substring(0, 2)}/${text.substring(2)}',
          selection: TextSelection.collapsed(offset: text.length + 1),
        );
      } else {
        return TextEditingValue(
          text:
              '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}',
          selection: TextSelection.collapsed(offset: text.length + 2),
        );
      }
    }
    return oldValue;
  });

  IconData _selectedIcon = Icons.person; // Ícone padrão

  // Mapa expandido com muitos mais ícones
  final Map<String, IconData> _iconMap = {
    // Pessoas
    'person': Icons.person,
    'woman': Icons.woman,
    'man': Icons.man,
    'face': Icons.face,
    'account_circle': Icons.account_circle,
    'emoji_people': Icons.emoji_people,
    'accessibility': Icons.accessibility,
    'child_care': Icons.child_care,
    'elderly': Icons.elderly,
    'family_restroom': Icons.family_restroom,
    'groups': Icons.groups,
    'person_add': Icons.person_add,
    'person_remove': Icons.person_remove,
    'person_outline': Icons.person_outline,
    'person_pin': Icons.person_pin,
    'person_search': Icons.person_search,
    'sentiment_satisfied': Icons.sentiment_satisfied,
    'sentiment_dissatisfied': Icons.sentiment_dissatisfied,
    'mood': Icons.mood,
    'mood_bad': Icons.mood_bad,

    // Animais
    'pets': Icons.pets,
    'bug_report': Icons.bug_report,
    'flutter_dash': Icons.flutter_dash, // Ícone do Flutter
    'cruelty_free': Icons.cruelty_free,

    // Esportes
    'sports_soccer': Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'sports_baseball': Icons.sports_baseball,
    'sports_tennis': Icons.sports_tennis,
    'sports_volleyball': Icons.sports_volleyball,
    'sports_football': Icons.sports_football,
    'fitness_center': Icons.fitness_center,
    'pool': Icons.pool,
    'directions_run': Icons.directions_run,
    'directions_bike': Icons.directions_bike,

    // Música e Entretenimento
    'music_note': Icons.music_note,
    'queue_music': Icons.queue_music,
    'album': Icons.album,
    'library_music': Icons.library_music,
    'movie': Icons.movie,
    'tv': Icons.tv,
    'games': Icons.games,
    'videogame_asset': Icons.videogame_asset,
    'headphones': Icons.headphones,
    'mic': Icons.mic,

    // Natureza e Viagem
    'nature': Icons.nature,
    'landscape': Icons.landscape,
    'beach_access': Icons.beach_access,
    'flight': Icons.flight,
    'directions_car': Icons.directions_car,
    'train': Icons.train,
    'directions_boat': Icons.directions_boat,
    'explore': Icons.explore,
    'map': Icons.map,
    'location_on': Icons.location_on,

    // Trabalho e Estudo
    'work': Icons.work,
    'school': Icons.school,
    'book': Icons.book,
    'library_books': Icons.library_books,
    'computer': Icons.computer,
    'phone_android': Icons.phone_android,
    'email': Icons.email,
    'attach_money': Icons.attach_money,
    'business': Icons.business,

    // Comida e Bebida
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_pizza': Icons.local_pizza,
    'icecream': Icons.icecream,
    'cake': Icons.cake,
    'local_bar': Icons.local_bar,

    // Outros
    'favorite': Icons.favorite,
    'star': Icons.star,
    'thumb_up': Icons.thumb_up,
    'celebration': Icons.celebration,
    'party_mode': Icons.party_mode,
    'lightbulb': Icons.lightbulb,
    'palette': Icons.palette,
    'camera': Icons.camera,
    'photo': Icons.photo,
    'videocam': Icons.videocam,
  };

  @override
  void initState() {
    super.initState();
    _userBox = Hive.box('userData');
    _loadUser();
  }

  void _loadUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      final userData =
          _userBox.get('currentUser') as Map<String, dynamic>? ?? {};
      _nomeController.text =
          userData['nome'] ?? _currentUser!.displayName ?? '';
      _telefoneController.text = userData['telefone'] ?? '';
      _dataNascimentoController.text = userData['dataNascimento'] ?? '';
      final iconName = userData['selectedIcon'] ?? 'person';
      _selectedIcon = _iconMap[iconName] ?? Icons.person;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Para web, mostre uma mensagem ou desabilite
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload de foto não disponível no navegador. Use o app mobile.',
          ),
        ),
      );
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  Future<void> _selectIcon() async {
    final selected = await showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha um Ícone'),
        content: Container(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            children: _iconMap.values.map((icon) {
              return IconButton(
                icon: Icon(icon, size: 40),
                onPressed: () => Navigator.of(context).pop(icon),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedIcon = selected);
    }
  }

  Future<void> _saveProfile() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nome é obrigatório!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_telefoneController.text.isNotEmpty &&
        !_isValidPhone(_telefoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Telefone inválido! Use formato (XX) XXXXX-XXXX'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final userData = UserData(
        nome: _nomeController.text,
        email: _currentUser!.email,
        telefone: _telefoneController.text,
        dataNascimento: _dataNascimentoController.text,
      );
      final dataMap = userData.toMap();
      // Salve o nome do ícone
      final iconName = _iconMap.entries
          .firstWhere(
            (entry) => entry.value == _selectedIcon,
            orElse: () => MapEntry('person', Icons.person),
          )
          .key;
      dataMap['selectedIcon'] = iconName;
      if (_profileImage != null) dataMap['profileImage'] = _profileImage!.path;
      await _userBox.put('currentUser', dataMap);

      if (_nomeController.text != _currentUser!.displayName) {
        await _currentUser!.updateDisplayName(_nomeController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _saving = false);
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
    return regex.hasMatch(phone);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Logout'),
        content: Text('Deseja sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final auth = FlutterFireAuth(context);
      await auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.indigoAccent.shade700
        : Colors.indigo.shade700;
    final backgroundColor = isDarkMode
        ? Color(0xFF1E1E28)
        : Colors.grey.shade50;
    final cardColor = isDarkMode ? Color(0xFF2D2D3A) : Colors.white;
    final accentColor = Colors.orangeAccent;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 100, color: theme.disabledColor),
              SizedBox(height: 16),
              Text(
                'Usuário não logado',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: Text('Fazer Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Perfil Profissional',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.3),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
            tooltip: _isEditing ? 'Cancelar Edição' : 'Editar Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar com Seleção de Ícone
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: _isEditing ? 120 : 100,
                  height: _isEditing ? 120 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.2),
                  ),
                  child: Icon(
                    _selectedIcon,
                    size: _isEditing ? 60 : 50,
                    color: primaryColor,
                  ),
                ),
                if (_isEditing)
                  FloatingActionButton.small(
                    onPressed: _selectIcon,
                    backgroundColor: accentColor,
                    child: Icon(
                      Icons.palette,
                      color: Colors.white,
                    ), // Ícone para seleção
                  ),
              ],
            ),
            SizedBox(height: 24),
            // Card de Informações
            Card(
              color: cardColor,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              shadowColor: primaryColor.withOpacity(0.2),
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    _buildEditableField(
                      label: 'Nome Completo',
                      controller: _nomeController,
                      icon: Icons.person,
                      isEditing: _isEditing,
                      hint: 'Digite seu nome',
                      accentColor: accentColor,
                    ),
                    Divider(height: 32),
                    ListTile(
                      leading: Icon(Icons.email, color: primaryColor),
                      title: Text(
                        'Email',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _currentUser!.email ?? 'Não informado',
                        style: GoogleFonts.roboto(),
                      ),
                    ),
                    Divider(height: 32),
                    _buildEditableField(
                      label: 'Telefone',
                      controller: _telefoneController,
                      icon: Icons.phone,
                      isEditing: _isEditing,
                      keyboardType: TextInputType.phone,
                      hint: '(XX) XXXXX-XXXX',
                      accentColor: accentColor,
                      inputFormatters: [_phoneFormatter], // Adicione aqui
                    ),
                    Divider(height: 32),
                    _buildEditableField(
                      label: 'Data de Nascimento',
                      controller: _dataNascimentoController,
                      icon: Icons.calendar_today,
                      isEditing: _isEditing,
                      onTap: _isEditing ? _selectDate : null,
                      hint: 'DD/MM/AAAA',
                      accentColor: accentColor,
                      inputFormatters: [_dateFormatter], // Adicione aqui
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            // Botões
            if (_isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save),
                    label: Text('Salvar Alterações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _isEditing = false),
                    icon: Icon(Icons.cancel),
                    label: Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 2),
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout),
                label: Text('Sair da Conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade400,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
              ),
            ],
            SizedBox(height: 24),
            // Nota Profissional
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.8),
                    accentColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'Mantenha seu perfil atualizado para uma experiência personalizada e segura.',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? hint,
    Color accentColor = Colors.orangeAccent,
    List<TextInputFormatter>? inputFormatters, // Adicione este parâmetro
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isEditing ? accentColor : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
      ),
      subtitle: isEditing
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onTap: onTap,
              inputFormatters: inputFormatters, // Use aqui
              validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
            )
          : Text(
              controller.text.isEmpty ? 'Não informado' : controller.text,
              style: GoogleFonts.roboto(),
            ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dataNascimentoController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(picked);
      });
    }
  }
}
