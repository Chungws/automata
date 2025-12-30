# Project 4: Regex Engine

## 개요

POSIX ERE(Extended Regular Expressions) 수준의 정규 표현식 엔진을 두 가지 방식으로 구현합니다:

1. **NFA 기반 엔진** - Thompson 구성법, O(nm) 보장
2. **백트래킹 엔진** - 백레퍼런스 지원, O(2ⁿ) 최악

두 엔진을 비교하여 오토마타 이론의 한계와 실제 정규식 엔진의 트레이드오프를 이해합니다.

## 학습 목표

- 정규 표현식과 유한 오토마타의 동치성 이해
- Thompson 구성법 알고리즘 구현
- 백트래킹 엔진의 동작 원리와 한계 이해
- ReDoS(정규식 서비스 거부) 취약점 체험

## 지원 기능

### POSIX ERE 기능 (두 엔진 공통)

| 기능 | 문법 | 설명 | 예시 |
|------|------|------|------|
| 리터럴 | `a`, `b` | 문자 그대로 매칭 | `abc` |
| 임의 문자 | `.` | 개행 제외 아무 문자 | `a.c` → "abc", "aXc" |
| 선택 | `\|` | OR 연산 | `a\|b` → "a" 또는 "b" |
| 그룹 | `()` | 그룹핑 | `(ab)+` |
| 클레이니 스타 | `*` | 0회 이상 | `a*` → "", "a", "aa" |
| 클레이니 플러스 | `+` | 1회 이상 | `a+` → "a", "aa" |
| 옵션 | `?` | 0회 또는 1회 | `a?` → "", "a" |
| 횟수 지정 | `{n}`, `{n,}`, `{n,m}` | 정확한 반복 횟수 | `a{2,4}` → "aa", "aaa", "aaaa" |
| 문자 클래스 | `[abc]` | 문자 집합 | `[aeiou]` |
| 범위 | `[a-z]` | 문자 범위 | `[0-9]` |
| 부정 클래스 | `[^abc]` | 제외 집합 | `[^0-9]` → 숫자 아닌 것 |
| 앵커 | `^`, `$` | 시작, 끝 | `^abc$` |
| 이스케이프 | `\` | 특수문자 이스케이프 | `\*`, `\\`, `\.` |

### POSIX 문자 클래스

| 클래스 | 동등 표현 | 설명 |
|--------|----------|------|
| `[:alnum:]` | `[a-zA-Z0-9]` | 알파벳 + 숫자 |
| `[:alpha:]` | `[a-zA-Z]` | 알파벳 |
| `[:digit:]` | `[0-9]` | 숫자 |
| `[:lower:]` | `[a-z]` | 소문자 |
| `[:upper:]` | `[A-Z]` | 대문자 |
| `[:space:]` | `[ \t\n\r\f\v]` | 공백 문자 |
| `[:punct:]` | 구두점 | 특수문자 |

사용: `[[:digit:]]` = `[0-9]`

### 백트래킹 엔진 전용 기능

| 기능 | 문법 | 설명 |
|------|------|------|
| 캡처 그룹 | `()` | 매칭된 내용 저장 |
| 백레퍼런스 | `\1` ~ `\9` | 캡처된 그룹 재참조 |

```
예시: (a+)\1
매칭: "aa", "aaaa", "aaaaaa" (같은 패턴 반복)
불매칭: "aaa" (홀수 개)
```

## 이론적 배경

### Kleene의 정리

정규 표현식과 유한 오토마타는 동등한 표현력:
- 모든 정규 표현식 → NFA로 변환 가능 (Thompson 구성법)
- 모든 DFA → 정규 표현식으로 변환 가능 (상태 제거법)

### 백레퍼런스는 왜 정규 언어가 아닌가?

```
패턴: (a+)\1
언어: { aⁿaⁿ | n ≥ 1 } = { aa, aaaa, aaaaaa, ... }
```

이 언어를 인식하려면 "a를 몇 개 봤는지" 기억해야 함.
NFA/DFA는 유한한 상태만 가지므로 무한한 카운트를 기억할 수 없음.
→ 펌핑 보조정리로 증명 가능

### 엔진 구현 방식 비교

| 특성 | NFA 시뮬레이션 | 백트래킹 |
|------|---------------|---------|
| 시간 복잡도 | O(nm) | O(2ⁿ) 최악 |
| 공간 복잡도 | O(m) | O(n) 스택 |
| 백레퍼런스 | ❌ | ✅ |
| ReDoS 취약 | ❌ | ✅ |
| 사용 엔진 | RE2, Go | PCRE, Python, JS |

n = 입력 길이, m = 패턴 상태 수

---

# Part 1: NFA 기반 엔진

## Thompson 구성법

각 정규식 요소를 NFA 조각(fragment)으로 변환:

### 1. 단일 문자 'a'
```
→(start)──a──→((end))
```

### 2. 연결 AB
```
→(A.start)───A───→(A.end)──ε──→(B.start)───B───→((B.end))
```

### 3. 선택 A|B
```
          ┌──ε──→(A.start)───A───→(A.end)──ε──┐
→(start)──┤                                    ├──→((end))
          └──ε──→(B.start)───B───→(B.end)──ε──┘
```

### 4. 클레이니 스타 A*
```
              ┌────────ε────────┐
              ↓                 │
→(start)──ε──→(A.start)───A───→(A.end)──ε──→((end))
    │                                          ↑
    └─────────────────ε────────────────────────┘
```

### 5. 클레이니 플러스 A+
```
              ┌────────ε────────┐
              ↓                 │
→(start)──ε──→(A.start)───A───→(A.end)──ε──→((end))
```
(스킵 경로 없음 - 최소 1회 필수)

### 6. 옵션 A?
```
→(start)──ε──→(A.start)───A───→(A.end)──ε──→((end))
    │                                          ↑
    └─────────────────ε────────────────────────┘
```

## Step-by-Step 구현 가이드 (NFA 엔진)

### Step 1: AST 정의

**목표**: 정규식을 표현하는 AST(추상 구문 트리) 정의

```ocaml
type regex =
  | Char of char                    (* 단일 문자 *)
  | Dot                             (* 임의 문자 . *)
  | CharClass of char_class         (* [abc], [^abc] *)
  | Concat of regex * regex         (* 연결 *)
  | Alt of regex * regex            (* 선택 | *)
  | Star of regex                   (* 클레이니 스타 * *)
  | Plus of regex                   (* 클레이니 플러스 + *)
  | Option of regex                 (* 옵션 ? *)
  | Repeat of regex * int * int option  (* {n,m} *)
  | Anchor of anchor_type           (* ^, $ *)
  | Group of regex                  (* 그룹 () *)
  | Empty                           (* 빈 문자열 *)

and char_class = {
  negated: bool;
  ranges: (char * char) list;       (* [a-z] → [('a', 'z')] *)
}

and anchor_type = Start | End
```

### Step 2: 토크나이저 구현

**목표**: 정규식 문자열을 토큰 리스트로 변환

```ocaml
type token =
  | TChar of char
  | TDot
  | TStar | TPlus | TQuestion
  | TPipe
  | TLParen | TRParen
  | TLBracket | TRBracket
  | TCaret | TDollar
  | TLBrace | TRBrace
  | TBackslash
  | TEOF
```

**처리할 것들**:
- 이스케이프: `\*`, `\\`, `\n`, `\t`
- POSIX 클래스: `[:digit:]`
- 수량자: `{n}`, `{n,}`, `{n,m}`

### Step 3: 파서 구현

**목표**: 토큰을 AST로 변환 (재귀 하강 파싱)

**문법** (우선순위 낮은 것부터):
```
regex    → alt
alt      → concat ('|' concat)*
concat   → repeat+
repeat   → atom ('*' | '+' | '?' | '{n,m}')?
atom     → char | '.' | class | '(' regex ')' | anchor
class    → '[' '^'? (char | range)+ ']'
```

### Step 4: NFA Fragment 구조

**목표**: NFA 조각을 표현하는 데이터 구조

```ocaml
type state = string

type nfa_fragment = {
  start: state;
  accept: state;
  transitions: (state * char option * state) list;
}

(* 고유 상태 이름 생성 *)
let counter = ref 0
let new_state () =
  let n = !counter in
  counter := n + 1;
  "s" ^ string_of_int n
```

### Step 5: AST → NFA 변환

**목표**: 각 AST 노드를 NFA fragment로 변환

```ocaml
let rec ast_to_nfa = function
  | Char c -> char_nfa c
  | Dot -> dot_nfa ()
  | CharClass cc -> char_class_nfa cc
  | Concat (a, b) -> concat_nfa (ast_to_nfa a) (ast_to_nfa b)
  | Alt (a, b) -> alt_nfa (ast_to_nfa a) (ast_to_nfa b)
  | Star a -> star_nfa (ast_to_nfa a)
  | Plus a -> plus_nfa (ast_to_nfa a)
  | Option a -> option_nfa (ast_to_nfa a)
  | Repeat (a, n, m) -> repeat_nfa (ast_to_nfa a) n m
  | ...
```

### Step 6: Fragment → 완전한 NFA 변환

**목표**: Fragment를 기존 Nfa 모듈과 호환되는 형태로 변환

```ocaml
let fragment_to_nfa fragment alphabet =
  (* 기존 Nfa.t 타입으로 변환 *)
  ...
```

### Step 7: 매칭 함수

**목표**: 정규식 문자열 → 매칭 결과

```ocaml
let compile pattern =
  let tokens = tokenize pattern in
  let ast = parse tokens in
  let fragment = ast_to_nfa ast in
  fragment_to_nfa fragment

let matches pattern text =
  let nfa = compile pattern in
  Nfa.accepts nfa text
```

---

# Part 2: 백트래킹 엔진

## 개요

백트래킹 엔진은 NFA 시뮬레이션 대신 재귀적 탐색을 사용합니다.
캡처 그룹과 백레퍼런스를 지원하지만, 최악의 경우 지수 시간이 걸립니다.

## 백트래킹 알고리즘

```
function match(pattern, text, pos, captures):
    if pattern is empty:
        return pos  # 매칭 성공

    if pattern is Char(c):
        if text[pos] == c:
            return match(rest(pattern), text, pos+1, captures)
        else:
            return FAIL  # 백트래킹

    if pattern is Star(a):
        # 그리디: 최대한 많이 매칭 시도
        for count in range(max_possible, -1, -1):
            result = try_match(a, count times, then rest)
            if result != FAIL:
                return result
        return FAIL

    if pattern is Group(n, a):
        start_pos = pos
        result = match(a, text, pos, captures)
        if result != FAIL:
            captures[n] = text[start_pos:result]
            return match(rest(pattern), text, result, captures)
        return FAIL

    if pattern is Backref(n):
        captured = captures[n]
        if text[pos:].startswith(captured):
            return match(rest(pattern), text, pos + len(captured), captures)
        return FAIL
```

## Step-by-Step 구현 가이드 (백트래킹 엔진)

### Step 1: 확장된 AST

```ocaml
type regex_bt =
  | (* NFA와 동일한 것들 *)
  | CaptureGroup of int * regex_bt  (* 캡처 그룹 *)
  | Backref of int                  (* 백레퍼런스 \1-\9 *)
```

### Step 2: 매칭 상태

```ocaml
type match_state = {
  pos: int;                         (* 현재 위치 *)
  captures: (int * int) IntMap.t;   (* 그룹 번호 → (시작, 끝) *)
}
```

### Step 3: 백트래킹 매처

```ocaml
let rec try_match regex text state =
  match regex with
  | Empty -> Some state

  | Char c ->
      if state.pos < String.length text && text.[state.pos] = c then
        Some { state with pos = state.pos + 1 }
      else
        None  (* 백트래킹 *)

  | Concat (a, b) ->
      (match try_match a text state with
       | Some state' -> try_match b text state'
       | None -> None)

  | Alt (a, b) ->
      (match try_match a text state with
       | Some _ as result -> result
       | None -> try_match b text state)  (* 백트래킹 *)

  | Star a ->
      try_star a regex text state

  | Backref n ->
      let (start_pos, end_pos) = IntMap.find n state.captures in
      let captured = String.sub text start_pos (end_pos - start_pos) in
      if String.sub text state.pos (String.length captured) = captured then
        Some { state with pos = state.pos + String.length captured }
      else
        None

  | ...
```

### Step 4: 그리디 vs 논그리디

```ocaml
(* 그리디: 최대한 많이 매칭 후 필요시 백트래킹 *)
let rec try_star_greedy inner rest text state =
  (* 먼저 더 매칭 시도 *)
  match try_match inner text state with
  | Some state' ->
      (match try_star_greedy inner rest text state' with
       | Some _ as result -> result
       | None -> try_match rest text state)  (* 백트래킹 *)
  | None ->
      try_match rest text state

(* 논그리디 (*?): 최소한만 매칭 *)
let rec try_star_lazy inner rest text state =
  (* 먼저 rest 시도 *)
  match try_match rest text state with
  | Some _ as result -> result
  | None ->
      match try_match inner text state with
      | Some state' -> try_star_lazy inner rest text state'
      | None -> None
```

---

# Part 3: 비교 실험

## ReDoS 테스트

```ocaml
(* 악명 높은 ReDoS 패턴 *)
let redos_pattern = "(a+)+$"
let evil_input n = String.make n 'a' ^ "!"

(* 테스트 *)
let () =
  for n = 10 to 30 do
    let input = evil_input n in

    (* NFA 엔진 - 항상 빠름 *)
    let t1 = time (fun () -> Regex_nfa.matches redos_pattern input) in

    (* 백트래킹 엔진 - 지수적으로 느려짐 *)
    let t2 = time (fun () -> Regex_bt.matches redos_pattern input) in

    Printf.printf "n=%d: NFA=%.3fs, BT=%.3fs\n" n t1 t2
  done
```

예상 출력:
```
n=10: NFA=0.001s, BT=0.001s
n=15: NFA=0.001s, BT=0.032s
n=20: NFA=0.001s, BT=1.024s
n=25: NFA=0.001s, BT=32.768s
n=30: NFA=0.001s, BT=timeout
```

## 기능 테스트

```ocaml
let test_cases = [
  (* 기본 *)
  ("a", "a", true);
  ("a", "b", false);
  ("abc", "abc", true);

  (* 메타문자 *)
  ("a.c", "abc", true);
  ("a.c", "aXc", true);
  ("a.c", "ac", false);

  (* 수량자 *)
  ("a*", "", true);
  ("a*", "aaa", true);
  ("a+", "", false);
  ("a+", "aaa", true);
  ("a?", "", true);
  ("a?", "a", true);
  ("a{2,4}", "aa", true);
  ("a{2,4}", "aaaaa", false);

  (* 문자 클래스 *)
  ("[abc]", "b", true);
  ("[^abc]", "d", true);
  ("[a-z]", "m", true);
  ("[[:digit:]]", "5", true);

  (* 앵커 *)
  ("^abc", "abc", true);
  ("^abc", "xabc", false);
  ("abc$", "abc", true);
  ("abc$", "abcx", false);

  (* 복합 *)
  ("(a|b)*abb", "aabb", true);
  ("(a|b)*abb", "abb", true);
  ("(a|b)*abb", "ab", false);

  (* 백레퍼런스 - 백트래킹 전용 *)
  ("(a+)\\1", "aa", true);
  ("(a+)\\1", "aaaa", true);
  ("(a+)\\1", "aaa", false);
]
```

---

## 파일 구조

```
lib/
├── regex_ast.ml       # AST 정의
├── regex_lexer.ml     # 토크나이저
├── regex_parser.ml    # 파서
├── regex_nfa.ml       # NFA 기반 엔진
├── regex_bt.ml        # 백트래킹 엔진
└── regex.ml           # 통합 인터페이스

test/
└── test_regex.ml      # 테스트
```

## 구현 순서

### Phase 1: 기본 NFA 엔진
1. AST 정의
2. 기본 토크나이저 (리터럴, `*`, `+`, `?`, `|`, `()`)
3. 파서
4. Thompson 구성법 (기본 연산자)
5. 매칭 함수

### Phase 2: POSIX ERE 확장
6. 문자 클래스 `[abc]`, `[a-z]`, `[^abc]`
7. POSIX 클래스 `[:digit:]`
8. 수량자 `{n,m}`
9. 앵커 `^`, `$`
10. 임의 문자 `.`

### Phase 3: 백트래킹 엔진
11. 백트래킹 매처 기본
12. 캡처 그룹
13. 백레퍼런스 `\1`-`\9`
14. 그리디/논그리디

### Phase 4: 비교 및 테스트
15. ReDoS 실험
16. 성능 벤치마크
17. 종합 테스트

---

## 디버깅 팁

### 흔한 실수

1. **연산자 우선순위 오류**
   - `a|bc`는 `a|(bc)`이지 `(a|b)c`가 아님

2. **앵커 처리 누락**
   - `^`는 위치만 체크, 문자 소비 안 함

3. **문자 클래스 범위**
   - `[a-z]`에서 `-`의 위치에 따른 해석

4. **이스케이프 처리**
   - `\\`는 리터럴 백슬래시

### 단계별 디버깅

```
입력: "(a|b)*c"

1. 토큰화:
   [LParen, Char 'a', Pipe, Char 'b', RParen, Star, Char 'c']

2. AST:
   Concat(Star(Alt(Char 'a', Char 'b')), Char 'c')

3. NFA 상태:
   s0 -ε→ s1 -a→ s2 -ε→ s5
   s0 -ε→ s3 -b→ s4 -ε→ s5
   s5 -ε→ s0 (루프백)
   s5 -ε→ s6 -c→ s7 (종료)
   s0 -ε→ s6 (스킵)

4. 매칭 테스트:
   "c"   → ✓ (스킵 경로)
   "ac"  → ✓
   "abc" → ✓
   "a"   → ✗
```

## 참고 자료

- Thompson, K. (1968). "Regular Expression Search Algorithm"
- Cox, R. "Regular Expression Matching Can Be Simple And Fast"
- Sipser, Chapter 1.3: Regular Expressions
- POSIX.2 (IEEE Std 1003.2) - Regular Expressions

## 다음 단계

이 프로젝트 완료 후:
1. [Project 5: Lexer Generator](./05-lexer.md)로 진행
2. DFA 최소화 알고리즘 추가 (선택)
3. 정규식 → DFA 직접 변환 (선택)
