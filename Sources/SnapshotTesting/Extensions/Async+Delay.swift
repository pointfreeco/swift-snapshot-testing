import Foundation

extension Async {
  /// Delays Async `run` block
  /// - Parameter timeInterval: Optional duration for Async to wait before running `run`
  /// - Returns: Delayed `Async` unless no duration was provided then returns original `Async`
  func delay(by timeInterval: TimeInterval?) -> Async<Value> {
    guard let timeInterval = timeInterval else {
      return self
    }
    
    return Async<Value> { callback in
      run { value in
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
          callback(value)
        }
      }
    }
  }
}
