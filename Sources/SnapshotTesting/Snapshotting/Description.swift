extension Snapshotting where Format == String {
  public static var description: Snapshotting {
    return SimplySnapshotting.lines.pullback(String.init(describing:))
  }
}
