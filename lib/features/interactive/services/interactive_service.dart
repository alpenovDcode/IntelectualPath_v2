import '../models/interactive_exercise.dart';

class InteractiveService {
  // Получение интерактивных упражнений для урока
  Future<List<InteractiveExercise>> getExercisesForLesson(String lessonId) async {
    // TODO: Заменить на реальные данные из Firebase
    return [
      InteractiveExercise(
        id: '1',
        title: 'Тест по основам программирования',
        description: 'Проверьте свои знания основ программирования',
        type: ExerciseType.quiz,
        content: {
          'questions': [
            {
              'question': 'Что такое переменная?',
              'options': [
                'Контейнер для хранения данных',
                'Тип данных',
                'Функция',
                'Оператор',
              ],
              'correctAnswer': 0,
            },
            {
              'question': 'Какой оператор используется для присваивания?',
              'options': ['=', '==', '===', '=>'],
              'correctAnswer': 0,
            },
          ],
        },
        points: 20,
        timeLimit: 300,
        tags: ['программирование', 'основы'],
      ),
      InteractiveExercise(
        id: '2',
        title: 'Сопоставление терминов',
        description: 'Сопоставьте термины с их определениями',
        type: ExerciseType.matching,
        content: {
          'pairs': [
            {
              'term': 'HTML',
              'definition': 'Язык разметки для создания веб-страниц',
            },
            {
              'term': 'CSS',
              'definition': 'Язык стилей для оформления веб-страниц',
            },
            {
              'term': 'JavaScript',
              'definition': 'Язык программирования для веб-разработки',
            },
          ],
        },
        points: 15,
        tags: ['веб-разработка', 'термины'],
      ),
      InteractiveExercise(
        id: '3',
        title: 'Заполните пропуски',
        description: 'Вставьте правильные слова в текст',
        type: ExerciseType.fillInBlanks,
        content: {
          'text': 'Flutter - это фреймворк для создания [cross-platform] приложений. Он использует язык [Dart] и позволяет создавать [native] приложения для iOS и Android.',
          'answers': ['cross-platform', 'Dart', 'native'],
        },
        points: 10,
        tags: ['flutter', 'dart'],
      ),
      InteractiveExercise(
        id: '4',
        title: 'Сортировка компонентов',
        description: 'Расположите компоненты в правильном порядке',
        type: ExerciseType.dragAndDrop,
        content: {
          'items': [
            'Инициализация проекта',
            'Создание UI компонентов',
            'Настройка навигации',
            'Добавление бизнес-логики',
            'Тестирование',
            'Публикация',
          ],
          'correctOrder': [0, 1, 2, 3, 4, 5],
        },
        points: 15,
        timeLimit: 180,
        tags: ['разработка', 'процесс'],
      ),
      InteractiveExercise(
        id: '5',
        title: 'Напишите функцию',
        description: 'Реализуйте функцию для подсчета факториала',
        type: ExerciseType.codeChallenge,
        content: {
          'description': 'Напишите функцию, которая вычисляет факториал числа n',
          'template': 'int factorial(int n) {\n  // Ваш код здесь\n}',
          'testCases': [
            {'input': 5, 'output': 120},
            {'input': 0, 'output': 1},
            {'input': 1, 'output': 1},
          ],
        },
        points: 25,
        tags: ['программирование', 'алгоритмы'],
      ),
      InteractiveExercise(
        id: '6',
        title: 'Обсуждение архитектуры',
        description: 'Обсудите преимущества и недостатки различных архитектурных паттернов',
        type: ExerciseType.discussion,
        content: {
          'topic': 'Сравнение MVC, MVVM и Clean Architecture',
          'questions': [
            'Какие основные преимущества каждого подхода?',
            'В каких случаях лучше использовать каждый из паттернов?',
            'Какие сложности могут возникнуть при реализации?',
          ],
        },
        points: 20,
        tags: ['архитектура', 'обсуждение'],
      ),
      InteractiveExercise(
        id: '7',
        title: 'Разбор кейса: Оптимизация производительности',
        description: 'Проанализируйте и предложите решение проблемы производительности',
        type: ExerciseType.caseStudy,
        content: {
          'scenario': 'Мобильное приложение работает медленно при загрузке большого количества данных',
          'data': {
            'currentImplementation': '...',
            'metrics': {
              'loadTime': '5s',
              'memoryUsage': '200MB',
              'batteryImpact': 'High',
            },
          },
          'questions': [
            'Какие могут быть причины медленной работы?',
            'Какие оптимизации можно применить?',
            'Как измерить эффективность предложенных решений?',
          ],
        },
        points: 30,
        tags: ['производительность', 'оптимизация'],
      ),
    ];
  }

  // Отметка упражнения как выполненного
  Future<void> completeExercise(String userId, String exerciseId, {Map<String, dynamic>? answer}) async {
    // TODO: Реализовать сохранение ответа и обновление прогресса в Firebase
    print('Упражнение $exerciseId выполнено пользователем $userId');
    if (answer != null) {
      print('Ответ пользователя: $answer');
    }
  }

  Future<Map<String, dynamic>> validateAnswer(String exerciseId, Map<String, dynamic> answer) async {
    // TODO: Реализовать валидацию ответа
    return {
      'isCorrect': true,
      'score': 10,
      'feedback': 'Отличная работа!',
    };
  }
} 