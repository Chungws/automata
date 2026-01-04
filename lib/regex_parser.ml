let rec parse_atom counter (tokens : Regex_lexer.token list) =
  match tokens with
  | Regex_lexer.TChar c :: rest -> (Regex_ast.Char c, rest, counter)
  | Regex_lexer.TCharClass (chars, neg) :: rest ->
      (Regex_ast.CharClass (chars, neg), rest, counter)
  | Regex_lexer.TDot :: rest -> (Regex_ast.Dot, rest, counter)
  | Regex_lexer.TCaret :: rest -> (Regex_ast.Anchor `Start, rest, counter)
  | Regex_lexer.TDollar :: rest -> (Regex_ast.Anchor `End, rest, counter)
  | Regex_lexer.TBackref n :: rest -> (Regex_ast.Backref n, rest, counter)
  | Regex_lexer.TLParen :: rest -> (
      let expr, rest', counter' = parse_expr (counter + 1) rest in
      match rest' with
      | Regex_lexer.TRParen :: rest'' ->
          (Regex_ast.Group (counter, expr), rest'', counter')
      | _ -> failwith "parse error: expected ')'")
  | _ -> failwith "parse error: expected atom"

and parse_repeat counter (tokens : Regex_lexer.token list) =
  let atom, rest, counter' = parse_atom counter tokens in
  match rest with
  | Regex_lexer.TStar :: rest' -> (Regex_ast.Star atom, rest', counter')
  | Regex_lexer.TPlus :: rest' -> (Regex_ast.Plus atom, rest', counter')
  | Regex_lexer.TQuestion :: rest' -> (Regex_ast.Option atom, rest', counter')
  | Regex_lexer.TRepeat (min, max) :: rest' ->
      (Regex_ast.Repeat (atom, min, max), rest', counter')
  | _ -> (atom, rest, counter')

and parse_concat counter (tokens : Regex_lexer.token list) =
  let left, rest, counter' = parse_repeat counter tokens in
  match rest with
  | Regex_lexer.TChar _ :: _
  | Regex_lexer.TLParen :: _
  | Regex_lexer.TDot :: _
  | Regex_lexer.TCaret :: _
  | Regex_lexer.TDollar :: _
  | Regex_lexer.TCharClass _ :: _
  | Regex_lexer.TBackref _ :: _ ->
      let right, rest', counter'' = parse_concat counter' rest in
      (Regex_ast.Concat (left, right), rest', counter'')
  | _ -> (left, rest, counter')

and parse_expr counter (tokens : Regex_lexer.token list) =
  let left, rest, counter' = parse_concat counter tokens in
  match rest with
  | Regex_lexer.TPipe :: rest' ->
      let right, rest'', counter'' = parse_expr counter' rest' in
      (Regex_ast.Alt (left, right), rest'', counter'')
  | _ -> (left, rest, counter')

let parse s =
  if String.length s = 0 then Regex_ast.Empty
  else
    let ast, _, _ = s |> Regex_lexer.tokenize |> parse_expr 1 in
    ast
