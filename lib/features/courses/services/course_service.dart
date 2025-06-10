import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class CourseService {
  static const String _coursesKey = 'courses';
  static const String _userProgressKey = 'user_courses_progress';
  
  // Singleton pattern
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  // Получение всех курсов
  Future<List<Course>> getCourses() async {
    print("CourseService: getCourses() вызван");
    
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString(_coursesKey);
    
    if (coursesJson == null) {
      print("CourseService: нет сохраненных курсов, создаю демо-курсы");
      // Если курсов нет, создаем демо-курсы
      final demoCourses = _createDemoCourses();
      await _saveCourses(demoCourses);
      return demoCourses;
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(coursesJson);
      final courses = decoded.map((item) => Course.fromJson(item)).toList();
      print("CourseService: загружено ${courses.length} курсов");
      return courses;
    } catch (e) {
      print("CourseService: ошибка при загрузке курсов: $e");
      // В случае ошибки, создаем новые демо-курсы
      final demoCourses = _createDemoCourses();
      await _saveCourses(demoCourses);
      return demoCourses;
    }
  }
  
  // Получение курса по ID
  Future<Course?> getCourseById(String courseId) async {
    print("CourseService: getCourseById() вызван для id=$courseId");
    
    final courses = await getCourses();
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    
    if (course == null) {
      print("CourseService: курс с id=$courseId не найден");
    } else {
      print("CourseService: курс с id=$courseId успешно загружен");
    }
    
    return course;
  }
  
  // Сохранение курсов
  Future<void> _saveCourses(List<Course> courses) async {
    print("CourseService: _saveCourses() вызван");
    
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final coursesJson = jsonEncode(courses.map((course) => course.toJson()).toList());
      await prefs.setString(_coursesKey, coursesJson);
      print("CourseService: ${courses.length} курсов сохранено");
    } catch (e) {
      print("CourseService: ошибка при сохранении курсов: $e");
      throw Exception('Ошибка при сохранении курсов: $e');
    }
  }

  // Обновление прогресса пользователя по курсу
  Future<void> updateLessonProgress(String userId, String courseId, String lessonId, bool isCompleted) async {
    print("CourseService: updateLessonProgress() вызван для пользователя=$userId, курс=$courseId, урок=$lessonId, выполнен=$isCompleted");
    
    final courses = await getCourses();
    final courseIndex = courses.indexWhere((c) => c.id == courseId);
    
    if (courseIndex < 0) {
      print("CourseService: курс с id=$courseId не найден");
      return;
    }
    
    final course = courses[courseIndex];
    final lessonIndex = course.modules.first.lessons.indexWhere((l) => l.id == lessonId);
    
    if (lessonIndex < 0) {
      print("CourseService: урок с id=$lessonId не найден в курсе $courseId");
      return;
    }
    
    // Обновляем статус урока
    final updatedLesson = course.modules.first.lessons[lessonIndex].copyWith(isCompleted: isCompleted);
    final updatedLessons = List<Lesson>.from(course.modules.first.lessons);
    updatedLessons[lessonIndex] = updatedLesson;

    // Находим модуль, в котором находится урок
    int moduleIndex = -1;
    int lessonIndexInModule = -1;
    for (int i = 0; i < course.modules.length; i++) {
      final idx = course.modules[i].lessons.indexWhere((l) => l.id == lessonId);
      if (idx != -1) {
        moduleIndex = i;
        lessonIndexInModule = idx;
        break;
      }
    }
    if (moduleIndex == -1 || lessonIndexInModule == -1) {
      print("CourseService: модуль с уроком не найден");
      return;
    }
    // Обновляем урок в модуле
    final updatedModule = course.modules[moduleIndex];
    final updatedModuleLessons = List<Lesson>.from(updatedModule.lessons);
    updatedModuleLessons[lessonIndexInModule] = updatedLesson;
    final newModule = Module(
      id: updatedModule.id,
      title: updatedModule.title,
      lessons: updatedModuleLessons,
      tasks: updatedModule.tasks,
      quizzes: updatedModule.quizzes,
    );
    // Обновляем список модулей
    final updatedModules = List<Module>.from(course.modules);
    updatedModules[moduleIndex] = newModule;
    
    // Обновляем курс с новым прогрессом
    final completedLessons = updatedLessons.where((l) => l.isCompleted).length;
    final progress = course.modules.isEmpty ? 0.0 : completedLessons / course.modules.first.lessons.length;
    
    final updatedCourse = course.copyWith(
      modules: updatedModules,
      completedLessons: completedLessons,
      progress: progress,
    );
    
    // Обновляем список курсов
    final updatedCourses = List<Course>.from(courses);
    updatedCourses[courseIndex] = updatedCourse;
    
    // Сохраняем обновленные курсы
    await _saveCourses(updatedCourses);
    
    // Сохраняем прогресс пользователя
    await _saveUserProgress(userId, courseId, lessonId, isCompleted);
    
    print("CourseService: прогресс урока обновлен, новый прогресс курса: $progress");
  }
  
  // Сохранение прогресса пользователя
  Future<void> _saveUserProgress(String userId, String courseId, String lessonId, bool isCompleted) async {
    print("CourseService: _saveUserProgress() вызван");
    
    final prefs = await SharedPreferences.getInstance();
    final userProgressKey = "${_userProgressKey}_$userId";
    final progressJson = prefs.getString(userProgressKey);
    
    Map<String, dynamic> progress = {};
    if (progressJson != null) {
      try {
        progress = jsonDecode(progressJson);
      } catch (e) {
        print("CourseService: ошибка при парсинге прогресса: $e");
      }
    }
    
    // Обновляем прогресс для курса
    if (!progress.containsKey(courseId)) {
      progress[courseId] = <String, bool>{};
    }
    
    // Обновляем статус урока
    progress[courseId][lessonId] = isCompleted;
    
    // Сохраняем обновленный прогресс
    try {
      await prefs.setString(userProgressKey, jsonEncode(progress));
      print("CourseService: прогресс пользователя сохранен");
    } catch (e) {
      print("CourseService: ошибка при сохранении прогресса: $e");
    }
  }
  
  // Получение курсов пользователя с прогрессом
  Future<List<Course>> getUserCourses(String userId) async {
    print("CourseService: getUserCourses() вызван для пользователя=$userId");
    
    final courses = await getCourses();
    final prefs = await SharedPreferences.getInstance();
    final userProgressKey = "${_userProgressKey}_$userId";
    final progressJson = prefs.getString(userProgressKey);
    
    if (progressJson == null) {
      print("CourseService: прогресс пользователя не найден");
      return courses;
    }
    
    try {
      final Map<String, dynamic> progress = jsonDecode(progressJson);
      
      // Обновляем прогресс для каждого курса
      final updatedCourses = courses.map((course) {
        if (!progress.containsKey(course.id)) {
          return course;
        }
        
        final courseProgress = progress[course.id] as Map<String, dynamic>;
        final updatedModules = course.modules.map((module) {
          final updatedLessons = module.lessons.map((lesson) {
          final isCompleted = courseProgress[lesson.id] ?? false;
          return lesson.copyWith(isCompleted: isCompleted);
        }).toList();
        
        final completedLessons = updatedLessons.where((l) => l.isCompleted).length;
          final progressValue = module.lessons.isEmpty ? 0.0 : completedLessons / module.lessons.length;
        
          return Module(
            id: module.id,
            title: module.title,
          lessons: updatedLessons,
            tasks: module.tasks,
            quizzes: module.quizzes,
          );
        }).toList();
        
        final completedLessons = updatedModules.fold<int>(0, (sum, m) => sum + m.lessons.where((l) => l.isCompleted).length);
        final totalLessons = updatedModules.fold<int>(0, (sum, m) => sum + m.lessons.length);
        final progressValue = totalLessons == 0 ? 0.0 : completedLessons / totalLessons;
        
        return course.copyWith(
          modules: updatedModules,
          completedLessons: completedLessons,
          progress: progressValue,
        );
      }).toList();
      
      print("CourseService: курсы пользователя загружены с прогрессом");
      return updatedCourses;
    } catch (e) {
      print("CourseService: ошибка при загрузке прогресса: $e");
      return courses;
    }
  }
  
  // Подписка на курс
  Future<bool> subscribeToCourse(String userId, String courseId) async {
    print("CourseService: subscribeToCourse() вызван для пользователя=$userId, курс=$courseId");
    
    try {
      final courses = await getCourses();
      final courseIndex = courses.indexWhere((c) => c.id == courseId);
      
      if (courseIndex < 0) {
        print("CourseService: курс с id=$courseId не найден");
        return false;
      }
      
      // Обновляем статус подписки
      final course = courses[courseIndex];
      final updatedCourse = course.copyWith(isSubscribed: true);
      
      // Обновляем список курсов
      final updatedCourses = List<Course>.from(courses);
      updatedCourses[courseIndex] = updatedCourse;
      
      // Сохраняем обновленные курсы
      await _saveCourses(updatedCourses);
      
      // Сохраняем информацию о подписке пользователя
      await _saveUserSubscription(userId, courseId, true);
      
      print("CourseService: пользователь успешно подписан на курс");
      return true;
    } catch (e) {
      print("CourseService: ошибка при подписке на курс: $e");
      return false;
    }
  }
  
  // Отписка от курса
  Future<bool> unsubscribeFromCourse(String userId, String courseId) async {
    print("CourseService: unsubscribeFromCourse() вызван для пользователя=$userId, курс=$courseId");
    
    try {
      final courses = await getCourses();
      final courseIndex = courses.indexWhere((c) => c.id == courseId);
      
      if (courseIndex < 0) {
        print("CourseService: курс с id=$courseId не найден");
        return false;
      }
      
      // Обновляем статус подписки
      final course = courses[courseIndex];
      final updatedCourse = course.copyWith(isSubscribed: false);
      
      // Обновляем список курсов
      final updatedCourses = List<Course>.from(courses);
      updatedCourses[courseIndex] = updatedCourse;
      
      // Сохраняем обновленные курсы
      await _saveCourses(updatedCourses);
      
      // Сохраняем информацию о подписке пользователя
      await _saveUserSubscription(userId, courseId, false);
      
      print("CourseService: пользователь успешно отписан от курса");
      return true;
    } catch (e) {
      print("CourseService: ошибка при отписке от курса: $e");
      return false;
    }
  }
  
  // Сохранение информации о подписке пользователя
  Future<void> _saveUserSubscription(String userId, String courseId, bool isSubscribed) async {
    print("CourseService: _saveUserSubscription() вызван");
    
    final prefs = await SharedPreferences.getInstance();
    final userSubscriptionsKey = "user_subscriptions_$userId";
    final subscriptionsJson = prefs.getString(userSubscriptionsKey);
    
    Map<String, bool> subscriptions = {};
    if (subscriptionsJson != null) {
      try {
        final decoded = jsonDecode(subscriptionsJson);
        subscriptions = Map<String, bool>.from(decoded);
      } catch (e) {
        print("CourseService: ошибка при парсинге подписок: $e");
      }
    }
    
    // Обновляем статус подписки
    subscriptions[courseId] = isSubscribed;
    
    // Сохраняем обновленные подписки
    try {
      await prefs.setString(userSubscriptionsKey, jsonEncode(subscriptions));
      print("CourseService: подписки пользователя сохранены");
    } catch (e) {
      print("CourseService: ошибка при сохранении подписок: $e");
    }
  }
  
  // Получение подписок пользователя
  Future<List<Course>> getUserSubscribedCourses(String userId) async {
    print("CourseService: getUserSubscribedCourses() вызван для пользователя=$userId");
    
    final courses = await getCourses();
    final prefs = await SharedPreferences.getInstance();
    final userSubscriptionsKey = "user_subscriptions_$userId";
    final subscriptionsJson = prefs.getString(userSubscriptionsKey);
    
    if (subscriptionsJson == null) {
      print("CourseService: подписки пользователя не найдены");
      return [];
    }
    
    try {
      final Map<String, dynamic> subscriptions = jsonDecode(subscriptionsJson);
      
      final subscribedCourses = courses.where((course) {
        return subscriptions[course.id] == true;
      }).toList();
      
      print("CourseService: найдено ${subscribedCourses.length} подписок пользователя");
      return subscribedCourses;
    } catch (e) {
      print("CourseService: ошибка при загрузке подписок: $e");
      return [];
    }
  }
  
  // Обновление подписок в списке курсов для конкретного пользователя
  Future<List<Course>> getCoursesWithSubscriptionStatus(String userId) async {
    print("CourseService: getCoursesWithSubscriptionStatus() вызван для пользователя=$userId");
    
    final courses = await getCourses();
    final prefs = await SharedPreferences.getInstance();
    final userSubscriptionsKey = "user_subscriptions_$userId";
    final subscriptionsJson = prefs.getString(userSubscriptionsKey);
    
    if (subscriptionsJson == null) {
      print("CourseService: подписки пользователя не найдены");
      return courses;
    }
    
    try {
      final Map<String, dynamic> subscriptions = jsonDecode(subscriptionsJson);
      
      final updatedCourses = courses.map((course) {
        final isSubscribed = subscriptions[course.id] == true;
        return course.copyWith(isSubscribed: isSubscribed);
      }).toList();
      
      print("CourseService: статусы подписок обновлены для курсов");
      return updatedCourses;
    } catch (e) {
      print("CourseService: ошибка при обновлении статусов подписок: $e");
      return courses;
    }
  }

  // Создание демо-курсов для примера
  List<Course> _createDemoCourses() {
    print("CourseService: _createDemoCourses() вызван");
    
    // Курс программирования
    final programmingCourse = Course(
      id: 'course_programming',
      title: 'Программирование',
      description: 'Основы программирования и алгоритмы для начинающих',
      icon: Icons.code,
      color: Colors.blue,
      modules: [
        Module(
          id: 'module_prog_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_prog_1',
          title: 'Введение в программирование',
          description: 'Основные понятия и принципы программирования',
          durationMinutes: 30,
          content: """
# Введение в программирование

## Что такое программирование?

Программирование — это процесс создания инструкций для компьютера, чтобы он выполнял определенные задачи. Эти инструкции называются кодом, и они написаны на языках программирования, которые компьютер может понять.

### Основные концепции программирования:

- **Переменные**: хранят данные для использования в программе
- **Типы данных**: определяют вид информации (числа, текст, логические значения)
- **Функции**: блоки кода, которые выполняют определенные задачи
- **Условия**: позволяют программе принимать решения
- **Циклы**: позволяют повторять действия несколько раз

## Почему программирование важно?

В современном мире программирование становится все более важным навыком. Компьютеры и программное обеспечение используются практически везде — от смартфонов до автомобилей и медицинского оборудования.

**Важно**: Изучение программирования развивает логическое мышление и навыки решения проблем.
""",
        ),
        Lesson(
          id: 'lesson_prog_2',
          title: 'Переменные и типы данных',
          description: 'Изучение переменных и базовых типов данных',
          durationMinutes: 45,
          content: """
# Переменные и типы данных

## Что такое переменные?

Переменные — это "контейнеры" для хранения данных в программе. Представьте их как коробки с ярлыками, где:
- Имя переменной — это ярлык
- Значение переменной — это содержимое коробки

## Основные типы данных:

### Целые числа (int)
```
возраст = 25
количество_студентов = 30
```

### Числа с плавающей точкой (float)
```
цена = 19.99
вес = 68.5
```

### Строки (string)
```
имя = "Мария"
сообщение = 'Привет, мир!'
```

### Логические значения (boolean)
```
isActive = true
завершено = false
```

## Примеры объявления переменных:

В разных языках программирования синтаксис может отличаться:

**Python:**
```python
name = "Иван"
age = 25
```

**JavaScript:**
```javascript
let name = "Иван";
const age = 25;
```

**Java:**
```java
String name = "Иван";
int age = 25;
```

Переменные позволяют сохранять данные и использовать их в разных частях программы. Это основа практически любого программного кода.
""",
        ),
        Lesson(
          id: 'lesson_prog_3',
          title: 'Условные операторы',
          description: 'Изучение условных операторов if-else',
          durationMinutes: 40,
        ),
        Lesson(
          id: 'lesson_prog_4',
          title: 'Циклы',
          description: 'Работа с циклами for и while',
          durationMinutes: 50,
        ),
        Lesson(
          id: 'lesson_prog_5',
          title: 'Функции',
          description: 'Создание и использование функций',
          durationMinutes: 55,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 5,
      ratingAverage: 4.7,
      ratingCount: 324,
      difficulty: 'Средний уровень',
      category: 'Технологии',
      price: 0,
    );
    
    // Курс языков
    final languageCourse = Course(
      id: 'course_language',
      title: 'Иностранные языки',
      description: 'Изучение английского языка для начинающих',
      icon: Icons.language,
      color: Colors.green,
      modules: [
        Module(
          id: 'module_lang_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_lang_1',
          title: 'Приветствия и знакомство',
          description: 'Базовые фразы для приветствия на английском',
          durationMinutes: 20,
          content: """
# Приветствия и знакомство на английском

## Основные фразы приветствия:

- **Hello!** — Привет!
- **Hi!** — Привет! (неформально)
- **Good morning!** — Доброе утро! (до 12:00)
- **Good afternoon!** — Добрый день! (12:00 - 18:00)
- **Good evening!** — Добрый вечер! (после 18:00)
- **Good night!** — Доброй ночи! (при прощании перед сном)

## Знакомство:

### Представление себя
- **My name is...** — Меня зовут...
- **I'm...** — Я...
- **Nice to meet you!** — Приятно познакомиться!
- **Pleased to meet you!** — Рад познакомиться!

### Вопросы
- **What's your name?** — Как тебя зовут?
- **Where are you from?** — Откуда ты?
- **How are you?** — Как дела?

### Ответы на "How are you?"
- **I'm fine, thank you.** — Я в порядке, спасибо.
- **I'm good, thanks.** — У меня всё хорошо, спасибо.
- **Not bad.** — Неплохо.
- **I'm OK.** — Я в порядке.

## Практические диалоги:

**Диалог 1:**
```
A: Hello!
B: Hi there!
A: My name is John. What's your name?
B: I'm Maria. Nice to meet you!
A: Nice to meet you too! Where are you from?
B: I'm from Spain. And you?
A: I'm from Canada.
```

**Диалог 2:**
```
A: Good morning!
B: Good morning! How are you today?
A: I'm fine, thank you. And you?
B: Not bad, thanks.
```

## Упражнение:
Составьте свой собственный диалог знакомства, используя фразы из урока.
""",
        ),
        Lesson(
          id: 'lesson_lang_2',
          title: 'Числа и счет',
          description: 'Изучение чисел и базовых математических операций',
          durationMinutes: 25,
        ),
        Lesson(
          id: 'lesson_lang_3',
          title: 'Семья и родственники',
          description: 'Словарный запас по теме "Семья"',
          durationMinutes: 30,
        ),
        Lesson(
          id: 'lesson_lang_4',
          title: 'Время и даты',
          description: 'Как говорить о времени и датах',
          durationMinutes: 35,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 4,
      ratingAverage: 4.5,
      ratingCount: 218,
      difficulty: 'Начальный уровень',
      category: 'Языки',
      price: 990,
    );
    
    // Курс логики
    final logicCourse = Course(
      id: 'course_logic',
      title: 'Логика',
      description: 'Развитие логического мышления и решение задач',
      icon: Icons.psychology,
      color: Colors.purple,
      modules: [
        Module(
          id: 'module_logic_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_logic_1',
          title: 'Основы логики',
          description: 'Введение в формальную логику',
          durationMinutes: 40,
          content: """
# Основы логики

## Что такое логика?

Логика — это наука о правильном мышлении, о законах, формах и приемах интеллектуальной познавательной деятельности человека. 

Логика изучает методы отличия правильных рассуждений от неправильных и помогает избегать ошибок в процессе мышления.

## Основные понятия логики:

### Высказывание
Высказывание — это предложение, о котором можно сказать, истинно оно или ложно.

**Примеры высказываний:**
- "Солнце — звезда" (истинно)
- "Москва — столица Франции" (ложно)
- "2 + 2 = 4" (истинно)

**Не являются высказываниями:**
- "Который час?"
- "Сделай домашнее задание!"
- "Ух ты!"

### Логические операции:

1. **Отрицание (НЕ)** — изменяет истинность высказывания на противоположную
   * Обозначение: ¬A или ~A
   * Пример: "Не является правдой, что Москва — столица Франции" (истинно)

2. **Конъюнкция (И)** — истинна только когда оба высказывания истинны
   * Обозначение: A ∧ B
   * Пример: "Солнце — звезда И Земля — планета" (истинно)

3. **Дизъюнкция (ИЛИ)** — истинна, когда хотя бы одно из высказываний истинно
   * Обозначение: A ∨ B
   * Пример: "Солнце — звезда ИЛИ Москва — столица Франции" (истинно)

4. **Импликация (ЕСЛИ..., ТО...)** — ложна только когда из истинного высказывания следует ложное
   * Обозначение: A → B
   * Пример: "ЕСЛИ идет дождь, ТО асфальт мокрый"

## Таблицы истинности:

Таблицы истинности показывают, как значение сложного высказывания зависит от значений входящих в него простых высказываний.

### Таблица истинности для конъюнкции (И):
| A | B | A ∧ B |
|---|---|-------|
| Т | Т |   Т   |
| Т | Л |   Л   |
| Л | Т |   Л   |
| Л | Л |   Л   |

### Таблица истинности для дизъюнкции (ИЛИ):
| A | B | A ∨ B |
|---|---|-------|
| Т | Т |   Т   |
| Т | Л |   Т   |
| Л | Т |   Т   |
| Л | Л |   Л   |

## Практическое применение логики:

- Программирование (условные операторы, булева логика)
- Анализ аргументов в дискуссиях
- Решение логических задач и головоломок
- Юриспруденция (правовые рассуждения)
- Математика и наука (доказательства теорем)
""",
        ),
        Lesson(
          id: 'lesson_logic_2',
          title: 'Логические операторы',
          description: 'Изучение логических операторов И, ИЛИ, НЕ',
          durationMinutes: 45,
        ),
        Lesson(
          id: 'lesson_logic_3',
          title: 'Решение логических задач',
          description: 'Практические задания на развитие логики',
          durationMinutes: 60,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 3,
      ratingAverage: 4.9,
      ratingCount: 156,
      difficulty: 'Продвинутый уровень',
      category: 'Наука',
      price: 1490,
    );
    
    // Дополнительные курсы
    final webDevCourse = Course(
      id: 'course_webdev',
      title: 'Веб-разработка',
      description: 'Создание современных веб-сайтов с использованием HTML, CSS и JavaScript',
      icon: Icons.web,
      color: Colors.orange,
      modules: [
        Module(
          id: 'module_webdev_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_webdev_1',
          title: 'Введение в HTML',
          description: 'Основы структуры HTML и семантические теги',
          durationMinutes: 35,
          content: """
# Введение в HTML

HTML (HyperText Markup Language) — это стандартный язык разметки для создания веб-страниц.

## Структура HTML-документа

```html
<!DOCTYPE html>
<html>
<head>
    <title>Название страницы</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>Это заголовок</h1>
    <p>Это параграф текста.</p>
</body>
</html>
```

## Основные HTML-теги

- `<h1>` - `<h6>`: Заголовки разных уровней
- `<p>`: Параграф текста
- `<a>`: Ссылка
- `<img>`: Изображение
- `<ul>`, `<ol>`, `<li>`: Списки
- `<div>`: Блочный контейнер
- `<span>`: Строчный контейнер

## Семантические теги HTML5

HTML5 ввел семантические элементы, которые помогают структурировать страницу:

- `<header>`: Верхняя часть страницы
- `<nav>`: Навигационное меню
- `<main>`: Основное содержимое
- `<section>`: Раздел страницы
- `<article>`: Независимый блок контента
- `<footer>`: Нижняя часть страницы

## Атрибуты

Элементы HTML могут иметь атрибуты:

```html
<a href="https://example.com" target="_blank">Ссылка</a>
<img src="image.jpg" alt="Описание картинки">
```

- `href`: Адрес ссылки
- `src`: Путь к изображению
- `alt`: Альтернативный текст
- `target`: Где открыть ссылку

## Практическое задание

Создайте простую HTML-страницу с:
1. Заголовком страницы
2. Параграфом текста
3. Ссылкой на любой сайт
4. Изображением
5. Списком из 3 элементов
"""
        ),
        Lesson(
          id: 'lesson_webdev_2',
          title: 'Основы CSS',
          description: 'Стилизация веб-страниц с помощью CSS',
          durationMinutes: 40,
        ),
        Lesson(
          id: 'lesson_webdev_3',
          title: 'JavaScript для начинающих',
          description: 'Основы программирования на JavaScript',
          durationMinutes: 50,
        ),
        Lesson(
          id: 'lesson_webdev_4',
          title: 'Адаптивный дизайн',
          description: 'Создание отзывчивых веб-страниц для разных устройств',
          durationMinutes: 45,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 4,
      ratingAverage: 4.8,
      ratingCount: 275,
      difficulty: 'Средний уровень',
      category: 'Технологии',
      price: 1990,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
    );
    
    final designCourse = Course(
      id: 'course_design',
      title: 'Основы дизайна',
      description: 'Принципы UI/UX дизайна и создание красивых интерфейсов',
      icon: Icons.brush,
      color: Colors.pink,
      modules: [
        Module(
          id: 'module_design_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_design_1',
          title: 'Принципы дизайна',
          description: 'Основные принципы визуального дизайна',
          durationMinutes: 30,
          content: """
# Основные принципы дизайна

Дизайн — это не просто о красоте, это о функциональности и пользовательском опыте.

## 1. Баланс

Баланс обеспечивает стабильность и структуру дизайна. Баланс может быть симметричным или асимметричным.

## 2. Контраст

Контраст привлекает внимание и выделяет важные элементы. Контраст может быть в цвете, размере, форме и т.д.

## 3. Акцент

Акцент направляет внимание пользователя к самому важному элементу дизайна.

## 4. Единство

Все элементы должны работать вместе и создавать ощущение целостности.

## 5. Пропорция

Пропорция относится к размеру и масштабу элементов по отношению друг к другу.

## 6. Иерархия

Визуальная иерархия организует элементы так, чтобы пользователи могли быстро понять их важность.

## 7. Повторение

Повторение элементов создает единство и укрепляет дизайн.

## 8. Пространство

Пространство вокруг элементов (отрицательное пространство) так же важно, как и сами элементы.

## Практическое задание

Выберите любой веб-сайт или приложение и проанализируйте, как в нем применяются эти принципы дизайна.
"""
        ),
        Lesson(
          id: 'lesson_design_2',
          title: 'Цветовая теория',
          description: 'Понимание цветов и создание гармоничных палитр',
          durationMinutes: 35,
        ),
        Lesson(
          id: 'lesson_design_3',
          title: 'Типография',
          description: 'Выбор и комбинирование шрифтов для улучшения читаемости',
          durationMinutes: 30,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 3,
      ratingAverage: 4.6,
      ratingCount: 182,
      difficulty: 'Начальный уровень',
      category: 'Дизайн',
      price: 1490,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    );
    
    final financeCourse = Course(
      id: 'course_finance',
      title: 'Личные финансы',
      description: 'Управление личными финансами и основы инвестирования',
      icon: Icons.account_balance,
      color: Colors.teal,
      modules: [
        Module(
          id: 'module_finance_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_finance_1',
          title: 'Основы бюджетирования',
          description: 'Создание и ведение личного бюджета',
          durationMinutes: 40,
          content: """
# Основы бюджетирования

Бюджет — это план управления вашими доходами и расходами.

## Почему важно вести бюджет?

- Помогает контролировать расходы
- Позволяет достигать финансовых целей
- Снижает финансовый стресс
- Помогает избежать долгов
- Создает финансовую безопасность

## Как создать бюджет

### Шаг 1: Определите свой доход
Учитывайте все источники дохода:
- Зарплата
- Фриланс
- Пассивный доход (аренда, инвестиции)
- Подработки

### Шаг 2: Отслеживайте расходы
Категории расходов:
- Обязательные (жилье, коммунальные услуги, продукты)
- Долги (кредиты, ипотека)
- Сбережения и инвестиции
- Дискреционные (развлечения, путешествия)

### Шаг 3: Задайте финансовые цели
- Краткосрочные (1-12 месяцев)
- Среднесрочные (1-5 лет)
- Долгосрочные (более 5 лет)

### Шаг 4: Создайте план бюджета
Формула бюджета: Доходы - Расходы = Сбережения

### Шаг 5: Регулярно пересматривайте и корректируйте

## Полезные методы бюджетирования

### Метод 50/30/20
- 50% на нужды (обязательные расходы)
- 30% на желания (дискреционные расходы)
- 20% на сбережения и погашение долгов

### Метод конвертов
Распределяйте наличные по конвертам для разных категорий расходов.

## Инструменты для ведения бюджета
- Специальные приложения
- Электронные таблицы
- Банковские приложения с функцией аналитики расходов

## Практическое задание
Составьте свой личный бюджет на текущий месяц, используя одну из рассмотренных методик.
"""
        ),
        Lesson(
          id: 'lesson_finance_2',
          title: 'Сбережения и инвестиции',
          description: 'Стратегии накопления и инвестирования денег',
          durationMinutes: 45,
        ),
        Lesson(
          id: 'lesson_finance_3',
          title: 'Финансовые цели',
          description: 'Постановка и достижение финансовых целей',
          durationMinutes: 35,
        ),
        Lesson(
          id: 'lesson_finance_4',
          title: 'Защита от финансовых рисков',
          description: 'Страхование и создание финансовой подушки безопасности',
          durationMinutes: 30,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 4,
      ratingAverage: 4.9,
      ratingCount: 210,
      difficulty: 'Средний уровень',
      category: 'Финансы',
      price: 2490,
      createdAt: DateTime.now().subtract(Duration(days: 45)),
    );
    
    final marketingCourse = Course(
      id: 'course_marketing',
      title: 'Цифровой маркетинг',
      description: 'Основы интернет-маркетинга и продвижения в социальных сетях',
      icon: Icons.trending_up,
      color: Colors.red,
      modules: [
        Module(
          id: 'module_marketing_1',
          title: 'Основной модуль',
      lessons: [
        Lesson(
          id: 'lesson_marketing_1',
          title: 'Введение в цифровой маркетинг',
          description: 'Основные концепции и стратегии цифрового маркетинга',
          durationMinutes: 50,
        ),
        Lesson(
          id: 'lesson_marketing_2',
          title: 'SEO-оптимизация',
          description: 'Основы поисковой оптимизации сайта',
          durationMinutes: 45,
        ),
        Lesson(
          id: 'lesson_marketing_3',
          title: 'Маркетинг в социальных сетях',
          description: 'Стратегии продвижения в социальных сетях',
          durationMinutes: 40,
        ),
        Lesson(
          id: 'lesson_marketing_4',
          title: 'Контент-маркетинг',
          description: 'Создание эффективного контента для привлечения аудитории',
          durationMinutes: 35,
        ),
        Lesson(
          id: 'lesson_marketing_5',
          title: 'Email-маркетинг',
          description: 'Создание и оптимизация email-кампаний',
          durationMinutes: 30,
            ),
          ],
          tasks: const [],
          quizzes: const [],
        ),
      ],
      lessonsCount: 5,
      ratingAverage: 4.4,
      ratingCount: 178,
      difficulty: 'Продвинутый уровень',
      category: 'Маркетинг',
      price: 3490,
      createdAt: DateTime.now().subtract(Duration(days: 60)),
    );
    
    return [
      programmingCourse, 
      languageCourse, 
      logicCourse,
      webDevCourse,
      designCourse,
      financeCourse,
      marketingCourse
    ];
  }
} 