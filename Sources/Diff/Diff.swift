public enum DiffType {
  case first
  case second
  case both
}

public struct Diff<A> {
  public let type: DiffType
  public let elements: [A]
}

public func diff<A: Hashable>(_ fst: [A], _ snd: [A]) -> [Diff<A>] {
  var idxsOf = [A: [Int]]()
  fst.enumerated().forEach { idxsOf[$1, default: []].append($0) }

  let sub = snd.enumerated().reduce((overlap: [Int: Int](), fst: 0, snd: 0, len: 0)) { sub, sndPair in
    (idxsOf[sndPair.element] ?? [])
      .reduce((overlap: [Int: Int](), fst: sub.fst, snd: sub.snd, len: sub.len)) { innerSub, fstIdx in

        var newOverlap = innerSub.overlap
        newOverlap[fstIdx] = (sub.overlap[fstIdx - 1] ?? 0) + 1

        if let newLen = newOverlap[fstIdx], newLen > sub.len {
          return (newOverlap, fstIdx - newLen + 1, sndPair.offset - newLen + 1, newLen)
        }
        return (newOverlap, innerSub.fst, innerSub.snd, innerSub.len)
    }
  }
  let (_, fstIdx, sndIdx, len) = sub

  if len == 0 {
    let fstDiff = fst.isEmpty ? [] : [Diff(type: .first, elements: fst)]
    let sndDiff = snd.isEmpty ? [] : [Diff(type: .second, elements: snd)]
    return fstDiff + sndDiff
  } else {
    return diff(Array(fst.prefix(upTo: fstIdx)), Array(snd.prefix(upTo: sndIdx)))
      + [Diff(type: .both, elements: Array(fst.suffix(from: fstIdx).prefix(len)))]
      + diff(Array(fst.suffix(from: fstIdx + len)), Array(snd.suffix(from: sndIdx + len)))
  }
}

private let minus = "−"
private let plus = "+"
private let figureSpace = "\u{2007}"

public struct Hunk {
  public fileprivate(set) var fstIdx: Int = 0
  public fileprivate(set) var fstLen: Int = 0
  public fileprivate(set) var sndIdx: Int = 0
  public fileprivate(set) var sndLen: Int = 0
  public fileprivate(set) var lines: [String] = []

  public var patchMark: String {
    let fstMark = "\(minus)\(fstIdx + 1),\(fstLen)"
    let sndMark = "\(plus)\(sndIdx + 1),\(sndLen)"
    return "@@ \(fstMark) \(sndMark) @@"
  }
}

public func chunk<S: StringProtocol>(diff diffs: [Diff<S>], context ctx: Int = 4) -> [Hunk] {
  func prepending(_ prefix: String) -> (S) -> String {
    return { prefix + $0 + ($0.hasSuffix(" ") ? "¬" : "") }
  }

  let (hunk, hunks) = diffs
    .reduce((current: Hunk(), hunks: [Hunk]())) { cursor, diff in
      var (current, hunks) = cursor
      let len = diff.elements.count

      switch diff.type {
      case .both:
        if len > ctx * 2 {
          current.fstLen += ctx
          current.sndLen += ctx
          current.lines.append(contentsOf: diff.elements.prefix(ctx).map(prepending(figureSpace)))
          if current.lines.contains(where: { $0.hasPrefix(minus) || $0.hasPrefix(plus) }) {
            hunks.append(current)
          }

          current.fstIdx += len + 1
          current.fstLen = ctx
          current.sndIdx += len + 1
          current.sndLen = ctx
          current.lines = (diff.elements.suffix(ctx) as ArraySlice<S>).map(prepending(figureSpace))
        } else if current.lines.isEmpty {
          let lines = (diff.elements.suffix(ctx) as ArraySlice<S>).map(prepending(figureSpace))
          let count = lines.count
          current.fstIdx += len - count
          current.fstLen += count
          current.sndIdx += len - count
          current.sndLen += count
          current.lines.append(contentsOf: lines)
        } else {
          current.fstLen += len
          current.sndLen += len
          current.lines.append(contentsOf: diff.elements.map(prepending(figureSpace)))
        }
        return (current, hunks)
      case .first:
        current.fstLen += len
        current.lines.append(contentsOf: diff.elements.map(prepending(minus)))
      case .second:
        current.sndLen += len
        current.lines.append(contentsOf: diff.elements.map(prepending(plus)))
      }

      return (current, hunks)
  }

  return hunk.lines.contains(where: { $0.hasPrefix(minus) || $0.hasPrefix(plus) })
    ? hunks + [hunk]
    : hunks
}
