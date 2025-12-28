module Nfa = Automata.Nfa

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
        (("q0", None), [ "q1"; "q4" ]);
        (("q1", Some 'a'), [ "q2" ]);
        (("q2", Some 'b'), [ "q3" ]);
        (("q4", Some 'a'), [ "q5" ]);
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

(* accepts tests *)
let test_nfa_empty () =
  Alcotest.(check bool) "empty string" false (Nfa.accepts a_or_ab_nfa "")

let test_nfa_a () =
  Alcotest.(check bool) "a" true (Nfa.accepts a_or_ab_nfa "a")

let test_nfa_ab () =
  Alcotest.(check bool) "ab" true (Nfa.accepts a_or_ab_nfa "ab")

let test_nfa_b () =
  Alcotest.(check bool) "b" false (Nfa.accepts a_or_ab_nfa "b")

let test_nfa_aa () =
  Alcotest.(check bool) "aa" false (Nfa.accepts a_or_ab_nfa "aa")

let test_nfa_abb () =
  Alcotest.(check bool) "abb" false (Nfa.accepts a_or_ab_nfa "abb")

(* epsilon_closure tests *)
let test_epsilon_closure () =
  let result = Nfa.epsilon_closure a_or_ab_nfa (Nfa.StateSet.singleton "q0") in
  let expected = Nfa.StateSet.of_list [ "q0"; "q1"; "q4" ] in
  Alcotest.(check bool) "epsilon closure from q0" true (Nfa.StateSet.equal result expected)

(* trace tests *)
let test_nfa_trace_empty () =
  let result = Nfa.trace a_or_ab_nfa "" in
  Alcotest.(check int) "empty trace length" 0 (List.length result)

let test_nfa_trace_a () =
  let result = Nfa.trace a_or_ab_nfa "a" in
  Alcotest.(check int) "trace a length" 1 (List.length result);
  let (from_states, sym, to_states) = List.hd result in
  Alcotest.(check char) "symbol" 'a' sym;
  Alcotest.(check bool) "from contains q1" true (Nfa.StateSet.mem "q1" from_states);
  Alcotest.(check bool) "to contains q2" true (Nfa.StateSet.mem "q2" to_states);
  Alcotest.(check bool) "to contains q5" true (Nfa.StateSet.mem "q5" to_states)

let test_nfa_trace_ab () =
  let result = Nfa.trace a_or_ab_nfa "ab" in
  Alcotest.(check int) "trace ab length" 2 (List.length result)

let () =
  Alcotest.run "NFA"
    [
      ( "accepts",
        [
          Alcotest.test_case "empty" `Quick test_nfa_empty;
          Alcotest.test_case "a" `Quick test_nfa_a;
          Alcotest.test_case "ab" `Quick test_nfa_ab;
          Alcotest.test_case "b" `Quick test_nfa_b;
          Alcotest.test_case "aa" `Quick test_nfa_aa;
          Alcotest.test_case "abb" `Quick test_nfa_abb;
        ] );
      ( "epsilon_closure",
        [
          Alcotest.test_case "from start" `Quick test_epsilon_closure;
        ] );
      ( "trace",
        [
          Alcotest.test_case "empty" `Quick test_nfa_trace_empty;
          Alcotest.test_case "a" `Quick test_nfa_trace_a;
          Alcotest.test_case "ab" `Quick test_nfa_trace_ab;
        ] );
    ]
