# Project 2: NFA Simulator

## 개요

NFA(Non-deterministic Finite Automaton) 시뮬레이터를 구현합니다.
DFA와 달리 하나의 입력에 대해 여러 전이가 가능하고, 입력 없이 전이하는 ε-전이가 있습니다.

## 학습 목표

- 비결정성(Non-determinism)의 개념 이해
- ε-전이와 ε-closure의 개념 파악
- 집합 기반 상태 추적 구현

## 이론적 배경

### NFA의 정의

NFA는 5-tuple (Q, Σ, δ, q₀, F)로 정의됩니다:

| 요소 | 의미 | DFA와의 차이 |
|------|------|-------------|
| Q | 상태 집합 | 동일 |
| Σ | 입력 알파벳 | 동일 |
| δ | 전이 함수 | δ: Q × (Σ ∪ {ε}) → P(Q) |
| q₀ | 시작 상태 | 동일 |
| F | 수락 상태 집합 | 동일 |

### DFA vs NFA

| 특성 | DFA | NFA |
|------|-----|-----|
| 전이 결과 | 정확히 하나의 상태 | 상태들의 집합 (0개 이상) |
| ε-전이 | 없음 | 있음 |
| 결정성 | 결정적 | 비결정적 |
| 구현 | 단순 | 복잡 |
| 표현력 | 동일 | 동일 |

### ε-전이 (Epsilon Transition)

입력 기호를 소비하지 않고 상태를 전이:

```
    ε           a           ε
(q0) ──→ (q1) ──→ (q2) ──→ ((q3))

"a"를 입력하면:
- q0에서 시작
- ε로 q1에 도달 가능
- a를 읽고 q2로 이동
- ε로 q3에 도달 → 수락
```

### ε-closure

상태 q에서 ε-전이만으로 도달 가능한 모든 상태의 집합:

```
예시:
      ε           ε
(q0) ──→ (q1) ──→ (q2)
  │
  └──ε──→ (q3)

ε-closure(q0) = {q0, q1, q2, q3}
ε-closure(q1) = {q1, q2}
ε-closure(q2) = {q2}
ε-closure(q3) = {q3}
```

### 예시: "ab" 또는 "a"를 인식하는 NFA

```
              a           b
       ┌───→ (q1) ───→ ((q2))
  ε    │
(q0) ──┤
       │      a
       └───→ ((q3))

수락하는 문자열: "a", "ab"
거부하는 문자열: "", "b", "aa", "abb"
```

## Step-by-Step 구현 가이드

### Step 1: 데이터 구조 설계

**목표**: NFA를 표현할 데이터 구조 정의

**할 일**:
1. 전이 함수가 **집합**을 반환하도록 설계
   - `{(state, symbol): {next_states}}`
   - symbol에 ε (빈 문자열 또는 특수 기호) 포함
2. ε을 어떻게 표현할지 결정
   - 빈 문자열 `""`
   - 특수 상수 `EPSILON` 또는 `None`

**확인 사항**:
- [ ] 전이 결과가 집합인가?
- [ ] ε-전이를 표현할 수 있는가?
- [ ] 전이가 없는 경우 빈 집합을 반환하는가?

### Step 2: ε-closure 구현

**목표**: 주어진 상태(들)에서 ε-전이만으로 도달 가능한 모든 상태 계산

**할 일**:
1. 단일 상태에 대한 ε-closure 구현
2. 상태 집합에 대한 ε-closure 구현 (합집합)
3. BFS 또는 DFS로 구현

**알고리즘**:
```
function epsilon_closure(states):
    result ← states (복사본)
    stack ← states의 모든 원소

    while stack is not empty:
        state ← stack.pop()
        for next_state in δ(state, ε):
            if next_state not in result:
                result.add(next_state)
                stack.push(next_state)

    return result
```

**테스트 케이스**:
```
NFA:
q0 --ε--> q1
q1 --ε--> q2
q0 --ε--> q3

입력: {q0}
기대: {q0, q1, q2, q3}

입력: {q1}
기대: {q1, q2}

입력: {q2, q3}
기대: {q2, q3}
```

### Step 3: 단일 기호에 대한 전이 구현

**목표**: 상태 집합에서 하나의 입력 기호에 대한 전이 수행

**할 일**:
1. `move(states, symbol)` 함수 구현
2. 각 상태에서 symbol로 도달 가능한 모든 상태의 합집합 계산
3. 결과에 ε-closure 적용

**알고리즘**:
```
function move(states, symbol):
    result ← empty set

    for state in states:
        result ← result ∪ δ(state, symbol)

    return result

function step(states, symbol):
    moved ← move(states, symbol)
    return epsilon_closure(moved)
```

**테스트 케이스**:
```
NFA: "ab" 또는 "a"를 인식
q0 --ε--> q1, q0 --ε--> q4
q1 --a--> q2
q2 --b--> q3 (수락)
q4 --a--> q5 (수락)

시작 상태 집합: ε-closure({q0}) = {q0, q1, q4}

move({q0, q1, q4}, 'a') = {q2, q5}
step({q0, q1, q4}, 'a') = ε-closure({q2, q5}) = {q2, q5}
```

### Step 4: 문자열 처리 함수 구현

**목표**: 전체 문자열을 처리하여 최종 상태 집합 반환

**할 일**:
1. `process(input_string)` 함수 구현
2. 시작 상태의 ε-closure에서 출발
3. 각 문자에 대해 `step()` 수행
4. 최종 상태 집합 반환

**알고리즘**:
```
function process(input_string):
    current ← epsilon_closure({start_state})

    for each symbol in input_string:
        current ← step(current, symbol)
        if current is empty:
            return empty set  // 조기 종료 가능

    return current
```

**테스트 케이스**:
```
NFA: "ab" 또는 "a"를 인식

입력: ""
기대: {q0, q1, q4}

입력: "a"
기대: {q2, q5}

입력: "ab"
기대: {q3}

입력: "abc"
기대: {} (빈 집합)
```

### Step 5: 수락 여부 판정 구현

**목표**: 문자열이 NFA에 의해 수락되는지 판정

**할 일**:
1. `accepts(input_string)` 함수 구현
2. `process()`를 호출하여 최종 상태 집합 획득
3. 최종 상태 집합과 수락 상태 집합의 교집합이 비어있지 않은지 확인

**알고리즘**:
```
function accepts(input_string):
    final_states ← process(input_string)
    return (final_states ∩ accept_states) ≠ ∅
```

**테스트 케이스**:
```
NFA: "ab" 또는 "a"를 인식

입력: ""      → 기대: False
입력: "a"     → 기대: True
입력: "ab"    → 기대: True
입력: "abc"   → 기대: False
입력: "b"     → 기대: False
입력: "aa"    → 기대: False
```

### Step 6: 실행 추적(Trace) 기능 구현

**목표**: 문자열 처리 과정을 단계별로 보여주기

**할 일**:
1. `trace(input_string)` 함수 구현
2. 각 단계의 (현재상태집합, 입력기호, 다음상태집합)을 기록

**출력 예시**:
```
입력: "ab"

추적:
  시작: ε-closure({q0}) = {q0, q1, q4}

  'a': {q0, q1, q4} → move → {q2, q5} → ε-closure → {q2, q5}
  'b': {q2, q5} → move → {q3} → ε-closure → {q3}

최종 상태: {q3}
수락 상태와 교집합: {q3}
결과: 수락
```

### Step 7: 백트래킹 방식 구현 (대안)

**목표**: 집합 기반 대신 재귀적 백트래킹으로 구현

**할 일**:
1. 재귀 함수로 가능한 모든 경로 탐색
2. 하나라도 수락 상태에 도달하면 True

**알고리즘**:
```
function accepts_backtrack(state, remaining_input):
    // ε-전이 먼저 시도
    for next_state in δ(state, ε):
        if accepts_backtrack(next_state, remaining_input):
            return True

    // 입력이 비었으면 수락 여부 확인
    if remaining_input is empty:
        return state in accept_states

    // 첫 문자로 전이 시도
    symbol ← remaining_input[0]
    rest ← remaining_input[1:]

    for next_state in δ(state, symbol):
        if accepts_backtrack(next_state, rest):
            return True

    return False
```

**비교**:
| 방식 | 장점 | 단점 |
|------|------|------|
| 집합 기반 | 효율적, 중복 방문 없음 | 메모리 사용 |
| 백트래킹 | 메모리 효율적 | 최악의 경우 지수 시간 |

### Step 8: 파일 입출력 구현 (선택)

**파일 형식 예시 (JSON)**:
```json
{
  "states": ["q0", "q1", "q2", "q3"],
  "alphabet": ["a", "b"],
  "transitions": {
    "q0": {"": ["q1", "q2"]},
    "q1": {"a": ["q3"]},
    "q2": {"a": ["q2"], "b": ["q3"]}
  },
  "start": "q0",
  "accept": ["q3"]
}
```

## 추가 연습 문제

### 연습 1: 0으로 시작하거나 1로 끝나는 문자열
- Σ = {0, 1}
- 수락: "0", "01", "1", "001", "111", ...
- 힌트: 두 패턴을 ε-전이로 연결

### 연습 2: "web" 또는 "ebay"를 부분 문자열로 포함
- Σ = {a-z}
- 수락: "web", "webmaster", "ebay", "usedebay", ...
- 힌트: `.*web.*` 와 `.*ebay.*` 의 union

### 연습 3: 길이가 3의 배수인 문자열
- Σ = {a, b}
- 수락: "", "aaa", "abb", "bba", "aaabbb", ...
- 힌트: DFA가 더 자연스러울 수 있음 (비교해보기)

## 디버깅 팁

### 흔한 실수

1. **ε-closure 누락**
   - 시작 시 ε-closure 적용 잊음
   - 전이 후 ε-closure 적용 잊음

2. **무한 루프**
   - ε-closure 계산 시 방문 체크 누락
   - ε-사이클이 있는 경우

3. **빈 전이 처리**
   - 정의되지 않은 전이를 None 대신 빈 집합으로

### 디버깅 체크리스트

```
[ ] ε-closure({start})가 올바른가?
[ ] 각 단계에서 상태 집합이 예상대로인가?
[ ] 빈 문자열 입력이 올바르게 처리되는가?
[ ] 수락 상태가 없는 경우 거부하는가?
```

## 다음 단계

이 프로젝트를 완료했다면:
1. NFA와 DFA의 표현력이 동일함을 직관적으로 이해했는지 확인
2. 어떤 경우에 NFA가 DFA보다 표현하기 쉬운지 생각해보기
3. [Project 3: NFA to DFA Converter](./03-nfa-to-dfa.md)로 진행

## 참고 자료

- Sipser, Chapter 1.2: Nondeterminism
- 위키피디아: Nondeterministic finite automaton
