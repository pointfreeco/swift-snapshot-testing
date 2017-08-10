public enum Diff<A> {
  case fst(A)
  case snd(A)
  case tup(A, A)
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
    return fst.map(Diff.fst) + snd.map(Diff.snd)
  } else {
    return diff(Array(fst.prefix(upTo: fstIdx)), Array(snd.prefix(upTo: sndIdx)))
      + zip(fst.suffix(from: fstIdx).prefix(len), snd.suffix(from: sndIdx).prefix(len)).map(Diff.tup)
      + diff(Array(fst.suffix(from: fstIdx + len)), Array(snd.suffix(from: sndIdx + len)))
  }
}
