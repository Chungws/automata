(* ReDoS (Regular Expression Denial of Service) 실험

   백트래킹 엔진 vs NFA 엔진 성능 비교

   악의적 패턴: (a+)+$
   악의적 입력: "aaa...a!" (a가 n개 + 느낌표)

   NFA: O(nm) - 항상 빠름
   백트래킹: O(2^n) - 지수적 폭발
*)

let time f =
  let start = Sys.time () in
  let result = f () in
  let elapsed = Sys.time () -. start in
  (result, elapsed)

let evil_input n = String.make n 'a' ^ "!"

let test_redos () =
  let pattern = "(a+)+$" in

  Printf.printf "=== ReDoS 실험 ===\n";
  Printf.printf "패턴: %s\n" pattern;
  Printf.printf "입력: %s (a가 n개 + !)\n\n" "aaa...!";
  Printf.printf "%4s | %12s | %12s | %s\n" "n" "NFA" "Backtrack" "비고";
  Printf.printf "%s\n" (String.make 50 '-');

  for n = 5 to 25 do
    let input = evil_input n in

    (* NFA 엔진 *)
    let (result_nfa, time_nfa) = time (fun () ->
      Automata.Regex_nfa.matches pattern input
    ) in

    (* 백트래킹 엔진 - 너무 오래 걸리면 스킵 *)
    let (result_bt, time_bt) =
      if n <= 22 then
        time (fun () -> Automata.Regex_bt.matches pattern input)
      else
        (false, infinity)
    in

    let note =
      if time_bt > 1.0 then "느림!"
      else if time_bt > 0.1 then "주의"
      else ""
    in

    if time_bt = infinity then
      Printf.printf "%4d | %10.6fs | %12s | 스킵 (너무 오래 걸림)\n"
        n time_nfa "..."
    else
      Printf.printf "%4d | %10.6fs | %10.6fs | %s\n"
        n time_nfa time_bt note;

    flush stdout;

    (* 결과 검증 - 둘 다 false여야 함 (패턴이 매치 안 됨) *)
    if result_nfa <> result_bt && time_bt <> infinity then
      Printf.printf "  경고: 결과 불일치! NFA=%b, BT=%b\n" result_nfa result_bt
  done;

  Printf.printf "\n=== 분석 ===\n";
  Printf.printf "NFA 엔진: 입력 크기에 선형적 (안전)\n";
  Printf.printf "백트래킹: 입력 크기에 지수적 (위험!)\n";
  Printf.printf "\n";
  Printf.printf "이것이 ReDoS 공격의 원리입니다.\n";
  Printf.printf "악의적 입력으로 서버를 마비시킬 수 있습니다.\n"

let () = test_redos ()
