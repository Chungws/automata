module Nfa = Automata.Nfa
module Dfa = Automata.Dfa
module Nfa_to_dfa = Automata.Nfa_to_dfa

let nfa_transitions_of_list lst =
  List.fold_left
    (fun map (key, value) ->
      Nfa.TransitionMap.add key (Nfa.StateSet.of_list value) map)
    Nfa.TransitionMap.empty lst

(* NFA: "a" 또는 "ab"를 인식
   q0 --ε--> q1 --a--> q2 --b--> ((q3))
    |
    └--ε--> q4 --a--> ((q5))
*)
let a_or_ab_nfa =
  let transitions =
    nfa_transitions_of_list
      [
        (("q0", Nfa.Epsilon), [ "q1"; "q4" ]);
        (("q1", Nfa.Char 'a'), [ "q2" ]);
        (("q2", Nfa.Char 'b'), [ "q3" ]);
        (("q4", Nfa.Char 'a'), [ "q5" ]);
      ]
  in
  Nfa.
    {
      states = Nfa.StateSet.of_list [ "q0"; "q1"; "q2"; "q3"; "q4"; "q5" ];
      alphabet = [ 'a'; 'b' ];
      start = "q0";
      accept = Nfa.StateSet.of_list [ "q3"; "q5" ];
      transitions;
    }

let converted_dfa = Nfa_to_dfa.convert a_or_ab_nfa

(* NFA와 DFA가 같은 문자열을 accept하는지 테스트 *)
let test_both_empty () =
  Alcotest.(check bool) "empty" (Nfa.accepts a_or_ab_nfa "") (Dfa.accepts converted_dfa "")

let test_both_a () =
  Alcotest.(check bool) "a" (Nfa.accepts a_or_ab_nfa "a") (Dfa.accepts converted_dfa "a")

let test_both_ab () =
  Alcotest.(check bool) "ab" (Nfa.accepts a_or_ab_nfa "ab") (Dfa.accepts converted_dfa "ab")

let test_both_b () =
  Alcotest.(check bool) "b" (Nfa.accepts a_or_ab_nfa "b") (Dfa.accepts converted_dfa "b")

let test_both_aa () =
  Alcotest.(check bool) "aa" (Nfa.accepts a_or_ab_nfa "aa") (Dfa.accepts converted_dfa "aa")

let test_both_abb () =
  Alcotest.(check bool) "abb" (Nfa.accepts a_or_ab_nfa "abb") (Dfa.accepts converted_dfa "abb")

let test_both_ba () =
  Alcotest.(check bool) "ba" (Nfa.accepts a_or_ab_nfa "ba") (Dfa.accepts converted_dfa "ba")

let test_both_aba () =
  Alcotest.(check bool) "aba" (Nfa.accepts a_or_ab_nfa "aba") (Dfa.accepts converted_dfa "aba")

(* DFA 구조 테스트 *)
let test_dfa_start_state () =
  Alcotest.(check bool) "start contains q0,q1,q4" true
    (String.length converted_dfa.start > 0)

let test_dfa_is_deterministic () =
  (* 모든 (상태, 심볼) 쌍에 대해 전이가 정의되어 있는지 *)
  let all_defined =
    List.for_all
      (fun state ->
        List.for_all
          (fun sym -> Dfa.TransitionMap.mem (state, sym) converted_dfa.transitions)
          converted_dfa.alphabet)
      converted_dfa.states
  in
  Alcotest.(check bool) "all transitions defined" true all_defined

let () =
  Alcotest.run "NFA to DFA"
    [
      ( "equivalence",
        [
          Alcotest.test_case "empty" `Quick test_both_empty;
          Alcotest.test_case "a" `Quick test_both_a;
          Alcotest.test_case "ab" `Quick test_both_ab;
          Alcotest.test_case "b" `Quick test_both_b;
          Alcotest.test_case "aa" `Quick test_both_aa;
          Alcotest.test_case "abb" `Quick test_both_abb;
          Alcotest.test_case "ba" `Quick test_both_ba;
          Alcotest.test_case "aba" `Quick test_both_aba;
        ] );
      ( "dfa_structure",
        [
          Alcotest.test_case "start state" `Quick test_dfa_start_state;
          Alcotest.test_case "deterministic" `Quick test_dfa_is_deterministic;
        ] );
    ]
