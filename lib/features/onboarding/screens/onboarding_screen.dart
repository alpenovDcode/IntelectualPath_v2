import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import '../../../config/theme.dart';
import '../../../widgets/buttons.dart';
import '../../auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  
  // Данные для страниц онбординга
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Добро пожаловать в IntelectualPath',
      description: 'Ваш путь к новым знаниям и навыкам начинается здесь',
      animationPath: 'assets/animations/Hello.json',
      icon: Icons.lightbulb_outline,
      backgroundColor: Colors.blue.shade400,
    ),
    OnboardingPage(
      title: 'Множество курсов',
      description: 'Выбирайте курсы различной сложности и направленности',
      animationPath: 'assets/animations/Study.json',
      icon: Icons.menu_book_outlined,
      backgroundColor: Colors.green.shade400,
    ),
    OnboardingPage(
      title: 'Отслеживайте прогресс',
      description: 'Следите за своими достижениями и продвигайтесь к новым высотам',
      animationPath: 'assets/animations/Create1.json',
      icon: Icons.bar_chart_rounded,
      backgroundColor: Colors.orange.shade400,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Отмечаем, что онбординг пройден
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _isLastPage = index == _pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPageWidget(
                  page: _pages[index],
                  index: index,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Индикаторы страниц
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 5,
                        expansionFactor: 3,
                        activeDotColor: AppTheme.primaryColor,
                        dotColor: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // Кнопки навигации
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка "Далее" или "Начать"
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            text: _isLastPage ? 'Начать' : 'Далее',
                            onPressed: () {
                              if (_isLastPage) {
                                _navigateToLogin();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            type: AppButtonType.primary,
                            icon: _isLastPage ? Icons.check : Icons.arrow_forward,
                            iconRight: true,
                            textColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToLogin() async {
    await _markOnboardingComplete();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppInitializer(),
      ),
    );
  }
}

// Модель данных для страницы онбординга
class OnboardingPage {
  final String title;
  final String description;
  final String? imagePath;
  final String? animationPath;
  final IconData icon;
  final Color backgroundColor;
  
  OnboardingPage({
    required this.title,
    required this.description,
    this.imagePath,
    this.animationPath,
    required this.icon,
    required this.backgroundColor,
  });
}

// Виджет для отображения страницы онбординга
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final int index;
  
  const OnboardingPageWidget({
    super.key,
    required this.page,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Фоновые круги для декорации
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          // Основной контент
          Column(
            children: [
              // Верхняя часть с изображением
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: _buildImage().animate(delay: 300.ms).scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                    ),
                  ),
                ),
              ),
              
              // Нижняя часть с текстом и кнопками
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: 180,
                  maxHeight: 260,
                ),
                padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ).animate(delay: 400.ms).slideX(
                      duration: 500.ms,
                      begin: 0.3,
                      curve: Curves.easeOutCubic,
                    ).fadeIn(),
                    
                    const SizedBox(height: 16),
                    
                    // Описание
                    Text(
                      page.description,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ).animate(delay: 600.ms).slideX(
                      duration: 500.ms,
                      begin: 0.3,
                      curve: Curves.easeOutCubic,
                    ).fadeIn(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildImage() {
    if (page.animationPath != null) {
      return FutureBuilder(
        future: rootBundle.loadString(page.animationPath!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Lottie.asset(
              page.animationPath!,
              height: 460,
              width: 460,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            );
          } else if (snapshot.hasError) {
            // Если ошибка — показываем иконку
            return Icon(
              page.icon,
              size: 120,
              color: Colors.white,
            );
          } else {
            // Пока грузится — показываем лоадер
            return const CircularProgressIndicator();
          }
        },
      );
    } else if (page.imagePath != null) {
      return Image.asset(
        page.imagePath!,
        height: 240,
        width: 240,
        fit: BoxFit.contain,
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          page.icon,
          size: 100,
          color: page.backgroundColor,
        ),
      );
    }
  }
} 