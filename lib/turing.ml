module IntMap = Map.Make (Int)

type tape = { cells : char IntMap.t; head : int; blank : char }

let empty_tape blank = { cells = IntMap.empty; head = 0; blank }

let read tape =
  IntMap.find_opt tape.head tape.cells |> Option.value ~default:tape.blank

let write symbol tape =
  { tape with cells = IntMap.add tape.head symbol tape.cells }

let move_left tape = { tape with head = tape.head - 1 }
let move_right tape = { tape with head = tape.head + 1 }
