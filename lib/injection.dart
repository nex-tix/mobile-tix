// import 'package:get_it/get_it.dart';

// Service locator / dependency injection setup
// final getIt = GetIt.instance;

// Future<void> setupInjection() async {
// Core services
// getIt.registerLazySingleton<Dio>(() => DioClient.create());
// getIt.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
// getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());

// Repositories
// getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(...));
// getIt.registerLazySingleton<CheckpointRepository>(() => CheckpointRepositoryImpl(...));
// getIt.registerLazySingleton<ScannerRepository>(() => ScannerRepositoryImpl(...));
// getIt.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(...));
// getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(...));

// Use cases
// getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
// getIt.registerLazySingleton(() => GetCheckpointsUseCase(getIt<CheckpointRepository>()));
// getIt.registerLazySingleton(() => ScanTicketUseCase(getIt<ScannerRepository>()));
// getIt.registerLazySingleton(() => CheckTicketUseCase(getIt<ScannerRepository>()));
// getIt.registerLazySingleton(() => GetDashboardUseCase(getIt<DashboardRepository>()));
// getIt.registerLazySingleton(() => GetHistoryUseCase(getIt<HistoryRepository>()));

// Providers
// getIt.registerFactory(() => AuthProvider(getIt<LoginUseCase>(), getIt<GetMeUseCase>(), ...));
// getIt.registerFactory(() => CheckpointProvider(getIt<GetCheckpointsUseCase>(), ...));
// getIt.registerFactory(() => ScannerProvider(getIt<ScanTicketUseCase>(), getIt<CheckTicketUseCase>(), ...));
// getIt.registerFactory(() => DashboardProvider(getIt<GetDashboardUseCase>()));
// getIt.registerFactory(() => HistoryProvider(getIt<GetHistoryUseCase>()));
// }
