type fragment = {
  start : string;
  accept : string;
  transitions : (string * char option * string) list;
}

let counter = ref 0

let new_state () =
  let n = !counter in
  counter := n + 1;
  "s" ^ string_of_int n

let char_frag ch =
  let start = new_state () in
  let accept = new_state () in
  { start; accept; transitions = [ (start, Some ch, accept) ] }

let empty_frag () =
  let start = new_state () in
  let accept = new_state () in
  { start; accept; transitions = [ (start, None, accept) ] }

let concat_frag a b =
  let start = a.start in
  let accept = b.accept in
  let transitions =
    a.transitions @ b.transitions @ [ (a.accept, None, b.start) ]
  in
  { start; accept; transitions }

let alt_frag a b =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, None, a.start);
      (start, None, b.start);
      (a.accept, None, accept);
      (b.accept, None, accept);
    ]
    @ a.transitions @ b.transitions
  in
  { start; accept; transitions }

let star_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, None, a.start);
      (start, None, accept);
      (a.accept, None, a.start);
      (a.accept, None, accept);
    ]
    @ a.transitions
  in
  { start; accept; transitions }

let plus_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, None, a.start); (a.accept, None, a.start); (a.accept, None, accept);
    ]
    @ a.transitions
  in
  { start; accept; transitions }

let option_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [ (start, None, a.start); (start, None, accept); (a.accept, None, accept) ]
    @ a.transitions
  in
  { start; accept; transitions }

let rec ast_to_fragment ast =
  match ast with
  | Regex_ast.Char c -> char_frag c
  | Regex_ast.Empty -> empty_frag ()
  | Regex_ast.Concat (a, b) ->
      concat_frag (ast_to_fragment a) (ast_to_fragment b)
  | Regex_ast.Alt (a, b) -> alt_frag (ast_to_fragment a) (ast_to_fragment b)
  | Regex_ast.Star a -> star_frag (ast_to_fragment a)
  | Regex_ast.Plus a -> plus_frag (ast_to_fragment a)
  | Regex_ast.Option a -> option_frag (ast_to_fragment a)
  | Regex_ast.Group a -> ast_to_fragment a

let to_nfa frag : Nfa.t =
  let states =
    frag.transitions
    |> List.concat_map (fun (s, _, d) -> [ s; d ])
    |> List.sort_uniq String.compare
    |> Nfa.StateSet.of_list
  in
  let alphabet =
    frag.transitions
    |> List.filter_map (fun (_, sym, _) -> sym)
    |> List.sort_uniq Char.compare
  in
  let transitions =
    List.fold_left
      (fun map (src, sym, dst) ->
        let key = (src, sym) in
        let existing =
          Nfa.TransitionMap.find_opt key map
          |> Option.value ~default:Nfa.StateSet.empty
        in
        Nfa.TransitionMap.add key (Nfa.StateSet.add dst existing) map)
      Nfa.TransitionMap.empty frag.transitions
  in
  {
    states;
    alphabet;
    start = frag.start;
    accept = Nfa.StateSet.singleton frag.accept;
    transitions;
  }

let compile pattern =
  counter := 0;
  pattern |> Regex_parser.parse |> ast_to_fragment |> to_nfa

let matches pattern text =
  let nfa = compile pattern in
  Nfa.accepts nfa text
