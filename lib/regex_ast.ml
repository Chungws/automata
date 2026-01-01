type t =
  | Char of char
  | Concat of t * t
  | Alt of t * t
  | Star of t
  | Plus of t
  | Option of t
  | Group of t
  | Dot
  | Empty
