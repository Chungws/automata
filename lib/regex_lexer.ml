type token =
  | TChar of char
  | TCharClass of char list * bool
  | TStar
  | TPlus
  | TQuestion
  | TPipe
  | TLParen
  | TRParen
  | TDot
  | TCaret
  | TDollar
  | TRepeat of int * int option
  | TEOF

let char_to_tok ch =
  match ch with
  | '*' -> TStar
  | '+' -> TPlus
  | '?' -> TQuestion
  | '|' -> TPipe
  | '(' -> TLParen
  | ')' -> TRParen
  | '.' -> TDot
  | '^' -> TCaret
  | '$' -> TDollar
  | ch -> TChar ch

let escape_char ch =
  match ch with 'n' -> '\n' | 't' -> '\t' | 'r' -> '\r' | c -> c

let parse_escape ch =
  match ch with
  | '*' | '+' | '.' | '?' | '|' | '(' | ')' | '{' | '}' | '[' | ']' | '\\' | '^'
  | '$' | 'n' | 't' | 'r' ->
      TChar (escape_char ch)
  | _ -> failwith "Invalid Escape"

let range start_char end_char =
  List.init
    (Char.code end_char - Char.code start_char + 1)
    (fun i -> Char.chr (Char.code start_char + i))

let parse_char_class chars =
  let negate, chars' =
    match chars with '^' :: rest -> (true, rest) | _ -> (false, chars)
  in
  let prefix_chars, chars' =
    match chars' with
    | ']' :: rest -> ([ ']' ], rest)
    | '-' :: rest -> ([ '-' ], rest)
    | _ -> ([], chars')
  in
  let rec loop acc chars =
    match chars with
    | [] -> failwith "Unclosed character class: missing ']'"
    | ']' :: rest -> (acc, rest)
    | '\\' :: next :: rest -> loop (escape_char next :: acc) rest
    | '\\' :: [] -> failwith "Escape at end of character class"
    | ch :: '-' :: d :: rest when d <> ']' -> loop (range ch d @ acc) rest
    | ch :: rest -> loop (ch :: acc) rest
  in
  let acc, rest = loop [] chars' in
  (prefix_chars @ acc, negate, rest)

let is_digit ch = ch >= '0' && ch <= '9'

let parse_number chars =
  let rec loop acc chars =
    match chars with
    | n :: rest when is_digit n ->
        let num = Char.code n - Char.code '0' in
        loop ((acc * 10) + num) rest
    | _ -> (acc, chars)
  in
  loop 0 chars

let parse_repeat chars =
  let min, rest = parse_number chars in
  match rest with
  | '}' :: rest -> (min, Some min, rest)
  | ',' :: '}' :: rest -> (min, None, rest)
  | ',' :: rest -> (
      let max, rest' = parse_number rest in
      match rest' with
      | '}' :: rest'' -> (min, Some max, rest'')
      | _ -> failwith "Unclosed repeats: missing '}'")
  | _ -> failwith "Invalid repeats"

let tokenize s =
  let rec loop chars =
    match chars with
    | [] -> [ TEOF ]
    | '\\' :: next :: rest -> parse_escape next :: loop rest
    | '\\' :: [] -> failwith "Invalid Escape"
    | '[' :: rest ->
        let chars, negated, rest' = parse_char_class rest in
        TCharClass (chars, negated) :: loop rest'
    | '{' :: rest ->
        let min, max, rest' = parse_repeat rest in
        TRepeat (min, max) :: loop rest'
    | c :: rest -> char_to_tok c :: loop rest
  in
  loop (s |> String.to_seq |> List.of_seq)
