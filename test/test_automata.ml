module Dfa = Automata.Dfa

let transitions_of_list lst =
  List.fold_left
    (fun map (key, value) -> Dfa.TransitionMap.add key value map)
    Dfa.TransitionMap.empty lst

let even_zeros_dfa =
  let transitions =
    transitions_of_list
      [
        (("q0", '0'), "q1");
        (("q0", '1'), "q0");
        (("q1", '0'), "q0");
        (("q1", '1'), "q1");
      ]
  in
  Dfa.
    {
      states = [ "q0"; "q1" ];
      alphabet = [ '0'; '1' ];
      start = "q0";
      accept = [ "q0" ];
      transitions;
    }

let test_empty () =
  Alcotest.(check bool) "empty string" true (Dfa.accepts even_zeros_dfa "")

let test_single_zero () =
  Alcotest.(check bool) "single zero" false (Dfa.accepts even_zeros_dfa "0")

let test_double_zero () =
  Alcotest.(check bool) "double zero" true (Dfa.accepts even_zeros_dfa "00")

let test_single_one () =
  Alcotest.(check bool) "single one" true (Dfa.accepts even_zeros_dfa "1")

let test_mixed () =
  Alcotest.(check bool) "10" false (Dfa.accepts even_zeros_dfa "10")

let test_mixed_even () =
  Alcotest.(check bool) "0110" true (Dfa.accepts even_zeros_dfa "0110")

(* create tests *)
let test_create_valid () =
  let dfa =
    Dfa.create [ "q0"; "q1" ] [ '0'; '1' ] "q0" [ "q0" ]
      [ (("q0", '0'), "q1"); (("q0", '1'), "q0"); (("q1", '0'), "q0"); (("q1", '1'), "q1") ]
  in
  Alcotest.(check bool) "valid dfa accepts empty" true (Dfa.accepts dfa "")

let test_create_invalid_start () =
  Alcotest.check_raises "invalid start" (Dfa.Invalid_dfa "start state not in states")
    (fun () ->
      ignore
        (Dfa.create [ "q0"; "q1" ] [ '0'; '1' ] "q99" [ "q0" ]
           [ (("q0", '0'), "q1") ]))

let test_create_invalid_accept () =
  Alcotest.check_raises "invalid accept" (Dfa.Invalid_dfa "accept state not in states")
    (fun () ->
      ignore
        (Dfa.create [ "q0"; "q1" ] [ '0'; '1' ] "q0" [ "q99" ]
           [ (("q0", '0'), "q1") ]))

(* trace tests *)
let trace_testable =
  Alcotest.list (Alcotest.triple Alcotest.string Alcotest.char Alcotest.string)

let test_trace_empty () =
  Alcotest.(check trace_testable) "empty trace" [] (Dfa.trace even_zeros_dfa "")

let test_trace_single () =
  Alcotest.(check trace_testable)
    "single char"
    [ ("q0", '0', "q1") ]
    (Dfa.trace even_zeros_dfa "0")

let test_trace_multiple () =
  Alcotest.(check trace_testable)
    "multiple chars"
    [ ("q0", '0', "q1"); ("q1", '1', "q1"); ("q1", '0', "q0") ]
    (Dfa.trace even_zeros_dfa "010")

let () =
  Alcotest.run "DFA"
    [
      ( "accepts",
        [
          Alcotest.test_case "empty" `Quick test_empty;
          Alcotest.test_case "single zero" `Quick test_single_zero;
          Alcotest.test_case "double zero" `Quick test_double_zero;
          Alcotest.test_case "single one" `Quick test_single_one;
          Alcotest.test_case "mixed odd" `Quick test_mixed;
          Alcotest.test_case "mixed even" `Quick test_mixed_even;
        ] );
      ( "create",
        [
          Alcotest.test_case "valid" `Quick test_create_valid;
          Alcotest.test_case "invalid start" `Quick test_create_invalid_start;
          Alcotest.test_case "invalid accept" `Quick test_create_invalid_accept;
        ] );
      ( "trace",
        [
          Alcotest.test_case "empty" `Quick test_trace_empty;
          Alcotest.test_case "single" `Quick test_trace_single;
          Alcotest.test_case "multiple" `Quick test_trace_multiple;
        ] );
    ]
