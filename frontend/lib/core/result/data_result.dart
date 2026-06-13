sealed class DataResult<T> {
  const DataResult();
}

class Success<T> extends DataResult<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends DataResult<T> {
  final String message;
  const Error(this.message);
}
