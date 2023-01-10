extension Snapshotting where Value: CaseIterable, Format == String  {
  /// A strategy for snapshotting the output for every input of a function. The format of the snapshot
  /// is a comma-separated value (CSV) file that shows the mapping of inputs to outputs.
  ///
  /// Parameter witness: A snapshotting value on the output of the function to be snapshot.
  /// Returns: A snapshot strategy on functions (Value) -> A that feeds every possible input into the
  ///          function and records the output into a CSV file.
//  public static func `func`<A>(into witness: Snapshotting<A, Format>) -> Snapshotting<(Value) -> A, Format> {
//    var snapshotting = Snapshotting<String, String>.lines.pullback { (f: @escaping (Value) -> A) in
//      var output = ""
//      for input in Value.allCases {
//        await output.append(#""\#(input)","\#(witness.snapshot(f(input)))"\n"#)
//      }
//      return output
//    }
//
//    snapshotting.pathExtension = "csv"
//
//    return snapshotting
//  }
}
