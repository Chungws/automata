type token =
  | TChar of char
  | TStar
  | TPlus
  | TQuestion
  | TPipe
  | TLParen
  | TRParen
  | TEOF

let char_to_tok ch =
  match ch with
  | '*' -> TStar
  | '+' -> TPlus
  | '?' -> TQuestion
  | '|' -> TPipe
  | '(' -> TLParen
  | ')' -> TRParen
  | ch -> TChar ch

let tokenize s =
  let tokens = String.to_seq s |> Seq.map char_to_tok |> List.of_seq in
  tokens @ [ TEOF ]
