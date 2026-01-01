type state = string
type symbol = Char of char | Epsilon | StartAnchor | EndAnchor

module StateSet = Set.Make (String)

module TransitionKey = struct
  type t = state * symbol

  let compare = compare
end

module TransitionMap = Map.Make (TransitionKey)

type t = {
  states : StateSet.t;
  alphabet : char list;
  start : state;
  accept : StateSet.t;
  transitions : StateSet.t TransitionMap.t;
}

let epsilon_closure nfa states ~pos ~len =
  let rec loop visited stack =
    match stack with
    | [] -> visited
    | state :: rest ->
        let find_transitions key =
          nfa.transitions |> TransitionMap.find_opt key
          |> Option.value ~default:StateSet.empty
        in
        let combined_states =
          [ (pos = 0, StartAnchor); (pos = len, EndAnchor); (true, Epsilon) ]
          |> List.filter_map (fun (cond, sym) ->
              if cond then Some (find_transitions (state, sym)) else None)
          |> List.fold_left StateSet.union StateSet.empty
        in
        let new_states = StateSet.diff combined_states visited in
        let visited' = StateSet.union visited new_states in
        let stack' = StateSet.elements new_states @ rest in
        loop visited' stack'
  in
  loop states (StateSet.elements states)

let move nfa states sym =
  StateSet.fold
    (fun state states' ->
      TransitionMap.find_opt (state, sym) nfa.transitions
      |> Option.value ~default:StateSet.empty
      |> StateSet.union states')
    states StateSet.empty

let step nfa states sym ~pos ~len =
  move nfa states sym |> epsilon_closure nfa ~pos ~len

let process nfa input =
  let len = String.length input in
  let rec loop states pos =
    if pos >= len then states
    else
      let sym = input.[pos] in
      let next = step nfa states (Char sym) ~pos:(pos + 1) ~len in
      loop next (pos + 1)
  in
  let start = epsilon_closure nfa (StateSet.singleton nfa.start) ~pos:0 ~len in
  loop start 0

let accepts nfa input =
  process nfa input |> StateSet.inter nfa.accept |> StateSet.is_empty |> not

let trace nfa input =
  let len = String.length input in
  let rec loop current chars acc pos =
    match chars with
    | [] -> List.rev acc
    | sym :: rest ->
        let next = step nfa current (Char sym) ~pos:(pos + 1) ~len in
        loop next rest ((current, sym, next) :: acc) (pos + 1)
  in
  let start = epsilon_closure nfa (StateSet.singleton nfa.start) ~pos:0 ~len in
  loop start (String.to_seq input |> List.of_seq) [] 0
