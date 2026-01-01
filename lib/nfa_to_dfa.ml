module StringSet = Set.Make (String)

let state_set_to_string states =
  "{" ^ (Nfa.StateSet.elements states |> String.concat ",") ^ "}"

let is_accept_state (nfa : Nfa.t) state_set =
  not (Nfa.StateSet.disjoint nfa.accept state_set)

let compute_reachable nfa =
  let start =
    Nfa.epsilon_closure nfa (Nfa.StateSet.singleton nfa.start) ~pos:0 ~len:0
  in
  let rec loop visited result queue =
    match queue with
    | [] -> result
    | cur :: rest ->
        let cur_name = state_set_to_string cur in
        if StringSet.mem cur_name visited then loop visited result rest
        else
          let visited' = StringSet.add cur_name visited in
          let result' = cur :: result in
          let nexts =
            List.map
              (fun ch -> Nfa.step nfa cur (Char ch) ~pos:0 ~len:0)
              nfa.alphabet
          in
          loop visited' result' (nexts @ rest)
  in
  loop StringSet.empty [] [ start ]

let build_transitions nfa reachable =
  reachable |> List.to_seq
  |> Seq.flat_map (fun state_set ->
      nfa.alphabet |> List.to_seq |> Seq.map (fun ch -> (state_set, ch)))
  |> Seq.fold_left
       (fun trans (state_set, ch) ->
         let next = Nfa.step nfa state_set (Char ch) ~pos:0 ~len:0 in
         Dfa.TransitionMap.add
           (state_set_to_string state_set, ch)
           (state_set_to_string next) trans)
       Dfa.TransitionMap.empty

let convert (nfa : Nfa.t) : Dfa.t =
  let start =
    Nfa.epsilon_closure nfa (Nfa.StateSet.singleton nfa.start) ~pos:0 ~len:0
  in
  let reachable = compute_reachable nfa in
  let transitions = build_transitions nfa reachable in
  let is_accept = is_accept_state nfa in
  let accepts =
    List.filter_map
      (fun state_set ->
        if is_accept state_set then Some (state_set_to_string state_set)
        else None)
      reachable
  in
  {
    states = List.map state_set_to_string reachable;
    alphabet = nfa.alphabet;
    start = state_set_to_string start;
    accept = accepts;
    transitions;
  }
