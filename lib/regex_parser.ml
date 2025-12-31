let rec parse_atom (tokens : Regex_lexer.token list) =
  match tokens with
  | Regex_lexer.TChar c :: rest -> (Regex_ast.Char c, rest)
  | Regex_lexer.TLParen :: rest -> (
      let expr, rest' = parse_expr rest in
      match rest' with
      | Regex_lexer.TRParen :: rest'' -> (expr, rest'')
      | _ -> failwith "parse error: expected ')'")
  | _ -> failwith "parse error: expected atom"

and parse_repeat (tokens : Regex_lexer.token list) =
  let atom, rest = parse_atom tokens in
  match rest with
  | Regex_lexer.TStar :: rest' -> (Regex_ast.Star atom, rest')
  | Regex_lexer.TPlus :: rest' -> (Regex_ast.Plus atom, rest')
  | Regex_lexer.TQuestion :: rest' -> (Regex_ast.Option atom, rest')
  | _ -> (atom, rest)

and parse_concat (tokens : Regex_lexer.token list) =
  let left, rest = parse_repeat tokens in
  match rest with
  | Regex_lexer.TChar _ :: _ | Regex_lexer.TLParen :: _ ->
      let right, rest' = parse_concat rest in
      (Regex_ast.Concat (left, right), rest')
  | _ -> (left, rest)

and parse_expr (tokens : Regex_lexer.token list) =
  let left, rest = parse_concat tokens in
  match rest with
  | Regex_lexer.TPipe :: rest' ->
      let right, rest'' = parse_expr rest' in
      (Regex_ast.Alt (left, right), rest'')
  | _ -> (left, rest)

let parse s =
  if String.length s = 0 then Regex_ast.Empty
  else
    let ast, _ = s |> Regex_lexer.tokenize |> parse_expr in
    ast
