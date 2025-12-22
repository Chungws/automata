# Project 3: NFA to DFA Converter

## 개요

NFA를 동등한 DFA로 변환하는 변환기를 구현합니다.
이 과정은 "부분집합 구성법(Subset Construction)" 또는 "멱집합 구성법(Powerset Construction)"이라고 합니다.

## 학습 목표

- NFA와 DFA의 동치성 증명 이해
- 부분집합 구성법 알고리즘 구현
- 지수적 상태 폭발의 개념 이해

## 이론적 배경

### 핵심 아이디어

NFA는 "동시에 여러 상태에 있을 수 있다"고 생각할 수 있습니다.
이 "상태들의 집합"을 DFA의 "하나의 상태"로 만듭니다.

```
NFA 상태: q0, q1, q2
    ↓
DFA 상태: ∅, {q0}, {q1}, {q2}, {q0,q1}, {q0,q2}, {q1,q2}, {q0,q1,q2}
         (NFA 상태들의 모든 부분집합 = 멱집합)
```

### 부분집합 구성법

| NFA | DFA |
|-----|-----|
| 상태 집합 Q | 상태 집합 P(Q) (Q의 멱집합) |
| 시작 상태 q₀ | 시작 상태 ε-closure({q₀}) |
| 수락 상태 F | F와 교집합이 있는 모든 부분집합 |
| δ(q, a) = {q₁, q₂, ...} | δ'(S, a) = ε-closure(∪ δ(q, a) for q in S) |

### 예시

**NFA**: "a" 또는 "ab"를 인식

```
     a         b
(q0)───→(q1)───→((q2))
  │
  └──a──→((q3))

ε-전이 없음
```

**변환 과정**:

```
1. 시작: ε-closure({q0}) = {q0}

2. {q0}에서의 전이:
   - 'a': move({q0}, a) = {q1, q3} → ε-closure = {q1, q3}
   - 'b': move({q0}, b) = ∅

3. {q1, q3}에서의 전이:
   - 'a': move({q1, q3}, a) = ∅
   - 'b': move({q1, q3}, b) = {q2} → ε-closure = {q2}

4. {q2}에서의 전이:
   - 'a': ∅
   - 'b': ∅

5. ∅에서의 전이 (dead state):
   - 'a': ∅
   - 'b': ∅
```

**결과 DFA**:

```
상태: {q0}, {q1,q3}, {q2}, ∅
시작: {q0}
수락: {q1,q3}, {q2}  (q2나 q3을 포함하므로)

전이:
  {q0}    --a--> {q1,q3}
  {q0}    --b--> ∅
  {q1,q3} --a--> ∅
  {q1,q3} --b--> {q2}
  {q2}    --a--> ∅
  {q2}    --b--> ∅
  ∅       --a--> ∅
  ∅       --b--> ∅
```

### 상태 폭발

NFA가 n개의 상태를 가지면, DFA는 최대 2ⁿ개의 상태를 가질 수 있습니다.

```
n = 3  → 최대 8개 상태
n = 10 → 최대 1,024개 상태
n = 20 → 최대 1,048,576개 상태
```

실제로는 도달 가능한 상태만 생성하므로 대부분 훨씬 적습니다.

## Step-by-Step 구현 가이드

### Step 1: 필요한 유틸리티 확인

**목표**: Project 2에서 구현한 기능들이 준비되었는지 확인

**필요한 함수들**:
- `epsilon_closure(states)` - 상태 집합의 ε-closure
- `move(states, symbol)` - 상태 집합에서 symbol로의 전이

**확인 사항**:
- [ ] NFA 클래스가 완성되어 있는가?
- [ ] ε-closure가 올바르게 동작하는가?
- [ ] move 함수가 올바르게 동작하는가?

### Step 2: DFA 상태 표현 설계

**목표**: NFA 상태들의 집합을 DFA 상태로 표현

**할 일**:
1. 집합을 해시 가능한 형태로 변환 (frozenset, tuple 등)
2. 또는 집합에 이름 부여 (D0, D1, D2, ...)
3. 집합 → DFA 상태 이름의 매핑 테이블 유지

**설계 선택지**:
```
방법 1: frozenset 직접 사용
  DFA 상태 = frozenset({'q0', 'q1'})

방법 2: 이름 부여
  D0 = {q0}
  D1 = {q0, q1}
  매핑: {frozenset({'q0'}): 'D0', ...}
```

### Step 3: 시작 상태 계산

**목표**: DFA의 시작 상태 결정

**할 일**:
1. NFA 시작 상태의 ε-closure 계산
2. 이를 DFA의 시작 상태로 설정

**알고리즘**:
```
dfa_start = epsilon_closure({nfa.start_state})
```

**테스트**:
```
NFA 시작 상태: q0
q0 --ε--> q1
q1 --ε--> q2

기대 DFA 시작 상태: {q0, q1, q2}
```

### Step 4: 전이 계산 함수 구현

**목표**: DFA 상태(NFA 상태 집합)에서 입력 기호에 대한 전이 계산

**할 일**:
1. `dfa_transition(dfa_state, symbol)` 함수 구현
2. NFA의 move와 ε-closure를 조합

**알고리즘**:
```
function dfa_transition(dfa_state, symbol):
    // dfa_state는 NFA 상태들의 집합
    moved = empty set

    for nfa_state in dfa_state:
        moved = moved ∪ nfa.move(nfa_state, symbol)

    return epsilon_closure(moved)
```

### Step 5: 도달 가능한 상태 탐색

**목표**: 시작 상태에서 도달 가능한 모든 DFA 상태 찾기

**할 일**:
1. BFS/DFS로 상태 공간 탐색
2. 새로운 상태를 발견할 때마다 큐에 추가
3. 모든 전이를 기록

**알고리즘**:
```
function find_reachable_states(nfa):
    dfa_states = empty set
    dfa_transitions = empty map
    worklist = empty queue

    start = epsilon_closure({nfa.start_state})
    worklist.enqueue(start)
    dfa_states.add(start)

    while worklist is not empty:
        current = worklist.dequeue()

        for symbol in nfa.alphabet:
            next_state = dfa_transition(current, symbol)

            // 전이 기록
            dfa_transitions[(current, symbol)] = next_state

            // 새로운 상태면 큐에 추가
            if next_state not in dfa_states:
                dfa_states.add(next_state)
                worklist.enqueue(next_state)

    return dfa_states, dfa_transitions
```

**주의사항**:
- 빈 집합(∅)도 유효한 DFA 상태 (dead state)
- 무한 루프 방지를 위해 방문 체크 필수

### Step 6: 수락 상태 결정

**목표**: DFA의 수락 상태 집합 결정

**할 일**:
1. 각 DFA 상태(NFA 상태 집합)가 NFA 수락 상태를 포함하는지 확인
2. 포함하면 DFA 수락 상태로 지정

**알고리즘**:
```
function find_accept_states(dfa_states, nfa_accept):
    dfa_accept = empty set

    for dfa_state in dfa_states:
        if (dfa_state ∩ nfa_accept) ≠ ∅:
            dfa_accept.add(dfa_state)

    return dfa_accept
```

### Step 7: DFA 객체 생성

**목표**: 계산된 정보로 DFA 객체 생성

**할 일**:
1. 상태 집합을 읽기 쉬운 이름으로 변환 (선택)
2. Project 1의 DFA 클래스 형식에 맞게 변환
3. DFA 객체 반환

**알고리즘**:
```
function nfa_to_dfa(nfa):
    // Step 5: 상태와 전이 계산
    dfa_states, dfa_transitions = find_reachable_states(nfa)

    // Step 6: 수락 상태 결정
    dfa_accept = find_accept_states(dfa_states, nfa.accept_states)

    // Step 3: 시작 상태
    dfa_start = epsilon_closure({nfa.start_state})

    // DFA 생성
    return DFA(
        states = dfa_states,
        alphabet = nfa.alphabet,
        transitions = dfa_transitions,
        start = dfa_start,
        accept = dfa_accept
    )
```

### Step 8: 상태 이름 정리 (선택)

**목표**: 집합 표현을 읽기 쉬운 이름으로 변환

**할 일**:
1. 각 상태 집합에 순번 부여 (D0, D1, ...)
2. 매핑 테이블 생성
3. 전이 함수와 상태 집합 변환

**예시**:
```
원래:
  {q0, q1} --a--> {q2}

변환 후:
  D0 --a--> D1

매핑:
  D0 = {q0, q1}
  D1 = {q2}
```

### Step 9: 검증 구현

**목표**: 변환 결과가 올바른지 검증

**할 일**:
1. 여러 테스트 문자열에 대해 NFA와 DFA 결과 비교
2. NFA가 수락하는 문자열을 DFA도 수락하는지
3. NFA가 거부하는 문자열을 DFA도 거부하는지

**테스트 함수**:
```
function verify_conversion(nfa, dfa, test_strings):
    for s in test_strings:
        nfa_result = nfa.accepts(s)
        dfa_result = dfa.accepts(s)

        if nfa_result ≠ dfa_result:
            report error for string s

    return all tests passed
```

### Step 10: 시각화 출력 (선택)

**목표**: 변환 과정과 결과 시각화

**할 일**:
1. 변환 과정 단계별 출력
2. 결과 DFA를 DOT 형식으로 출력
3. 상태 매핑 테이블 출력

**출력 예시**:
```
=== NFA to DFA Conversion ===

NFA States: {q0, q1, q2, q3}
NFA Accept: {q2, q3}

Step 1: Start state
  ε-closure({q0}) = {q0}
  DFA start: D0 = {q0}

Step 2: Processing D0 = {q0}
  D0 --a--> {q1, q3} (new state D1)
  D0 --b--> ∅ (new state D2)

Step 3: Processing D1 = {q1, q3}
  D1 --a--> ∅ = D2
  D1 --b--> {q2} (new state D3)

...

=== Result DFA ===
States: D0, D1, D2, D3
Start: D0
Accept: D1, D3

Transitions:
  D0 --a--> D1
  D0 --b--> D2
  ...

State Mapping:
  D0 = {q0}
  D1 = {q1, q3}
  D2 = ∅
  D3 = {q2}
```

## 최적화 (선택)

### Dead State 제거

빈 집합 상태(∅)와 그로 가는 전이를 제거:

```
전: D0 --a--> D1, D0 --b--> ∅, ∅ --a--> ∅, ∅ --b--> ∅
후: D0 --a--> D1 (b 전이는 암묵적 거부)
```

### 도달 불가능 상태 제거

시작 상태에서 도달할 수 없는 상태 제거 (Step 5의 알고리즘을 사용하면 자동으로 제거됨)

### 상태 최소화

동등한 상태를 합치는 알고리즘 (별도 프로젝트로 분리 가능):
- Hopcroft의 알고리즘
- Moore의 알고리즘

## 추가 연습 문제

### 연습 1: 변환 후 상태 수 비교

다음 NFA들을 DFA로 변환하고 상태 수를 비교하세요:

1. "aa" 또는 "bb"를 인식하는 NFA
2. 끝에서 세 번째 문자가 'a'인 문자열
3. "ab"를 부분 문자열로 포함하는 문자열

### 연습 2: 최악의 경우 구성

n개 상태 NFA가 2ⁿ개 상태 DFA로 변환되는 예시를 만들어보세요.

힌트: 끝에서 n번째 문자가 'a'인 문자열을 인식하는 NFA

### 연습 3: 왕복 변환

1. DFA → NFA 변환 구현 (간단함: 전이 결과를 싱글톤 집합으로)
2. NFA → DFA → NFA → DFA 변환 후 상태 수 비교

## 디버깅 팁

### 흔한 실수

1. **ε-closure 누락**
   - 시작 상태 계산 시 ε-closure 적용 잊음
   - 전이 계산 시 ε-closure 적용 잊음

2. **빈 집합 처리**
   - ∅도 유효한 DFA 상태임을 잊음
   - ∅에서의 전이도 정의해야 함 (자기 자신으로)

3. **상태 동일성 비교**
   - 집합 비교 시 순서 무시 확인
   - frozenset 사용 또는 정렬 후 비교

### 디버깅 체크리스트

```
[ ] 시작 상태가 ε-closure 적용되었는가?
[ ] 모든 알파벳 기호에 대해 전이가 계산되었는가?
[ ] 빈 집합 상태가 처리되었는가?
[ ] 새로운 상태만 큐에 추가되는가?
[ ] 수락 상태가 올바르게 결정되었는가?
```

## 다음 단계

이 프로젝트를 완료했다면:
1. DFA 상태 최소화 알고리즘 학습
2. 정규 표현식과 유한 오토마타의 관계 이해
3. [Project 4: Regex Engine](./04-regex-engine.md)로 진행

## 참고 자료

- Sipser, Chapter 1.2: NFA와 DFA의 동치성
- 위키피디아: Powerset construction
- Dragon Book, Chapter 3: Lexical Analysis
