module Turing = Automata.Turing

(* Tape tests *)
let test_empty_tape () =
  let tape = Turing.empty_tape 'B' in
  Alcotest.(check char) "empty tape reads blank" 'B' (Turing.read tape)

let test_write_read () =
  let tape = Turing.empty_tape 'B' in
  let tape = Turing.write 'a' tape in
  Alcotest.(check char) "write then read" 'a' (Turing.read tape)

let test_move_right () =
  let tape = Turing.empty_tape 'B' in
  let tape = Turing.write 'a' tape in
  let tape = Turing.move_right tape in
  Alcotest.(check char) "move right reads blank" 'B' (Turing.read tape)

let test_move_left () =
  let tape = Turing.empty_tape 'B' in
  let tape = Turing.move_left tape in
  let tape = Turing.write 'x' tape in
  Alcotest.(check char) "write at -1" 'x' (Turing.read tape)

let test_of_input () =
  let tape = Turing.of_input "abc" 'B' in
  Alcotest.(check char) "pos 0" 'a' (Turing.read tape);
  let tape = Turing.move_right tape in
  Alcotest.(check char) "pos 1" 'b' (Turing.read tape);
  let tape = Turing.move_right tape in
  Alcotest.(check char) "pos 2" 'c' (Turing.read tape);
  let tape = Turing.move_right tape in
  Alcotest.(check char) "pos 3 blank" 'B' (Turing.read tape)

(* a^n b^n recognizer TM *)
let make_anbn_tm () =
  let open Turing in
  let transitions =
    TransitionMap.empty
    |> TransitionMap.add ("q0", 'a') ("q1", 'X', Right)
    |> TransitionMap.add ("q1", 'a') ("q1", 'a', Right)
    |> TransitionMap.add ("q1", 'Y') ("q1", 'Y', Right)
    |> TransitionMap.add ("q1", 'b') ("q2", 'Y', Left)
    |> TransitionMap.add ("q2", 'a') ("q2", 'a', Left)
    |> TransitionMap.add ("q2", 'Y') ("q2", 'Y', Left)
    |> TransitionMap.add ("q2", 'X') ("q0", 'X', Right)
    |> TransitionMap.add ("q0", 'Y') ("q3", 'Y', Right)
    |> TransitionMap.add ("q3", 'Y') ("q3", 'Y', Right)
    |> TransitionMap.add ("q3", 'B') ("accept", 'B', Right)
  in
  make_tm "q0" "accept" "reject" 'B' transitions

let status_to_string = function
  | Turing.Accepted -> "Accepted"
  | Turing.Rejected -> "Rejected"
  | Turing.Running -> "Running"
  | Turing.Timeout -> "Timeout"

let status_eq a b = (a = b)
let status_testable = Alcotest.testable
  (fun fmt s -> Format.fprintf fmt "%s" (status_to_string s))
  status_eq

let test_anbn_accept () =
  let tm = make_anbn_tm () in
  Alcotest.(check status_testable) "ab" Turing.Accepted (Turing.run tm "ab" 100);
  Alcotest.(check status_testable) "aabb" Turing.Accepted (Turing.run tm "aabb" 100);
  Alcotest.(check status_testable) "aaabbb" Turing.Accepted (Turing.run tm "aaabbb" 100)

let test_anbn_reject () =
  let tm = make_anbn_tm () in
  Alcotest.(check status_testable) "a" Turing.Rejected (Turing.run tm "a" 100);
  Alcotest.(check status_testable) "b" Turing.Rejected (Turing.run tm "b" 100);
  Alcotest.(check status_testable) "aab" Turing.Rejected (Turing.run tm "aab" 100);
  Alcotest.(check status_testable) "abb" Turing.Rejected (Turing.run tm "abb" 100);
  Alcotest.(check status_testable) "ba" Turing.Rejected (Turing.run tm "ba" 100)

let () =
  Alcotest.run "Turing Machine"
    [
      ("tape", [
        Alcotest.test_case "empty tape" `Quick test_empty_tape;
        Alcotest.test_case "write read" `Quick test_write_read;
        Alcotest.test_case "move right" `Quick test_move_right;
        Alcotest.test_case "move left" `Quick test_move_left;
        Alcotest.test_case "of_input" `Quick test_of_input;
      ]);
      ("anbn", [
        Alcotest.test_case "accept" `Quick test_anbn_accept;
        Alcotest.test_case "reject" `Quick test_anbn_reject;
      ]);
    ]
