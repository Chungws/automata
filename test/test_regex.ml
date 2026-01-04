module Regex = Automata.Regex

(* 기본 매칭 테스트 - NFA 엔진 *)
let test_nfa_basic () =
  Alcotest.(check bool) "NFA: a matches a" true
    (Regex.matches ~engine:NFA "a" "a");
  Alcotest.(check bool) "NFA: a* matches aaa" true
    (Regex.matches ~engine:NFA "a*" "aaa");
  Alcotest.(check bool) "NFA: (a|b)+ matches abab" true
    (Regex.matches ~engine:NFA "(a|b)+" "abab")

(* 기본 매칭 테스트 - 백트래킹 엔진 *)
let test_bt_basic () =
  Alcotest.(check bool) "BT: a matches a" true
    (Regex.matches ~engine:Backtrack "a" "a");
  Alcotest.(check bool) "BT: a* matches aaa" true
    (Regex.matches ~engine:Backtrack "a*" "aaa");
  Alcotest.(check bool) "BT: (a|b)+ matches abab" true
    (Regex.matches ~engine:Backtrack "(a|b)+" "abab")

(* 백레퍼런스 - 자동으로 백트래킹 선택 *)
let test_backref_auto () =
  (* NFA로 요청해도 백레퍼런스 있으면 자동으로 Backtrack 사용 *)
  Alcotest.(check bool) "auto: (.)\\1 matches aa" true
    (Regex.matches ~engine:NFA "(.)\\1" "aa");
  Alcotest.(check bool) "auto: (.)\\1 not matches ab" false
    (Regex.matches ~engine:NFA "(.)\\1" "ab")

(* matches_auto 테스트 *)
let test_matches_auto () =
  (* 백레퍼런스 없음 -> NFA *)
  Alcotest.(check bool) "auto: a+ matches aaa" true
    (Regex.matches_auto "a+" "aaa");
  (* 백레퍼런스 있음 -> Backtrack *)
  Alcotest.(check bool) "auto: (.)\\1 matches bb" true
    (Regex.matches_auto "(.)\\1" "bb")

(* match_groups 테스트 *)
let test_match_groups () =
  let result = Regex.match_groups "(a)(b)" "ab" in
  match result with
  | Some caps ->
      Alcotest.(check bool) "has 2 captures" true (List.length caps = 2);
      Alcotest.(check bool) "group 1 exists" true
        (List.exists (fun (n, _) -> n = 1) caps);
      Alcotest.(check bool) "group 2 exists" true
        (List.exists (fun (n, _) -> n = 2) caps)
  | None -> Alcotest.fail "expected match"

let () =
  Alcotest.run "Regex Unified"
    [
      ("nfa", [
        Alcotest.test_case "basic" `Quick test_nfa_basic;
      ]);
      ("backtrack", [
        Alcotest.test_case "basic" `Quick test_bt_basic;
      ]);
      ("auto", [
        Alcotest.test_case "backref auto" `Quick test_backref_auto;
        Alcotest.test_case "matches_auto" `Quick test_matches_auto;
        Alcotest.test_case "match_groups" `Quick test_match_groups;
      ]);
    ]
