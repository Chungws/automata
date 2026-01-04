let make_matcher text =
  let len = String.length text in
  let rec try_match ast pos captures =
    let match_progress a pos caps f =
      try_match a pos caps
      |> List.concat_map (fun (p, caps') ->
          if p > pos then f (p, caps') else [])
    in
    match ast with
    | Regex_ast.Empty -> [ (pos, captures) ]
    | Regex_ast.Char c ->
        if pos < len && text.[pos] = c then [ (pos + 1, captures) ] else []
    | Regex_ast.CharClass (chars, negate) ->
        if pos < len && List.mem text.[pos] chars <> negate then
          [ (pos + 1, captures) ]
        else []
    | Regex_ast.Dot -> if pos < len then [ (pos + 1, captures) ] else []
    | Regex_ast.Concat (a, b) ->
        try_match a pos captures
        |> List.concat_map (fun (p, caps) -> try_match b p caps)
    | Regex_ast.Alt (a, b) ->
        try_match a pos captures @ try_match b pos captures
    | Regex_ast.Group (n, a) ->
        try_match a pos captures
        |> List.map (fun (end_pos, caps) ->
            (end_pos, (n, (pos, end_pos)) :: caps))
    | Regex_ast.Star a -> try_match (Repeat (a, 0, None)) pos captures
    | Regex_ast.Plus a -> try_match (Repeat (a, 1, None)) pos captures
    | Regex_ast.Option a -> try_match (Repeat (a, 0, Some 1)) pos captures
    | Regex_ast.Anchor `Start -> if pos = 0 then [ (pos, captures) ] else []
    | Regex_ast.Anchor `End -> if pos = len then [ (pos, captures) ] else []
    | Regex_ast.Repeat (a, min, max) -> (
        if min > 0 then
          match_progress a pos captures (fun (p, caps) ->
              try_match
                (Repeat (a, min - 1, Option.map (fun n -> n - 1) max))
                p caps)
        else
          match max with
          | Some 0 -> [ (pos, captures) ]
          | _ ->
              (pos, captures)
              :: match_progress a pos captures (fun (p, caps) ->
                  try_match
                    (Repeat (a, 0, Option.map (fun n -> n - 1) max))
                    p caps))
    | Regex_ast.Backref n -> (
        match List.assoc_opt n captures with
        | None -> []
        | Some (s, d) ->
            let cap_len = d - s in
            if pos + cap_len <= len then
              let captured = String.sub text s cap_len in
              let this = String.sub text pos cap_len in
              if captured = this then [ (pos + cap_len, captures) ] else []
            else [])
  in
  try_match

let matches pattern text =
  let len = String.length text in
  let ast = Regex_parser.parse pattern in
  let try_match = make_matcher text in
  try_match ast 0 [] |> List.exists (fun (p, _) -> p = len)

let match_groups pattern text =
  let len = String.length text in
  let ast = Regex_parser.parse pattern in
  let try_match = make_matcher text in
  try_match ast 0 [] |> List.find_opt (fun (p, _) -> p = len) |> Option.map snd

let search pattern text =
  let len = String.length text in
  let ast = Regex_parser.parse pattern in
  let try_match = make_matcher text in
  let rec try_form pos =
    if pos > len then false
    else if try_match ast pos [] <> [] then true
    else try_form (pos + 1)
  in
  try_form 0

let find_match pattern text =
  let len = String.length text in
  let ast = Regex_parser.parse pattern in
  let try_match = make_matcher text in
  let rec try_form pos =
    if pos > len then None
    else
      let res = try_match ast pos [] in
      if res <> [] then
        let best =
          List.fold_left
            (fun acc (end_pos, caps) ->
              match acc with
              | None -> Some (end_pos, caps)
              | Some (best_end, _) ->
                  if end_pos > best_end then Some (end_pos, caps) else acc)
            None res
        in
        match best with
        | Some (end_pos, caps) -> Some (pos, end_pos, caps)
        | None -> try_form (pos + 1)
      else try_form (pos + 1)
  in
  try_form 0

let parse_escape ch =
  match ch with '1' .. '9' -> Some (Char.code ch - Char.code '0') | _ -> None

let expand_captures replacement captures text =
  let len = String.length replacement in
  let rec loop i acc =
    if i >= len then acc
    else if i < len - 1 && replacement.[i] = '\\' then
      match parse_escape replacement.[i + 1] with
      | Some n ->
          let captured =
            match List.assoc_opt n captures with
            | Some (s, e) -> String.sub text s (e - s)
            | None -> ""
          in
          loop (i + 2) (acc ^ captured)
      | None -> loop (i + 1) (acc ^ String.make 1 replacement.[i])
    else loop (i + 1) (acc ^ String.make 1 replacement.[i])
  in
  loop 0 ""

let replace pattern replacement text =
  let len = String.length text in
  match find_match pattern text with
  | None -> text
  | Some (start, end_pos, captures) ->
      let expanded = expand_captures replacement captures text in
      String.sub text 0 start ^ expanded
      ^ String.sub text end_pos (len - end_pos)
