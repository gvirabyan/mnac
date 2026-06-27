/// A minimal success/failure result type to avoid throwing across layers.
sealed class Result<T> {
  const Result();

  /// Whether this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns the value if [Success], otherwise null.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  /// Folds both branches into a single value.
  R fold<R>(R Function(T value) onSuccess, R Function(String message) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final message) => onFailure(message),
      };
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;
}
