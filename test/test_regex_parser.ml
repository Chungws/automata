module Ast = Automata.Regex_ast
module Lexer = Automata.Regex_lexer
module Parser = Automata.Regex_parser

(* ===== Lexer Tests ===== *)

let test_tokenize_simple () =
  let tokens = Lexer.tokenize "abc" in
  Alcotest.(check (list (of_pp (fun fmt _ -> Fmt.string fmt "token"))))
    "abc"
    [Lexer.TChar 'a'; Lexer.TChar 'b'; Lexer.TChar 'c'; Lexer.TEOF]
    tokens

let test_tokenize_operators () =
  let tokens = Lexer.tokenize "a*b+c?" in
  let expected = [
    Lexer.TChar 'a'; Lexer.TStar;
    Lexer.TChar 'b'; Lexer.TPlus;
    Lexer.TChar 'c'; Lexer.TQuestion;
    Lexer.TEOF
  ] in
  Alcotest.(check int) "length" (List.length expected) (List.length tokens)

let test_tokenize_groups () =
  let tokens = Lexer.tokenize "(a|b)" in
  let expected = [
    Lexer.TLParen; Lexer.TChar 'a'; Lexer.TPipe;
    Lexer.TChar 'b'; Lexer.TRParen; Lexer.TEOF
  ] in
  Alcotest.(check int) "length" (List.length expected) (List.length tokens)

(* ===== Parser Tests ===== *)

let test_parse_empty () =
  let ast = Parser.parse "" in
  Alcotest.(check bool) "empty" true (ast = Ast.Empty)

let test_parse_char () =
  let ast = Parser.parse "a" in
  Alcotest.(check bool) "single char" true (ast = Ast.Char 'a')

let test_parse_concat () =
  let ast = Parser.parse "ab" in
  let expected = Ast.Concat (Ast.Char 'a', Ast.Char 'b') in
  Alcotest.(check bool) "concat" true (ast = expected)

let test_parse_concat_three () =
  let ast = Parser.parse "abc" in
  let expected = Ast.Concat (Ast.Char 'a', Ast.Concat (Ast.Char 'b', Ast.Char 'c')) in
  Alcotest.(check bool) "concat three" true (ast = expected)

let test_parse_alt () =
  let ast = Parser.parse "a|b" in
  let expected = Ast.Alt (Ast.Char 'a', Ast.Char 'b') in
  Alcotest.(check bool) "alt" true (ast = expected)

let test_parse_alt_three () =
  let ast = Parser.parse "a|b|c" in
  let expected = Ast.Alt (Ast.Char 'a', Ast.Alt (Ast.Char 'b', Ast.Char 'c')) in
  Alcotest.(check bool) "alt three" true (ast = expected)

let test_parse_star () =
  let ast = Parser.parse "a*" in
  let expected = Ast.Star (Ast.Char 'a') in
  Alcotest.(check bool) "star" true (ast = expected)

let test_parse_plus () =
  let ast = Parser.parse "a+" in
  let expected = Ast.Plus (Ast.Char 'a') in
  Alcotest.(check bool) "plus" true (ast = expected)

let test_parse_option () =
  let ast = Parser.parse "a?" in
  let expected = Ast.Option (Ast.Char 'a') in
  Alcotest.(check bool) "option" true (ast = expected)

let test_parse_group () =
  let ast = Parser.parse "(a)" in
  Alcotest.(check bool) "group" true (ast = Ast.Group (1, Ast.Char 'a'))

let test_parse_group_alt () =
  let ast = Parser.parse "(a|b)*" in
  let expected = Ast.Star (Ast.Group (1, Ast.Alt (Ast.Char 'a', Ast.Char 'b'))) in
  Alcotest.(check bool) "group alt star" true (ast = expected)

let test_parse_complex () =
  (* (a|b)*abb *)
  let ast = Parser.parse "(a|b)*abb" in
  let ab = Ast.Group (1, Ast.Alt (Ast.Char 'a', Ast.Char 'b')) in
  let expected = Ast.Concat (
    Ast.Star ab,
    Ast.Concat (Ast.Char 'a',
      Ast.Concat (Ast.Char 'b', Ast.Char 'b'))
  ) in
  Alcotest.(check bool) "complex" true (ast = expected)

let test_parse_precedence () =
  (* a|bc should parse as a OR bc, not ab then c *)
  let ast = Parser.parse "a|bc" in
  let expected = Ast.Alt (Ast.Char 'a', Ast.Concat (Ast.Char 'b', Ast.Char 'c')) in
  Alcotest.(check bool) "precedence" true (ast = expected)

let test_parse_precedence_star () =
  (* ab* should be a followed by b*, not the whole ab repeated *)
  let ast = Parser.parse "ab*" in
  let expected = Ast.Concat (Ast.Char 'a', Ast.Star (Ast.Char 'b')) in
  Alcotest.(check bool) "precedence star" true (ast = expected)

let () =
  Alcotest.run "Regex Parser"
    [
      ( "lexer",
        [
          Alcotest.test_case "simple" `Quick test_tokenize_simple;
          Alcotest.test_case "operators" `Quick test_tokenize_operators;
          Alcotest.test_case "groups" `Quick test_tokenize_groups;
        ] );
      ( "parser",
        [
          Alcotest.test_case "empty" `Quick test_parse_empty;
          Alcotest.test_case "char" `Quick test_parse_char;
          Alcotest.test_case "concat" `Quick test_parse_concat;
          Alcotest.test_case "concat three" `Quick test_parse_concat_three;
          Alcotest.test_case "alt" `Quick test_parse_alt;
          Alcotest.test_case "alt three" `Quick test_parse_alt_three;
          Alcotest.test_case "star" `Quick test_parse_star;
          Alcotest.test_case "plus" `Quick test_parse_plus;
          Alcotest.test_case "option" `Quick test_parse_option;
          Alcotest.test_case "group" `Quick test_parse_group;
          Alcotest.test_case "group alt star" `Quick test_parse_group_alt;
          Alcotest.test_case "complex" `Quick test_parse_complex;
          Alcotest.test_case "precedence alt" `Quick test_parse_precedence;
          Alcotest.test_case "precedence star" `Quick test_parse_precedence_star;
        ] );
    ]
