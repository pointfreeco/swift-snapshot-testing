import Foundation

precedencegroup CompositionPrecedence {
  associativity: right
}

infix operator >>>: CompositionPrecedence

func >>> <Inout, Input1, Input2, Output>(lhs: @escaping (inout Inout, Input1) -> Input2, rhs: @escaping (inout Inout, Input2) -> Output) -> (inout Inout, Input1) -> (Output) {
  return { inOut, input1 in
    return rhs(&inOut, lhs(&inOut, input1))
  }
}

func >>> <Inout, Input1, Input2, Output>(lhs: @escaping (Input1) -> (Input2), rhs: @escaping (inout Inout, Input2) -> Output) -> (inout Inout, Input1) -> (Output) {
  return { inOut, input1 in
    return rhs(&inOut, lhs(input1))
  }
}

func >>> <Inout, Input, Output>(input: Input, f: @escaping (inout Inout, Input) -> Output) -> (inout Inout) -> (Output) {
  return { inOut in
    return f(&inOut, input)
  }
}
