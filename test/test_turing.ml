module Turing = Automata.Turing

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

let test_sequence () =
  let tape = Turing.empty_tape 'B' in
  (* Write "ab" starting at position 0 *)
  let tape = Turing.write 'a' tape in
  let tape = Turing.move_right tape in
  let tape = Turing.write 'b' tape in
  (* Move back and verify *)
  let tape = Turing.move_left tape in
  Alcotest.(check char) "back to a" 'a' (Turing.read tape);
  let tape = Turing.move_right tape in
  Alcotest.(check char) "forward to b" 'b' (Turing.read tape)

let () =
  Alcotest.run "Turing Machine"
    [
      ("tape", [
        Alcotest.test_case "empty tape" `Quick test_empty_tape;
        Alcotest.test_case "write read" `Quick test_write_read;
        Alcotest.test_case "move right" `Quick test_move_right;
        Alcotest.test_case "move left" `Quick test_move_left;
        Alcotest.test_case "sequence" `Quick test_sequence;
      ]);
    ]
