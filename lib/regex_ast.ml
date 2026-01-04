type t =
  | Char of char
  | CharClass of char list * bool
  | Anchor of [ `Start | `End ]
  | Concat of t * t
  | Alt of t * t
  | Star of t
  | Plus of t
  | Option of t
  | Group of int * t
  | Repeat of t * int * int option
  | Dot
  | Backref of int
  | Empty
