type state = string
type symbol = char option

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

let epsilon_closure nfa states =
  let rec loop visited stack =
    match stack with
    | [] -> visited
    | state :: rest ->
        let next_states =
          TransitionMap.find_opt (state, None) nfa.transitions
          |> Option.value ~default:StateSet.empty
        in
        let new_states = StateSet.diff next_states visited in
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

let step nfa states sym = move nfa states sym |> epsilon_closure nfa

let process nfa input =
  String.fold_left
    (fun current sym -> step nfa current (Some sym))
    (epsilon_closure nfa (StateSet.singleton nfa.start))
    input

let accepts nfa input =
  process nfa input |> StateSet.inter nfa.accept |> StateSet.is_empty |> not

let trace nfa input =
  let rec loop current chars acc =
    match chars with
    | [] -> List.rev acc
    | sym :: rest ->
        let next = step nfa current (Some sym) in
        loop next rest ((current, sym, next) :: acc)
  in
  let start = epsilon_closure nfa (StateSet.singleton nfa.start) in
  loop start (String.to_seq input |> List.of_seq) []
