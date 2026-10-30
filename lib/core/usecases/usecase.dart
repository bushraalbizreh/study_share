/// Base use case abstraction used by feature use cases.
abstract class UseCase<ReturnType, Params> {
  Future<ReturnType> execute(Params params);
}


