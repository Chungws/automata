(* 통합 Regex 인터페이스

   NFA 엔진과 백트래킹 엔진을 통합하여 제공.
   - NFA: O(nm), ReDoS 안전, 백레퍼런스 미지원
   - Backtrack: O(2^n) 최악, 캡처/백레퍼런스 지원
*)

type engine = NFA | Backtrack

(* 패턴에 백레퍼런스가 있는지 감지 *)
let has_backref pattern =
  let rec check i =
    if i >= String.length pattern - 1 then false
    else if
      pattern.[i] = '\\' && pattern.[i + 1] >= '1' && pattern.[i + 1] <= '9'
    then true
    else check (i + 1)
  in
  check 0

(* 엔진 자동 선택: 백레퍼런스 있으면 Backtrack, 없으면 NFA *)
let auto_select_engine pattern = if has_backref pattern then Backtrack else NFA

let matches ?(engine = NFA) pattern text =
  let actual_engine =
    match engine with
    | NFA when has_backref pattern -> Backtrack (* 백레퍼런스는 NFA 불가 *)
    | e -> e
  in
  match actual_engine with
  | NFA -> Regex_nfa.matches pattern text
  | Backtrack -> Regex_bt.matches pattern text

(* 캡처 그룹 - 백트래킹 엔진만 지원 *)
let match_groups pattern text = Regex_bt.match_groups pattern text

(* 편의 함수: 엔진 자동 선택 *)
let matches_auto pattern text =
  matches ~engine:(auto_select_engine pattern) pattern text

let search ?(engine = NFA) pattern text =
  let actual_engine =
    match engine with
    | NFA when has_backref pattern -> Backtrack (* 백레퍼런스는 NFA 불가 *)
    | e -> e
  in
  match actual_engine with
  | NFA -> Regex_nfa.search pattern text
  | Backtrack -> Regex_bt.search pattern text

let replace ?(engine = NFA) pattern replacement text =
  let actual_engine =
    match engine with
    | NFA when has_backref pattern || has_backref replacement ->
        Backtrack (* 백레퍼런스는 NFA 불가 *)
    | e -> e
  in
  match actual_engine with
  | NFA -> Regex_nfa.replace pattern replacement text
  | Backtrack -> Regex_bt.replace pattern replacement text
