struct SnapshotURL: Sendable, Hashable {

    let path: StaticString

    init(path: StaticString) {
        self.path = path
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        String(describing: lhs.path) == String(describing: rhs.path)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: path))
    }
}
