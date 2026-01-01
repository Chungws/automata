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

let test_char_class () =
  (* basic char class *)
  Alcotest.(check bool) "[abc] matches a" true (Regex.matches "[abc]" "a");
  Alcotest.(check bool) "[abc] matches b" true (Regex.matches "[abc]" "b");
  Alcotest.(check bool) "[abc] not matches d" false (Regex.matches "[abc]" "d");
  (* range *)
  Alcotest.(check bool) "[a-z] matches m" true (Regex.matches "[a-z]" "m");
  Alcotest.(check bool) "[a-z] not matches M" false (Regex.matches "[a-z]" "M");
  Alcotest.(check bool) "[0-9] matches 5" true (Regex.matches "[0-9]" "5");
  (* negation *)
  Alcotest.(check bool) "[^abc] matches d" true (Regex.matches "[^abc]" "d");
  Alcotest.(check bool) "[^abc] not matches a" false (Regex.matches "[^abc]" "a");
  Alcotest.(check bool) "[^0-9] matches x" true (Regex.matches "[^0-9]" "x");
  (* combined with quantifiers *)
  Alcotest.(check bool) "[a-z]+ matches hello" true (Regex.matches "[a-z]+" "hello");
  Alcotest.(check bool) "[a-z]+ not matches Hello" false (Regex.matches "[a-z]+" "Hello");
  (* escape in char class *)
  Alcotest.(check bool) "[\\]] matches ]" true (Regex.matches "[\\]]" "]");
  Alcotest.(check bool) "[a\\-z] matches -" true (Regex.matches "[a\\-z]" "-");
  Alcotest.(check bool) "[\\\\] matches \\" true (Regex.matches "[\\\\]" "\\");
  (* literal ] and - at special positions *)
  Alcotest.(check bool) "[]a] matches ]" true (Regex.matches "[]a]" "]");
  Alcotest.(check bool) "[-a] matches -" true (Regex.matches "[-a]" "-");
  Alcotest.(check bool) "[a-] matches -" true (Regex.matches "[a-]" "-")

let test_escape () =
  (* escaped metacharacters *)
  Alcotest.(check bool) "\\. matches ." true (Regex.matches "\\." ".");
  Alcotest.(check bool) "\\. not matches a" false (Regex.matches "\\." "a");
  Alcotest.(check bool) "\\* matches *" true (Regex.matches "\\*" "*");
  Alcotest.(check bool) "\\+ matches +" true (Regex.matches "\\+" "+");
  Alcotest.(check bool) "\\\\ matches \\" true (Regex.matches "\\\\" "\\");
  (* escape in pattern *)
  Alcotest.(check bool) "a\\.b matches a.b" true (Regex.matches "a\\.b" "a.b");
  Alcotest.(check bool) "a\\.b not matches axb" false (Regex.matches "a\\.b" "axb")

let test_anchor () =
  (* start anchor *)
  Alcotest.(check bool) "^abc matches abc" true (Regex.matches "^abc" "abc");
  Alcotest.(check bool) "^abc not matches xabc" false (Regex.matches "^abc" "xabc");
  (* end anchor *)
  Alcotest.(check bool) "abc$ matches abc" true (Regex.matches "abc$" "abc");
  Alcotest.(check bool) "abc$ not matches abcx" false (Regex.matches "abc$" "abcx");
  (* both anchors *)
  Alcotest.(check bool) "^abc$ matches abc" true (Regex.matches "^abc$" "abc");
  Alcotest.(check bool) "^abc$ not matches xabc" false (Regex.matches "^abc$" "xabc");
  Alcotest.(check bool) "^abc$ not matches abcx" false (Regex.matches "^abc$" "abcx");
  (* anchor with quantifiers *)
  Alcotest.(check bool) "^a+$ matches aaa" true (Regex.matches "^a+$" "aaa");
  Alcotest.(check bool) "^a*$ matches empty" true (Regex.matches "^a*$" "")

let test_search () =
  (* basic search - finds pattern anywhere *)
  Alcotest.(check bool) "search abc in abc" true (Regex.search "abc" "abc");
  Alcotest.(check bool) "search abc in xabcx" true (Regex.search "abc" "xabcx");
  Alcotest.(check bool) "search abc in xxxabcxxx" true (Regex.search "abc" "xxxabcxxx");
  Alcotest.(check bool) "search abc not in abd" false (Regex.search "abc" "abd");
  (* search with start anchor *)
  Alcotest.(check bool) "search ^abc in abc" true (Regex.search "^abc" "abc");
  Alcotest.(check bool) "search ^abc in abcxxx" true (Regex.search "^abc" "abcxxx");
  Alcotest.(check bool) "search ^abc not in xabc" false (Regex.search "^abc" "xabc");
  (* search with end anchor *)
  Alcotest.(check bool) "search abc$ in abc" true (Regex.search "abc$" "abc");
  Alcotest.(check bool) "search abc$ in xxxabc" true (Regex.search "abc$" "xxxabc");
  Alcotest.(check bool) "search abc$ not in abcx" false (Regex.search "abc$" "abcx");
  (* search with both anchors *)
  Alcotest.(check bool) "search ^abc$ in abc" true (Regex.search "^abc$" "abc");
  Alcotest.(check bool) "search ^abc$ not in xabc" false (Regex.search "^abc$" "xabc");
  Alcotest.(check bool) "search ^abc$ not in abcx" false (Regex.search "^abc$" "abcx")

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
        Alcotest.test_case "char_class" `Quick test_char_class;
        Alcotest.test_case "escape" `Quick test_escape;
        Alcotest.test_case "anchor" `Quick test_anchor;
        Alcotest.test_case "search" `Quick test_search;
      ]);
    ]
