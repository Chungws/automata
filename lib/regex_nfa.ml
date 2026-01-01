type fragment = {
  start : string;
  accept : string;
  transitions : (string * Nfa.symbol * string) list;
}

module CharSet = Set.Make (Char)

let default_alphabet =
  Regex_lexer.range 'a' 'z' @ Regex_lexer.range 'A' 'Z'
  @ Regex_lexer.range '0' '9'

let counter = ref 0

let new_state () =
  let n = !counter in
  counter := n + 1;
  "s" ^ string_of_int n

let simple_frag symbol =
  let start = new_state () in
  let accept = new_state () in
  { start; accept; transitions = [ (start, symbol, accept) ] }

let char_frag ch = simple_frag (Nfa.Char ch)

let char_class_frag alphabet chars negate =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    if negate then
      let char_set = CharSet.of_list chars in
      alphabet
      |> List.filter (fun ch -> not (CharSet.mem ch char_set))
      |> List.map (fun ch -> (start, Nfa.Char ch, accept))
    else chars |> List.map (fun ch -> (start, Nfa.Char ch, accept))
  in
  { start; accept; transitions }

let empty_frag () = simple_frag Nfa.Epsilon

let concat_frag a b =
  let start = a.start in
  let accept = b.accept in
  let transitions =
    a.transitions @ b.transitions @ [ (a.accept, Nfa.Epsilon, b.start) ]
  in
  { start; accept; transitions }

let alt_frag a b =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, Nfa.Epsilon, a.start);
      (start, Nfa.Epsilon, b.start);
      (a.accept, Nfa.Epsilon, accept);
      (b.accept, Nfa.Epsilon, accept);
    ]
    @ a.transitions @ b.transitions
  in
  { start; accept; transitions }

let star_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, Nfa.Epsilon, a.start);
      (start, Nfa.Epsilon, accept);
      (a.accept, Nfa.Epsilon, a.start);
      (a.accept, Nfa.Epsilon, accept);
    ]
    @ a.transitions
  in
  { start; accept; transitions }

let plus_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, Nfa.Epsilon, a.start);
      (a.accept, Nfa.Epsilon, a.start);
      (a.accept, Nfa.Epsilon, accept);
    ]
    @ a.transitions
  in
  { start; accept; transitions }

let option_frag a =
  let start = new_state () in
  let accept = new_state () in
  let transitions =
    [
      (start, Nfa.Epsilon, a.start);
      (start, Nfa.Epsilon, accept);
      (a.accept, Nfa.Epsilon, accept);
    ]
    @ a.transitions
  in
  { start; accept; transitions }

let rec repeat_n factory n =
  match n with
  | 0 -> empty_frag ()
  | 1 -> factory ()
  | _ -> concat_frag (factory ()) (repeat_n factory (n - 1))

let rec repeat_optional factory n =
  match n with
  | 0 -> empty_frag ()
  | _ ->
      concat_frag (option_frag (factory ())) (repeat_optional factory (n - 1))

let repeat_frag factory min max =
  let min_a = repeat_n factory min in
  let max_a =
    match max with
    | Some m -> repeat_optional factory (m - min)
    | None -> star_frag (factory ())
  in
  concat_frag min_a max_a

let dot_frag alphabet = char_class_frag alphabet [] true
let anchor_frag anchor = simple_frag anchor

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
  | Regex_ast.Repeat (a, min, max) ->
      repeat_frag (fun () -> ast_to_fragment a) min max
  | Regex_ast.Group a -> ast_to_fragment a
  | Regex_ast.CharClass (chars, negate) ->
      char_class_frag default_alphabet chars negate
  | Regex_ast.Dot -> dot_frag default_alphabet
  | Regex_ast.Anchor `Start -> anchor_frag Nfa.StartAnchor
  | Regex_ast.Anchor `End -> anchor_frag Nfa.EndAnchor

let to_nfa frag : Nfa.t =
  let states =
    frag.transitions
    |> List.concat_map (fun (s, _, d) -> [ s; d ])
    |> List.sort_uniq String.compare
    |> Nfa.StateSet.of_list
  in
  let alphabet =
    frag.transitions
    |> List.filter_map (fun (_, sym, _) ->
        match sym with Nfa.Char sym -> Some sym | _ -> None)
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

let has_anchor which ast =
  let rec check ast =
    match ast with
    | Regex_ast.Anchor a when a = which -> true
    | Regex_ast.Concat (a, b) -> check (if which = `Start then a else b)
    | Regex_ast.Alt (a, b) -> check a && check b
    | Regex_ast.Group a -> check a
    | _ -> false
  in
  check ast

let has_start_anchor ast = has_anchor `Start ast
let has_end_anchor ast = has_anchor `End ast

let prepend_dot_star frag =
  let new_start = new_state () in
  let loop_transitions =
    List.map (fun ch -> (new_start, Nfa.Char ch, new_start)) default_alphabet
  in
  let epsilon_to_orig = (new_start, Nfa.Epsilon, frag.start) in
  {
    start = new_start;
    accept = frag.accept;
    transitions = (epsilon_to_orig :: loop_transitions) @ frag.transitions;
  }

let append_dot_star frag =
  let new_accept = new_state () in
  let loop_transitions =
    List.map (fun ch -> (new_accept, Nfa.Char ch, new_accept)) default_alphabet
  in
  let epsilon_to_orig = (frag.accept, Nfa.Epsilon, new_accept) in
  {
    start = frag.start;
    accept = new_accept;
    transitions = (epsilon_to_orig :: loop_transitions) @ frag.transitions;
  }

let search pattern text =
  counter := 0;
  let ast = Regex_parser.parse pattern in
  let frag = ast_to_fragment ast in
  let with_prefix =
    if has_start_anchor ast then frag else prepend_dot_star frag
  in
  let with_suffix =
    if has_end_anchor ast then with_prefix else append_dot_star with_prefix
  in
  let nfa = to_nfa with_suffix in
  Nfa.accepts nfa text
