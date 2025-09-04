import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'service': 'Limpeza de Pele',
      'professional': 'Dra. Amanda Silva',
      'date': '05 Set',
      'time': '14:30',
      'avatar': 'assets/avatar1.png',
      'confirmed': true,
    },
    {
      'service': 'Hidratação Capilar',
      'professional': 'João Paulo',
      'date': '08 Set',
      'time': '10:00',
      'avatar': 'assets/avatar2.png',
      'confirmed': false,
    },
  ];

  final List<Map<String, dynamic>> _promotions = [
    {
      'title': 'Combo Relaxante',
      'description': 'Massagem + Hidratação Facial',
      'discount': '25%',
      'validUntil': '15/09',
      'image': 'assets/promo1.jpg',
      'color': Color(0xFFFFA0A0),
    },
    {
      'title': 'Dia da Beleza',
      'description': 'Cabelo + Unhas + Maquiagem',
      'discount': '30%',
      'validUntil': '20/09',
      'image': 'assets/promo2.jpg',
      'color': Color(0xFFA0D7FF),
    },
    {
      'title': 'Tratamento Corporal',
      'description': 'Esfoliação + Hidratação',
      'discount': '20%',
      'validUntil': '25/09',
      'image': 'assets/promo3.jpg',
      'color': Color(0xFFC9FFA0),
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {'name': 'Facial', 'icon': Icons.face, 'color': Color(0xFFFFA0A0)},
    {'name': 'Cabelo', 'icon': Icons.content_cut, 'color': Color(0xFFA0D7FF)},
    {'name': 'Massagem', 'icon': Icons.spa, 'color': Color(0xFFC9FFA0)},
    {'name': 'Unhas', 'icon': Icons.brush, 'color': Color(0xFFFFD6A0)},
    {'name': 'Depilação', 'icon': Icons.waves, 'color': Color(0xFFD9A0FF)},
    {'name': 'Maquiagem', 'icon': Icons.palette, 'color': Color(0xFFA0FFEA)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..forward();

    // Simulate loading
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        body: _isLoading ? _buildLoadingScreen() : _buildHomeContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/beauty-loading.json', width: 200, height: 200),
          SizedBox(height: 20),
          Text(
            'Preparando sua experiência...',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: AnimationLimiter(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildHeader()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildWelcomeCard()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildPromotionsCarousel()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildServicesGrid()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildAppointmentsSection()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimationConfiguration.synchronized(
                duration: Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildFeaturedProfessionals()),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bella Estética',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Sua beleza em boas mãos',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(Icons.notifications_none_outlined, () {
                // Mostrar notificações
              }, hasIndicator: true),
              SizedBox(width: 8),
              Hero(
                tag: 'profile',
                child: Material(
                  elevation: 0,
                  shape: CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Abrir perfil
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    Function() onTap, {
    bool hasIndicator = false,
  }) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.grey[800]),
              if (hasIndicator)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final DateTime now = DateTime.now();
    String greeting;

    if (now.hour < 12) {
      greeting = 'Bom dia';
    } else if (now.hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8FB1), Color(0xFFFF5C8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF8FB1).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Marina!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Você tem 120 pontos acumulados.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFFFF5C8D),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Ver recompensas',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(seconds: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Image.asset('assets/gift-box.png', height: 120),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promoções Especiais',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todas',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF5C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder(
                tween: Tween<double>(
                  begin: 0.8,
                  end: _currentPage == index ? 1.0 : 0.8,
                ),
                duration: Duration(milliseconds: 300),
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _promotions[index]['color'],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _promotions[index]['color'].withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage(_promotions[index]['image']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _promotions[index]['discount'] + ' OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _promotions[index]['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _promotions[index]['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Válido até ' + _promotions[index]['validUntil'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promotions.length,
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Color(0xFFFF5C8D)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Nossos Serviços',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: Duration(milliseconds: 500),
                columnCount: 3,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildServiceItem(
                      _services[index]['name'],
                      _services[index]['icon'],
                      _services[index]['color'],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(String name, IconData icon, Color color) {
    return Material(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color.withOpacity(0.8)),
              ),
              SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    if (_upcomingAppointments.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximos Agendamentos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF5C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _upcomingAppointments.length,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final appointment = _upcomingAppointments[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: Duration(milliseconds: 500),
              child: SlideAnimation(
                horizontalOffset: 50,
                child: FadeInAnimation(
                  child: _buildAppointmentCard(appointment),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appointment['date'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        appointment['time'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['service'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: AssetImage(appointment['avatar']),
                          ),
                          SizedBox(width: 6),
                          Text(
                            appointment['professional'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appointment['confirmed']
                        ? Colors.green[100]
                        : Colors.amber[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment['confirmed'] ? 'Confirmado' : 'Pendente',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: appointment['confirmed']
                          ? Colors.green[800]
                          : Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProfessionals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Profissionais em Destaque',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: _buildProfessionalCard(
                      name: 'Profissional ${index + 1}',
                      specialty: index % 2 == 0 ? 'Cabelo' : 'Estética',
                      rating: 4.5 + (index % 2) * 0.3,
                      image: 'assets/professional${index + 1}.jpg',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalCard({
    required String name,
    required String specialty,
    required double rating,
    required String image,
  }) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Material(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(image),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            specialty,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
