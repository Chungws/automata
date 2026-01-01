type t =
  | Char of char
  | CharClass of char list * bool
  | Concat of t * t
  | Alt of t * t
  | Star of t
  | Plus of t
  | Option of t
  | Group of t
  | Dot
  | Empty
