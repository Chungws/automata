type state = string
type symbol = char
type direction = Left | Right
type transition = state * symbol * direction
type status = Running | Accepted | Rejected | Timeout

module TransitionKey = struct
  type t = state * symbol

  let compare = compare
end

module IntMap = Map.Make (Int)
module TransitionMap = Map.Make (TransitionKey)

type t = {
  start : state;
  accept : state;
  reject : state;
  blank : symbol;
  transitions : transition TransitionMap.t;
}

type tape = { cells : char IntMap.t; head : int; blank : char }

let empty_tape blank = { cells = IntMap.empty; head = 0; blank }

let read tape =
  IntMap.find_opt tape.head tape.cells |> Option.value ~default:tape.blank

let write symbol tape =
  { tape with cells = IntMap.add tape.head symbol tape.cells }

let move_left tape = { tape with head = tape.head - 1 }
let move_right tape = { tape with head = tape.head + 1 }

let move dir tape =
  match dir with Left -> move_left tape | Right -> move_right tape

let init_head tape = { tape with head = 0 }

let make_tm start accept reject blank transitions =
  { start; accept; reject; blank; transitions }

let get_transition tm state symbol =
  TransitionMap.find_opt (state, symbol) tm.transitions

let of_input text blank =
  let tape = empty_tape blank in
  text |> String.to_seq
  |> Seq.fold_left (fun acc ch -> move_right (write ch acc)) tape
  |> init_head

let step tm state tape =
  if state = tm.accept then (Accepted, state, tape)
  else if state = tm.reject then (Rejected, state, tape)
  else
    let symbol = read tape in
    match get_transition tm state symbol with
    | None -> (Rejected, state, tape)
    | Some (new_state, sym, dir) ->
        let new_tape = tape |> write sym |> move dir in
        (Running, new_state, new_tape)

let run (tm : t) text step_limit =
  let tape = of_input text tm.blank in
  let rec loop i state tape =
    if i = step_limit then Timeout
    else
      let status, new_state, new_tape = step tm state tape in
      match status with
      | Running -> loop (i + 1) new_state new_tape
      | _ -> status
  in
  loop 0 tm.start tape
