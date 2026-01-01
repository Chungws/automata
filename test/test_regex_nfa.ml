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

let test_repeat () =
  (* exact count {n} *)
  Alcotest.(check bool) "a{3} matches aaa" true (Regex.matches "a{3}" "aaa");
  Alcotest.(check bool) "a{3} not matches aa" false (Regex.matches "a{3}" "aa");
  Alcotest.(check bool) "a{3} not matches aaaa" false (Regex.matches "a{3}" "aaaa");
  Alcotest.(check bool) "a{0} matches empty" true (Regex.matches "a{0}" "");
  Alcotest.(check bool) "a{1} matches a" true (Regex.matches "a{1}" "a");
  (* range {n,m} *)
  Alcotest.(check bool) "a{2,4} matches aa" true (Regex.matches "a{2,4}" "aa");
  Alcotest.(check bool) "a{2,4} matches aaa" true (Regex.matches "a{2,4}" "aaa");
  Alcotest.(check bool) "a{2,4} matches aaaa" true (Regex.matches "a{2,4}" "aaaa");
  Alcotest.(check bool) "a{2,4} not matches a" false (Regex.matches "a{2,4}" "a");
  Alcotest.(check bool) "a{2,4} not matches aaaaa" false (Regex.matches "a{2,4}" "aaaaa");
  (* unbounded {n,} *)
  Alcotest.(check bool) "a{2,} matches aa" true (Regex.matches "a{2,}" "aa");
  Alcotest.(check bool) "a{2,} matches aaaaa" true (Regex.matches "a{2,}" "aaaaa");
  Alcotest.(check bool) "a{2,} not matches a" false (Regex.matches "a{2,}" "a");
  (* with groups *)
  Alcotest.(check bool) "(ab){2} matches abab" true (Regex.matches "(ab){2}" "abab");
  Alcotest.(check bool) "(ab){2} not matches ab" false (Regex.matches "(ab){2}" "ab");
  (* multi-digit numbers *)
  Alcotest.(check bool) "a{10} matches 10 a's" true (Regex.matches "a{10}" "aaaaaaaaaa");
  (* edge cases: min=0 *)
  Alcotest.(check bool) "a{0,2} matches empty" true (Regex.matches "a{0,2}" "");
  Alcotest.(check bool) "a{0,2} matches a" true (Regex.matches "a{0,2}" "a");
  Alcotest.(check bool) "a{0,2} matches aa" true (Regex.matches "a{0,2}" "aa");
  Alcotest.(check bool) "a{0,2} not matches aaa" false (Regex.matches "a{0,2}" "aaa");
  (* edge cases: equivalent to *, +, ? *)
  Alcotest.(check bool) "a{0,} matches empty (like a*)" true (Regex.matches "a{0,}" "");
  Alcotest.(check bool) "a{0,} matches aaa (like a*)" true (Regex.matches "a{0,}" "aaa");
  Alcotest.(check bool) "a{1,} not matches empty (like a+)" false (Regex.matches "a{1,}" "");
  Alcotest.(check bool) "a{1,} matches a (like a+)" true (Regex.matches "a{1,}" "a");
  Alcotest.(check bool) "a{0,1} matches empty (like a?)" true (Regex.matches "a{0,1}" "");
  Alcotest.(check bool) "a{0,1} matches a (like a?)" true (Regex.matches "a{0,1}" "a");
  Alcotest.(check bool) "a{0,1} not matches aa (like a?)" false (Regex.matches "a{0,1}" "aa");
  (* edge case: {0,0} *)
  Alcotest.(check bool) "a{0,0} matches empty" true (Regex.matches "a{0,0}" "");
  Alcotest.(check bool) "a{0,0} not matches a" false (Regex.matches "a{0,0}" "a");
  (* multi-digit range *)
  Alcotest.(check bool) "a{10,12} matches 10 a's" true (Regex.matches "a{10,12}" "aaaaaaaaaa");
  Alcotest.(check bool) "a{10,12} matches 12 a's" true (Regex.matches "a{10,12}" "aaaaaaaaaaaa");
  Alcotest.(check bool) "a{10,12} not matches 9 a's" false (Regex.matches "a{10,12}" "aaaaaaaaa")

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
  Alcotest.(check bool) "a\\.b not matches axb" false (Regex.matches "a\\.b" "axb");
  (* escaped braces *)
  Alcotest.(check bool) "\\{ matches {" true (Regex.matches "\\{" "{");
  Alcotest.(check bool) "\\} matches }" true (Regex.matches "\\}" "}")

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
        Alcotest.test_case "repeat" `Quick test_repeat;
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
