module Regex = Automata.Regex_bt

let test_char () =
  Alcotest.(check bool) "a matches a" true (Regex.matches "a" "a");
  Alcotest.(check bool) "a not matches b" false (Regex.matches "a" "b")

let test_concat () =
  Alcotest.(check bool) "ab matches ab" true (Regex.matches "ab" "ab");
  Alcotest.(check bool) "ab not matches a" false (Regex.matches "ab" "a")

let test_alt () =
  Alcotest.(check bool) "a|b matches a" true (Regex.matches "a|b" "a");
  Alcotest.(check bool) "a|b matches b" true (Regex.matches "a|b" "b");
  Alcotest.(check bool) "a|b not matches c" false (Regex.matches "a|b" "c")

let test_star () =
  Alcotest.(check bool) "a* matches empty" true (Regex.matches "a*" "");
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
  Alcotest.(check bool) "a{3} matches aaa" true (Regex.matches "a{3}" "aaa");
  Alcotest.(check bool) "a{3} not matches aa" false (Regex.matches "a{3}" "aa");
  Alcotest.(check bool) "a{2,4} matches aa" true (Regex.matches "a{2,4}" "aa");
  Alcotest.(check bool) "a{2,4} matches aaaa" true (Regex.matches "a{2,4}" "aaaa");
  Alcotest.(check bool) "a{2,4} not matches aaaaa" false (Regex.matches "a{2,4}" "aaaaa");
  Alcotest.(check bool) "a{2,} matches aa" true (Regex.matches "a{2,}" "aa");
  Alcotest.(check bool) "a{2,} matches aaaaa" true (Regex.matches "a{2,}" "aaaaa")

let test_dot () =
  Alcotest.(check bool) "a.c matches abc" true (Regex.matches "a.c" "abc");
  Alcotest.(check bool) "a.c not matches ac" false (Regex.matches "a.c" "ac")

let test_char_class () =
  Alcotest.(check bool) "[abc] matches a" true (Regex.matches "[abc]" "a");
  Alcotest.(check bool) "[abc] not matches d" false (Regex.matches "[abc]" "d");
  Alcotest.(check bool) "[^abc] matches d" true (Regex.matches "[^abc]" "d");
  Alcotest.(check bool) "[0-9]+ matches 123" true (Regex.matches "[0-9]+" "123")

let test_anchor () =
  Alcotest.(check bool) "^abc matches abc" true (Regex.matches "^abc" "abc");
  Alcotest.(check bool) "abc$ matches abc" true (Regex.matches "abc$" "abc");
  Alcotest.(check bool) "^abc$ matches abc" true (Regex.matches "^abc$" "abc")

let test_group () =
  Alcotest.(check bool) "(ab)* matches abab" true (Regex.matches "(ab)*" "abab");
  Alcotest.(check bool) "(a|b)*abb matches aabb" true (Regex.matches "(a|b)*abb" "aabb")

let capture_testable =
  Alcotest.testable
    (fun fmt caps ->
      let pp_cap fmt (n, (s, e)) = Format.fprintf fmt "(%d, (%d, %d))" n s e in
      Format.fprintf fmt "[%a]"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.fprintf fmt "; ") pp_cap)
        caps)
    ( = )

let test_capture_simple () =
  let result = Regex.match_groups "(a)" "a" in
  Alcotest.(check (option capture_testable)) "single group"
    (Some [(1, (0, 1))]) result

let test_capture_two_groups () =
  let result = Regex.match_groups "(a)(b)" "ab" in
  Alcotest.(check (option capture_testable)) "two groups"
    (Some [(2, (1, 2)); (1, (0, 1))]) result

let test_capture_nested () =
  let result = Regex.match_groups "((a))" "a" in
  Alcotest.(check (option capture_testable)) "nested groups"
    (Some [(1, (0, 1)); (2, (0, 1))]) result

let test_capture_no_match () =
  let result = Regex.match_groups "(a)" "b" in
  Alcotest.(check (option capture_testable)) "no match" None result

let test_capture_repeat () =
  let result = Regex.match_groups "(a)+" "aaa" in
  match result with
  | Some caps ->
      (* 반복 그룹은 마지막 매치를 캡처 *)
      Alcotest.(check bool) "has group 1" true (List.exists (fun (n, _) -> n = 1) caps)
  | None -> Alcotest.fail "expected match"

let test_backref_simple () =
  Alcotest.(check bool) "(.)\\1 matches aa" true (Regex.matches "(.)\\1" "aa");
  Alcotest.(check bool) "(.)\\1 matches bb" true (Regex.matches "(.)\\1" "bb");
  Alcotest.(check bool) "(.)\\1 not matches ab" false (Regex.matches "(.)\\1" "ab")

let test_backref_word () =
  Alcotest.(check bool) "([a-z]+)@\\1 matches test@test" true
    (Regex.matches "([a-z]+)@\\1" "test@test");
  Alcotest.(check bool) "([a-z]+)@\\1 not matches foo@bar" false
    (Regex.matches "([a-z]+)@\\1" "foo@bar")

let test_backref_multi () =
  Alcotest.(check bool) "(.)(.)(.)\\3\\2\\1 matches abccba" true
    (Regex.matches "(.)(.)(.)\\3\\2\\1" "abccba");
  Alcotest.(check bool) "(.)(.)(.)\\3\\2\\1 not matches abcabc" false
    (Regex.matches "(.)(.)(.)\\3\\2\\1" "abcabc")

let () =
  Alcotest.run "Regex Backtracking"
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
        Alcotest.test_case "dot" `Quick test_dot;
        Alcotest.test_case "char_class" `Quick test_char_class;
        Alcotest.test_case "anchor" `Quick test_anchor;
        Alcotest.test_case "group" `Quick test_group;
      ]);
      ("captures", [
        Alcotest.test_case "simple" `Quick test_capture_simple;
        Alcotest.test_case "two groups" `Quick test_capture_two_groups;
        Alcotest.test_case "nested" `Quick test_capture_nested;
        Alcotest.test_case "no match" `Quick test_capture_no_match;
        Alcotest.test_case "repeat" `Quick test_capture_repeat;
      ]);
      ("backrefs", [
        Alcotest.test_case "simple" `Quick test_backref_simple;
        Alcotest.test_case "word" `Quick test_backref_word;
        Alcotest.test_case "multi" `Quick test_backref_multi;
      ]);
    ]
