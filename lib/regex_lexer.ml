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
  | ch -> TChar ch

let range start_char end_char =
  List.init
    (Char.code end_char - Char.code start_char + 1)
    (fun i -> Char.chr (Char.code start_char + i))

let parse_char_class chars =
  let negate, chars' =
    match chars with '^' :: rest -> (true, rest) | _ -> (false, chars)
  in
  let accs, chars' =
    match chars' with
    | ']' :: rest -> ([ ']' ], rest)
    | '-' :: rest -> ([ '-' ], rest)
    | _ -> ([], chars')
  in
  let rec loop acc chars =
    match chars with
    | [] -> failwith "Error"
    | ']' :: rest -> (acc, rest)
    | ch :: '-' :: d :: rest when d <> ']' -> loop (range ch d @ acc) rest
    | ch :: rest -> loop (ch :: acc) rest
  in
  let acc, rest = loop [] chars' in
  (accs @ acc, negate, rest)

let tokenize s =
  let rec loop chars =
    match chars with
    | [] -> [ TEOF ]
    | '[' :: rest ->
        let chars, negated, rest' = parse_char_class rest in
        TCharClass (chars, negated) :: loop rest'
    | c :: rest -> char_to_tok c :: loop rest
  in
  loop (s |> String.to_seq |> List.of_seq)
