import 'package:get_it/get_it.dart';
import 'package:app_links/app_links.dart';
import 'package:projects/services/cloud_service.dart';
import 'package:projects/services/auth_service.dart';

import '../repositories/card_repository.dart';
import '../repositories/card_repository_impl.dart';
import '../repositories/label_repository.dart';
import '../repositories/label_repository_impl.dart';
import '../repositories/set_repository.dart';
import '../repositories/set_repository_impl.dart';
import '../services/database_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);
  locator.registerLazySingleton(() => AppLinks());
  locator.registerLazySingleton(() => CloudService());
  locator.registerLazySingleton(() => AuthService());


  // Repositories
  locator.registerLazySingleton<ICardRepository>(
    () => CardRepositoryImpl(locator<DatabaseService>()),
  );
  locator.registerLazySingleton<ILabelRepository>(
    () => LabelRepositoryImpl(locator<DatabaseService>()),
  );
  locator.registerLazySingleton<ISetRepository>(
    () => SetRepositoryImpl(locator<DatabaseService>(), locator<ICardRepository>(), locator<CloudService>()),
  );
}
