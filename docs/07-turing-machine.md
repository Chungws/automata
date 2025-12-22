# Project 7: Turing Machine Simulator

## 개요

튜링 기계(Turing Machine) 시뮬레이터를 구현합니다.
튜링 기계는 계산 가능한 모든 것을 표현할 수 있는 가장 강력한 계산 모델입니다.

## 학습 목표

- 튜링 기계의 구조와 동작 원리 이해
- 계산 가능성(Computability)의 개념 파악
- 결정 불가능 문제의 존재 인식
- Church-Turing 논제의 의미 이해

## 이론적 배경

### 촘스키 계층 복습

```
┌─────────────────────────────────────────────────────────┐
│                   Type 0: 재귀 열거 언어                  │
│                   (Turing Machine)                       │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Type 1: 문맥 의존 언어                 │  │
│  │              (Linear Bounded Automaton)            │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │           Type 2: 문맥 자유 언어              │  │  │
│  │  │           (Pushdown Automaton)               │  │  │
│  │  │  ┌───────────────────────────────────────┐  │  │  │
│  │  │  │        Type 3: 정규 언어               │  │  │  │
│  │  │  │        (Finite Automaton)              │  │  │  │
│  │  │  └───────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 튜링 기계 구성 요소

```
                    테이프 (무한)
    ... | B | B | a | b | a | c | B | B | ...
                    ↑
                   헤드
                    │
              ┌─────┴─────┐
              │  제어 장치  │
              │  (상태)    │
              └───────────┘
```

### 튜링 기계의 정의

TM은 7-tuple (Q, Σ, Γ, δ, q₀, q_accept, q_reject)로 정의됩니다:

| 요소 | 의미 | 설명 |
|------|------|------|
| Q | 상태 집합 | 유한한 상태들 |
| Σ | 입력 알파벳 | 공백(B)을 포함하지 않음 |
| Γ | 테이프 알파벳 | Σ ⊂ Γ, B ∈ Γ |
| δ | 전이 함수 | Q × Γ → Q × Γ × {L, R} |
| q₀ | 시작 상태 | q₀ ∈ Q |
| q_accept | 수락 상태 | q_accept ∈ Q |
| q_reject | 거부 상태 | q_reject ∈ Q |

### 전이 함수

```
δ(q, a) = (q', b, D)

의미:
- 현재 상태가 q이고
- 헤드가 읽은 기호가 a일 때
- 상태를 q'로 변경하고
- 테이프에 b를 쓰고
- 헤드를 방향 D(L 또는 R)로 이동

표기법:
q, a → q', b, R
```

### 예시: {aⁿbⁿ | n ≥ 1} 인식

```
알고리즘:
1. 가장 왼쪽 'a'를 'X'로 표시
2. 오른쪽으로 이동하여 첫 'b'를 'Y'로 표시
3. 왼쪽으로 이동하여 다음 'a'를 찾음
4. 반복
5. 모든 'a'와 'b'가 표시되면 수락

전이:
q0, a → q1, X, R  // a를 X로 표시, 오른쪽으로
q1, a → q1, a, R  // a 건너뛰기
q1, Y → q1, Y, R  // Y 건너뛰기
q1, b → q2, Y, L  // b를 Y로 표시, 왼쪽으로
q2, Y → q2, Y, L  // Y 건너뛰기
q2, a → q2, a, L  // a 건너뛰기
q2, X → q0, X, R  // X 발견, 다시 시작
q0, Y → q3, Y, R  // 모든 a 처리됨
q3, Y → q3, Y, R  // Y 건너뛰기
q3, B → accept    // 끝에 도달, 수락
```

### 실행 예시

```
입력: "aabb"

설정 (Configuration):
q0[a]abb    // q0 상태, 헤드는 첫 a
─────────────────
Xq1[a]bb    // X 쓰고 오른쪽 이동
Xaq1[b]b    // a 건너뛰고 오른쪽
Xq2[a]Yb    // Y 쓰고 왼쪽 이동
q2[X]aYb    // a 건너뛰고 왼쪽
Xq0[a]Yb    // X 발견, 다시 시작
XXq1[Y]b    // a를 X로, 오른쪽
XXYq1[b]    // Y 건너뛰고 오른쪽
XXq2[Y]Y    // Y 쓰고 왼쪽
Xq2[X]YY    // Y 건너뛰고 왼쪽
XXq0[Y]Y    // X 발견
XXYq3[Y]    // 모든 a 처리됨
XXYYq3[B]   // 끝 도달
ACCEPT      // 수락!
```

### 계산 가능성

**Church-Turing 논제**:
"직관적으로 계산 가능한 모든 함수는 튜링 기계로 계산 가능하다"

이는 증명이 아닌 논제(thesis)이지만, 지금까지 반례가 발견되지 않았습니다.

### 결정 불가능 문제

**정지 문제 (Halting Problem)**:
주어진 튜링 기계 M과 입력 w에 대해, M이 w에서 정지하는지 결정하는 것은 불가능합니다.

```
HALT = { <M, w> | M은 w에서 정지함 }

증명 (대각선 논법):
HALT를 결정하는 TM H가 존재한다고 가정
→ H를 이용해 자기 자신에 대해 역설적 동작하는 D 구성
→ 모순 발생
→ H는 존재하지 않음
```

## Step-by-Step 구현 가이드

### Step 1: 테이프 자료구조 설계

**목표**: 양방향 무한 테이프 구현

**선택지**:
1. 리스트 + 인덱스 (필요시 확장)
2. 딕셔너리 (위치 → 기호)
3. 양방향 연결 리스트

**딕셔너리 기반 구현**:
```
Tape:
    cells: Map<Integer, Symbol>  // 위치 → 기호
    head: Integer                // 현재 헤드 위치
    blank: Symbol                // 공백 기호

function read():
    if head in cells:
        return cells[head]
    return blank

function write(symbol):
    cells[head] = symbol

function move_left():
    head -= 1

function move_right():
    head += 1
```

**리스트 기반 구현**:
```
Tape:
    positive: List<Symbol>  // 0, 1, 2, ...
    negative: List<Symbol>  // -1, -2, -3, ...
    head: Integer

function read():
    if head >= 0:
        extend positive if needed
        return positive[head]
    else:
        extend negative if needed
        return negative[-(head+1)]
```

### Step 2: 전이 함수 표현

**목표**: 전이 함수를 저장하고 조회

**구조**:
```
Transition:
    new_state: State
    write_symbol: Symbol
    direction: Direction  // L or R

TransitionFunction:
    Map<(State, Symbol), Transition>

function get_transition(state, symbol):
    key = (state, symbol)
    if key in transitions:
        return transitions[key]
    return None  // 정의되지 않은 전이
```

### Step 3: 튜링 기계 클래스 설계

**목표**: TM의 모든 구성 요소를 포함하는 클래스

**구조**:
```
TuringMachine:
    states: Set<State>
    input_alphabet: Set<Symbol>
    tape_alphabet: Set<Symbol>
    transitions: TransitionFunction
    start_state: State
    accept_state: State
    reject_state: State
    blank_symbol: Symbol
```

### Step 4: 설정(Configuration) 표현

**목표**: TM의 현재 상태를 스냅샷으로 저장

**구조**:
```
Configuration:
    state: State
    tape: Tape (또는 테이프 내용의 복사본)
    head_position: Integer

function to_string():
    // 테이프 내용과 헤드 위치를 문자열로
    // 예: "aXq1[b]Ya"
```

### Step 5: 단일 스텝 실행 구현

**목표**: 하나의 전이를 수행

**알고리즘**:
```
function step(tm, config):
    current_state = config.state
    current_symbol = tape.read()

    // 종료 상태 체크
    if current_state == tm.accept_state:
        return (ACCEPT, config)
    if current_state == tm.reject_state:
        return (REJECT, config)

    // 전이 조회
    transition = tm.transitions.get((current_state, current_symbol))

    if transition is None:
        // 정의되지 않은 전이 = 거부
        return (REJECT, config)

    // 전이 수행
    tape.write(transition.write_symbol)
    config.state = transition.new_state

    if transition.direction == L:
        tape.move_left()
    else:
        tape.move_right()

    return (RUNNING, config)
```

### Step 6: 실행 루프 구현

**목표**: 정지할 때까지 TM 실행

**알고리즘**:
```
function run(tm, input_string, max_steps=infinity):
    // 초기화
    tape = Tape(input_string, tm.blank_symbol)
    config = Configuration(tm.start_state, tape, 0)

    steps = 0

    while steps < max_steps:
        status, config = step(tm, config)

        if status == ACCEPT:
            return (ACCEPTED, steps, config)
        if status == REJECT:
            return (REJECTED, steps, config)

        steps += 1

    return (TIMEOUT, steps, config)
```

**무한 루프 방지**:
- 최대 스텝 수 제한
- 사용자 인터럽트 지원

### Step 7: 실행 추적(Trace) 구현

**목표**: 각 스텝의 설정을 기록하고 출력

**구현**:
```
function run_with_trace(tm, input_string, max_steps):
    trace = []
    tape = Tape(input_string, tm.blank_symbol)
    config = Configuration(tm.start_state, tape, 0)

    trace.append(config.to_string())

    while steps < max_steps:
        status, config = step(tm, config)
        trace.append(config.to_string())

        if status in [ACCEPT, REJECT]:
            break

    return trace, status
```

**출력 예시**:
```
Step 0: q0[a]abb
Step 1: Xq1[a]bb
Step 2: Xaq1[b]b
Step 3: Xq2[a]Yb
...
Step 12: XXYYq3[B]
Result: ACCEPTED in 12 steps
```

### Step 8: TM 정의 파일 형식

**목표**: 파일에서 TM 정의 로드

**형식 예시 (JSON)**:
```json
{
  "name": "anbn_recognizer",
  "states": ["q0", "q1", "q2", "q3", "accept", "reject"],
  "input_alphabet": ["a", "b"],
  "tape_alphabet": ["a", "b", "X", "Y", "B"],
  "blank": "B",
  "start": "q0",
  "accept": "accept",
  "reject": "reject",
  "transitions": [
    {"from": "q0", "read": "a", "to": "q1", "write": "X", "move": "R"},
    {"from": "q1", "read": "a", "to": "q1", "write": "a", "move": "R"},
    {"from": "q1", "read": "Y", "to": "q1", "write": "Y", "move": "R"},
    {"from": "q1", "read": "b", "to": "q2", "write": "Y", "move": "L"}
  ]
}
```

**형식 예시 (텍스트)**:
```
// 상태, 읽기 -> 새상태, 쓰기, 방향
q0, a -> q1, X, R
q1, a -> q1, a, R
q1, Y -> q1, Y, R
q1, b -> q2, Y, L
q2, Y -> q2, Y, L
q2, a -> q2, a, L
q2, X -> q0, X, R
q0, Y -> q3, Y, R
q3, Y -> q3, Y, R
q3, B -> accept, B, R
```

### Step 9: 시각화 구현

**목표**: 테이프 상태를 시각적으로 표시

**ASCII 시각화**:
```
function visualize(config):
    tape_str = ""
    min_pos = min(tape.cells.keys())
    max_pos = max(tape.cells.keys())

    // 테이프 내용
    for pos in range(min_pos - 2, max_pos + 3):
        if pos == config.head_position:
            tape_str += "[" + tape.read_at(pos) + "]"
        else:
            tape_str += " " + tape.read_at(pos) + " "

    print("State:", config.state)
    print("Tape: ", tape_str)
    print("       ", " " * (head_visual_position) + "^")
```

**출력 예시**:
```
State: q1
Tape:   B   X  [a]  b   b   B
             ^
```

### Step 10: 다중 테이프 TM (확장)

**목표**: 여러 테이프를 가진 TM 구현

**구조**:
```
MultiTapeTM:
    num_tapes: Integer
    tapes: List<Tape>
    heads: List<Integer>

    // 전이: 모든 테이프의 현재 기호를 읽고,
    // 모든 테이프에 쓰고, 각 헤드 이동
    transitions: Map<(State, Tuple<Symbol>), (State, Tuple<Symbol>, Tuple<Direction>)>
```

**이론**: k-테이프 TM은 단일 테이프 TM과 동치 (다항 시간 시뮬레이션 가능)

## 추가 연습 문제

### 연습 1: 이진수 덧셈기

두 이진수를 더하는 TM:
```
입력: 101#11 (5 + 3)
출력: 1000 (8)
```

### 연습 2: 복사기

입력 문자열을 복사하는 TM:
```
입력: abc
출력: abc#abc
```

### 연습 3: 회문 인식기

회문(palindrome)을 인식하는 TM:
```
수락: aba, abba, abcba
거부: ab, abc, aab
```

### 연습 4: 범용 튜링 기계

다른 TM의 정의와 입력을 받아 시뮬레이션하는 TM:
```
입력: <M>#<w>
동작: M을 w에 대해 실행
```

## 구현된 TM 예제들

### 예제 1: {w#w | w ∈ {a,b}*}

문자열 w와 그 복사본 w를 인식:

```
아이디어:
1. 첫 문자를 X로 표시하고 기억
2. #을 넘어가서 대응하는 문자 찾아 X로 표시
3. 반복
4. 모든 문자가 X면 수락

전이 (일부):
q0, a -> q1, X, R  // a 기억, 오른쪽으로
q0, b -> q2, X, R  // b 기억, 오른쪽으로
q1, a -> q1, a, R  // a 찾기 위해 이동
q1, # -> q3, #, R  // # 넘어감 (a 찾는 중)
q3, X -> q3, X, R  // 이미 매칭된 X 건너뛰기
q3, a -> q4, X, L  // a 발견! X로 표시하고 돌아감
...
```

### 예제 2: {aⁿbⁿcⁿ | n ≥ 1}

CFG로 표현 불가능한 언어:

```
아이디어:
1. 가장 왼쪽 a를 X로 표시
2. 가장 왼쪽 b를 Y로 표시
3. 가장 왼쪽 c를 Z로 표시
4. 반복
5. 모두 표시되면 수락
```

## 디버깅 팁

### 흔한 실수

1. **헤드 이동 방향 혼동**
   - L/R을 반대로 사용

2. **공백 기호 처리 누락**
   - 테이프 끝에서의 동작 미정의

3. **전이 누락**
   - 특정 (상태, 기호) 조합에 대한 전이 없음

4. **무한 루프**
   - 종료 조건에 도달하지 못하는 전이 사이클

### 디버깅 전략

```
1. 손으로 먼저 실행해보기
   - 작은 입력에 대해 손으로 전체 실행 추적

2. 상태 전이 다이어그램 그리기
   - 시각적으로 흐름 확인

3. 단계별 실행
   - 각 스텝에서 기대 상태와 비교

4. 경계 케이스 테스트
   - 빈 입력
   - 최소 입력 (예: "ab")
   - 거부되어야 하는 입력
```

### 디버깅 출력

```
function debug_run(tm, input):
    for step, config in enumerate(run_generator(tm, input)):
        print(f"Step {step}:")
        print(f"  State: {config.state}")
        print(f"  Head:  {config.head_position}")
        print(f"  Tape:  {config.tape_visualization()}")
        print(f"  Read:  {config.current_symbol()}")

        transition = tm.get_transition(config.state, config.current_symbol())
        if transition:
            print(f"  Trans: → {transition}")
        else:
            print(f"  Trans: UNDEFINED (will reject)")
        print()
```

## 이론적 심화 주제

### 튜링 기계의 변형들

| 변형 | 설명 | 동치성 |
|------|------|--------|
| 다중 테이프 | k개의 테이프 | 동치 |
| 비결정적 TM | 여러 전이 가능 | 동치 |
| 양방향 무한 테이프 | 왼쪽으로도 무한 | 동치 |
| 다중 헤드 | 한 테이프에 여러 헤드 | 동치 |
| 2D 테이프 | 2차원 테이프 | 동치 |

### 시간/공간 복잡도

- **시간 복잡도**: 실행 스텝 수
- **공간 복잡도**: 사용된 테이프 셀 수

```
P = { L | L은 다항 시간에 결정 가능 }
NP = { L | L은 비결정적 다항 시간에 결정 가능 }
PSPACE = { L | L은 다항 공간에 결정 가능 }
```

## 다음 단계

이 프로젝트를 완료했다면:
1. 결정 가능성과 인식 가능성의 차이 학습
2. Rice의 정리 학습
3. 복잡도 이론 입문 (P vs NP)
4. 람다 계산법(Lambda Calculus) 학습

## 참고 자료

- Sipser, Chapter 3: The Church-Turing Thesis
- Sipser, Chapter 4: Decidability
- Sipser, Chapter 5: Reducibility
- 위키피디아: Turing machine
- "Gödel, Escher, Bach" - Douglas Hofstadter
