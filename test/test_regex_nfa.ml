module Regex = Automata.Regex_nfa

(* 기본 문자 매칭 *)
let test_char () =
  Alcotest.(check bool) "a matches a" true (Regex.matches "a" "a");
  Alcotest.(check bool) "a not matches b" false (Regex.matches "a" "b")

let test_concat () =
  Alcotest.(check bool) "ab matches ab" true (Regex.matches "ab" "ab");
  Alcotest.(check bool) "ab not matches a" false (Regex.matches "ab" "a");
  Alcotest.(check bool) "abc matches abc" true (Regex.matches "abc" "abc")

let test_alt () =
  Alcotest.(check bool) "a|b matches a" true (Regex.matches "a|b" "a");
  Alcotest.(check bool) "a|b matches b" true (Regex.matches "a|b" "b");
  Alcotest.(check bool) "a|b not matches c" false (Regex.matches "a|b" "c")

let test_star () =
  Alcotest.(check bool) "a* matches empty" true (Regex.matches "a*" "");
  Alcotest.(check bool) "a* matches a" true (Regex.matches "a*" "a");
  Alcotest.(check bool) "a* matches aaa" true (Regex.matches "a*" "aaa");
  Alcotest.(check bool) "a* not matches b" false (Regex.matches "a*" "b")

let test_plus () =
  Alcotest.(check bool) "a+ not matches empty" false (Regex.matches "a+" "");
  Alcotest.(check bool) "a+ matches a" true (Regex.matches "a+" "a");
  Alcotest.(check bool) "a+ matches aaa" true (Regex.matches "a+" "aaa")

let test_option () =
  Alcotest.(check bool) "a? matches empty" true (Regex.matches "a?" "");
  Alcotest.(check bool) "a? matches a" true (Regex.matches "a?" "a");
  Alcotest.(check bool) "a? not matches aa" false (Regex.matches "a?" "aa")

let test_group () =
  Alcotest.(check bool) "(ab)* matches empty" true (Regex.matches "(ab)*" "");
  Alcotest.(check bool) "(ab)* matches ab" true (Regex.matches "(ab)*" "ab");
  Alcotest.(check bool) "(ab)* matches abab" true (Regex.matches "(ab)*" "abab");
  Alcotest.(check bool) "(ab)* not matches aba" false (Regex.matches "(ab)*" "aba")

let test_complex () =
  (* (a|b)*abb - 전통적인 예제 *)
  Alcotest.(check bool) "(a|b)*abb matches abb" true (Regex.matches "(a|b)*abb" "abb");
  Alcotest.(check bool) "(a|b)*abb matches aabb" true (Regex.matches "(a|b)*abb" "aabb");
  Alcotest.(check bool) "(a|b)*abb matches babb" true (Regex.matches "(a|b)*abb" "babb");
  Alcotest.(check bool) "(a|b)*abb not matches ab" false (Regex.matches "(a|b)*abb" "ab")

let test_empty () =
  Alcotest.(check bool) "empty matches empty" true (Regex.matches "" "");
  Alcotest.(check bool) "empty not matches a" false (Regex.matches "" "a")

let test_dot () =
  Alcotest.(check bool) "a.c matches abc" true (Regex.matches "a.c" "abc");
  Alcotest.(check bool) "a.c matches aXc" true (Regex.matches "a.c" "aXc");
  Alcotest.(check bool) "a.c matches a1c" true (Regex.matches "a.c" "a1c");
  Alcotest.(check bool) "a.c not matches ac" false (Regex.matches "a.c" "ac");
  Alcotest.(check bool) "a.c not matches abbc" false (Regex.matches "a.c" "abbc");
  Alcotest.(check bool) ".* matches anything" true (Regex.matches ".*" "hello");
  Alcotest.(check bool) ".+ matches non-empty" true (Regex.matches ".+" "x");
  Alcotest.(check bool) ".+ not matches empty" false (Regex.matches ".+" "")

let () =
  Alcotest.run "Regex NFA"
    [
      ("basic", [
        Alcotest.test_case "char" `Quick test_char;
        Alcotest.test_case "concat" `Quick test_concat;
        Alcotest.test_case "alt" `Quick test_alt;
      ]);
      ("quantifiers", [
        Alcotest.test_case "star" `Quick test_star;
        Alcotest.test_case "plus" `Quick test_plus;
        Alcotest.test_case "option" `Quick test_option;
      ]);
      ("advanced", [
        Alcotest.test_case "group" `Quick test_group;
        Alcotest.test_case "complex" `Quick test_complex;
        Alcotest.test_case "empty" `Quick test_empty;
        Alcotest.test_case "dot" `Quick test_dot;
      ]);
    ]
