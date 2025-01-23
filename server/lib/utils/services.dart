class Services {
  static final _locator = Services._internal();
  factory Services() => _locator;

  Services._internal();

  final Map<Type, dynamic> _serviceMap = {};

  void registerSingleton<T>(T instance) {
    _serviceMap[T] = instance;
  }

  void registerFactory<T>(T Function() factory) {
    _serviceMap[T] = factory;
  }

  T get<T>() {
    final service = _serviceMap[T];

    if (service == null) {
      throw Exception('Serviço do tipo $T não foi registrado.');
    }

    if (service is T Function()) {
      return service();
    }

    return service as T;
  }
}
