type state = string
type symbol = char

exception Invalid_dfa of string

module TransitionKey = struct
  type t = state * symbol

  let compare = compare
end

module TransitionMap = Map.Make (TransitionKey)

type t = {
  states : state list;
  alphabet : symbol list;
  start : state;
  accept : state list;
  transitions : state TransitionMap.t;
}

let create states alphabet start accept transitions =
  if not (List.mem start states) then
    raise (Invalid_dfa "start state not in states");

  if not (List.for_all (fun s -> List.mem s states) accept) then
    raise (Invalid_dfa "accept state not in states");

  let trans_map =
    List.fold_left
      (fun map (key, value) -> TransitionMap.add key value map)
      TransitionMap.empty transitions
  in
  { states; alphabet; start; accept; transitions = trans_map }

let transition dfa current sym =
  TransitionMap.find (current, sym) dfa.transitions

let process dfa input =
  String.fold_left
    (fun current sym -> transition dfa current sym)
    dfa.start input

let accepts dfa input = List.mem (process dfa input) dfa.accept

let trace dfa input =
  let rec loop current chars acc =
    match chars with
    | [] -> List.rev acc
    | sym :: rest ->
        let next = transition dfa current sym in
        loop next rest ((current, sym, next) :: acc)
  in
  loop dfa.start (String.to_seq input |> List.of_seq) []
