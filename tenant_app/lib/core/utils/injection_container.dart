import 'package:get_it/get_it.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/logic/auth_cubit.dart';
import '../services/auth_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authService: getIt()),
  );

  // Cubits / Logic
  // Cubits are typically registered as factories if they need to be disposed
  // and recreated, but since AuthCubit is global and lasts the app's lifetime,
  // lazy singleton is appropriate here.
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: getIt()),
  );
}
