import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// События
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitializedEvent extends AuthEvent {}

class AuthSignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthSignUpEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthSignInEvent extends AuthEvent {
  final String? email;
  final String? password;
  final User? user;

  const AuthSignInEvent({
    required this.email,
    required this.password,
  }) : user = null;
  
  // Конструктор для создания события из модели User
  const AuthSignInEvent.fromUser(this.user)
      : email = null,
        password = null;

  @override
  List<Object?> get props => [email, password, user];
}

class AuthSignOutEvent extends AuthEvent {}

class AuthUpdateUserEvent extends AuthEvent {
  final User user;

  const AuthUpdateUserEvent({required this.user});

  @override
  List<Object?> get props => [user];
}

// Состояния
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final User user;

  const AuthAuthenticatedState(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  AuthBloc({
    required AuthService authService,
  })  : _authService = authService,
        super(AuthInitialState()) {
    on<AuthInitializedEvent>(_onInitialized);
    on<AuthSignUpEvent>(_onSignUp);
    on<AuthSignInEvent>(_onSignIn);
    on<AuthSignOutEvent>(_onSignOut);
    on<AuthUpdateUserEvent>(_onUpdateUser);

    // Подписка на изменения статуса аутентификации без перезапуска инициализации
    _authSubscription = _authService.userStream.listen((user) {
      _onUserChanged(user);
    });

    // Вызываем инициализацию только один раз при создании блока
    add(AuthInitializedEvent());
  }

  Future<void> _onInitialized(
    AuthInitializedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    
    await _authService.init();
    final user = _authService.currentUser;
    
    if (user != null) {
      emit(AuthAuthenticatedState(user));
    } else {
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignUp(
    AuthSignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    
    final result = await _authService.signUp(
      email: event.email,
      password: event.password,
      name: event.name,
    );
    
    if (result.isSuccess && result.user != null) {
      emit(AuthAuthenticatedState(result.user!));
    } else {
      emit(AuthErrorState(result.error ?? 'Ошибка при регистрации'));
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignIn(
    AuthSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    
    // Если есть готовый пользователь (например, из Google Sign In)
    if (event.user != null) {
      emit(AuthAuthenticatedState(event.user!));
      return;
    }
    
    // Иначе выполняем стандартный вход с email и паролем
    final result = await _authService.signIn(
      email: event.email!,
      password: event.password!,
    );
    
    if (result.isSuccess && result.user != null) {
      emit(AuthAuthenticatedState(result.user!));
    } else {
      emit(AuthErrorState(result.error ?? 'Ошибка при входе'));
      emit(AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignOut(
    AuthSignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    
    await _authService.signOut();
    emit(AuthUnauthenticatedState());
  }

  Future<void> _onUpdateUser(
    AuthUpdateUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    
    final result = await _authService.updateUser(event.user);
    
    if (result.isSuccess) {
      emit(AuthAuthenticatedState(event.user));
    } else {
      emit(AuthErrorState(result.error ?? 'Ошибка при обновлении данных пользователя'));
      emit(AuthUnauthenticatedState());
    }
  }

  // Метод для обработки события успешной аутентификации
  void _onUserChanged(User? user) {
    if (user != null) {
      // Успешная аутентификация, пользователь авторизован
      print("AuthBloc: пользователь авторизован, id=${user.id}");
      emit(AuthAuthenticatedState(user));
      
      // Здесь можно добавить дополнительную логику для загрузки данных пользователя из Firestore
    } else {
      // Пользователь не авторизован
      print("AuthBloc: пользователь не авторизован");
      emit(AuthUnauthenticatedState());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
} 