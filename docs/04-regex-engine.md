# Project 4: Regex Engine

## 개요

기본 정규 표현식을 NFA로 변환하고 문자열 매칭을 수행하는 엔진을 구현합니다.
Thompson 구성법을 사용하여 정규식을 NFA로 변환합니다.

## 학습 목표

- 정규 표현식과 유한 오토마타의 동치성 이해
- Thompson 구성법 알고리즘 구현
- 정규식 파싱의 기초 이해

## 이론적 배경

### Kleene의 정리

정규 표현식과 유한 오토마타는 동등한 표현력을 가집니다:
- 모든 정규 표현식 → NFA로 변환 가능 (Thompson 구성법)
- 모든 DFA → 정규 표현식으로 변환 가능 (상태 제거법)

### 정규 표현식 문법

기본 연산자 (우선순위 순):

| 우선순위 | 연산자 | 의미 | 예시 |
|---------|--------|------|------|
| 1 (높음) | `*` | 클레이니 스타 (0회 이상) | `a*` |
| 1 | `+` | 클레이니 플러스 (1회 이상) | `a+` |
| 1 | `?` | 옵션 (0회 또는 1회) | `a?` |
| 2 | 연결 | 순차적 결합 | `ab` |
| 3 (낮음) | `\|` | 선택 (또는) | `a\|b` |

괄호 `()`로 우선순위 변경 가능.

### Thompson 구성법

각 정규식 요소를 NFA 조각(fragment)으로 변환:

**1. 빈 문자열 ε**
```
→(start)──ε──→((end))
```

**2. 단일 문자 'a'**
```
→(start)──a──→((end))
```

**3. 연결 AB**
```
→(A.start)───A───→(A.end)──ε──→(B.start)───B───→((B.end))
```

**4. 선택 A|B**
```
          ┌──ε──→(A.start)───A───→(A.end)──ε──┐
→(start)──┤                                    ├──→((end))
          └──ε──→(B.start)───B───→(B.end)──ε──┘
```

**5. 클레이니 스타 A***
```
              ┌────────ε────────┐
              ↓                 │
→(start)──ε──→(A.start)───A───→(A.end)──ε──→((end))
    │                                          ↑
    └─────────────────ε────────────────────────┘
```

### 예시: (a|b)*abb

```
정규식: (a|b)*abb

단계별 구성:
1. 'a' → NFA(a)
2. 'b' → NFA(b)
3. 'a|b' → NFA(a|b)
4. '(a|b)*' → NFA((a|b)*)
5. '(a|b)*a' → 연결
6. '(a|b)*ab' → 연결
7. '(a|b)*abb' → 연결
```

## Step-by-Step 구현 가이드

### Step 1: NFA Fragment 구조 설계

**목표**: NFA 조각을 표현하는 데이터 구조 정의

**할 일**:
1. NFA Fragment 구조 정의
   - 시작 상태
   - 종료 상태 (단일 상태로 제한)
   - 전이들
2. 고유한 상태 이름 생성 방법 결정

**구조 설계**:
```
NFAFragment:
    start_state: State
    end_state: State
    transitions: Map<(State, Symbol), Set<State>>
```

**상태 이름 생성**:
```
counter = 0

function new_state():
    name = "s" + counter
    counter += 1
    return name
```

### Step 2: 기본 NFA 생성 함수 구현

**목표**: 단일 문자와 ε에 대한 NFA 생성

**할 일**:
1. `char_nfa(c)` - 문자 c를 인식하는 NFA
2. `epsilon_nfa()` - 빈 문자열만 인식하는 NFA

**알고리즘**:
```
function char_nfa(c):
    start = new_state()
    end = new_state()
    transitions = {(start, c): {end}}
    return NFAFragment(start, end, transitions)

function epsilon_nfa():
    start = new_state()
    end = new_state()
    transitions = {(start, ε): {end}}
    return NFAFragment(start, end, transitions)
```

### Step 3: 연결(Concatenation) 구현

**목표**: 두 NFA 조각을 순차적으로 연결

**할 일**:
1. `concat(nfa1, nfa2)` 함수 구현
2. nfa1의 종료 상태에서 nfa2의 시작 상태로 ε-전이 추가

**알고리즘**:
```
function concat(nfa1, nfa2):
    // nfa1의 종료 → nfa2의 시작 연결
    new_transitions = merge(nfa1.transitions, nfa2.transitions)
    add_transition(new_transitions, nfa1.end, ε, nfa2.start)

    return NFAFragment(
        start = nfa1.start,
        end = nfa2.end,
        transitions = new_transitions
    )
```

**시각화**:
```
Before:
  NFA1: →(s0)──a──→(s1)
  NFA2: →(s2)──b──→(s3)

After concat(NFA1, NFA2):
  →(s0)──a──→(s1)──ε──→(s2)──b──→((s3))
```

### Step 4: 선택(Union) 구현

**목표**: 두 NFA 조각 중 하나를 선택

**할 일**:
1. `union(nfa1, nfa2)` 함수 구현
2. 새 시작/종료 상태 생성
3. ε-전이로 연결

**알고리즘**:
```
function union(nfa1, nfa2):
    start = new_state()
    end = new_state()

    new_transitions = merge(nfa1.transitions, nfa2.transitions)

    // 새 시작에서 양쪽으로 분기
    add_transition(new_transitions, start, ε, nfa1.start)
    add_transition(new_transitions, start, ε, nfa2.start)

    // 양쪽 끝에서 새 종료로 합류
    add_transition(new_transitions, nfa1.end, ε, end)
    add_transition(new_transitions, nfa2.end, ε, end)

    return NFAFragment(start, end, new_transitions)
```

**시각화**:
```
         ┌──ε──→(s0)──a──→(s1)──ε──┐
→(new)───┤                          ├───→((new_end))
         └──ε──→(s2)──b──→(s3)──ε──┘
```

### Step 5: 클레이니 스타 구현

**목표**: NFA 조각의 0회 이상 반복

**할 일**:
1. `star(nfa)` 함수 구현
2. 새 시작/종료 상태 생성
3. 루프백 ε-전이와 스킵 ε-전이 추가

**알고리즘**:
```
function star(nfa):
    start = new_state()
    end = new_state()

    new_transitions = copy(nfa.transitions)

    // 시작 → NFA 시작
    add_transition(new_transitions, start, ε, nfa.start)

    // 시작 → 종료 (0회 매칭)
    add_transition(new_transitions, start, ε, end)

    // NFA 종료 → NFA 시작 (반복)
    add_transition(new_transitions, nfa.end, ε, nfa.start)

    // NFA 종료 → 종료
    add_transition(new_transitions, nfa.end, ε, end)

    return NFAFragment(start, end, new_transitions)
```

**시각화**:
```
           ┌────────ε────────┐
           ↓                 │
→(start)──ε──→(s0)──a──→(s1)─┴─ε──→((end))
    │                                 ↑
    └─────────────ε───────────────────┘
```

### Step 6: 플러스와 옵션 구현

**목표**: `+`와 `?` 연산자 구현

**할 일**:
1. `plus(nfa)` - 1회 이상 반복
2. `option(nfa)` - 0회 또는 1회

**알고리즘**:
```
function plus(nfa):
    // A+ = AA* (A 다음에 A*)
    return concat(nfa, star(copy(nfa)))

    // 또는 직접 구현: star와 비슷하지만 스킵 ε-전이 없음

function option(nfa):
    // A? = A|ε
    return union(nfa, epsilon_nfa())

    // 또는 직접 구현: 시작→종료 ε-전이만 추가
```

### Step 7: 정규식 파싱 - 토큰화

**목표**: 정규식 문자열을 토큰 리스트로 변환

**할 일**:
1. 특수 문자 식별: `|`, `*`, `+`, `?`, `(`, `)`
2. 이스케이프 처리: `\*`, `\\` 등
3. 일반 문자와 구분

**토큰 종류**:
```
CHAR      - 일반 문자 (a, b, 1, 2, ...)
STAR      - *
PLUS      - +
QUESTION  - ?
PIPE      - |
LPAREN    - (
RPAREN    - )
```

**예시**:
```
입력: "(a|b)*abb"
출력: [LPAREN, CHAR(a), PIPE, CHAR(b), RPAREN, STAR, CHAR(a), CHAR(b), CHAR(b)]
```

### Step 8: 정규식 파싱 - 암묵적 연결 처리

**목표**: 연결 연산자를 명시적으로 삽입

정규식에서 연결은 암묵적입니다 (`ab`는 `a·b`). 파싱을 쉽게 하기 위해 명시적 연결 토큰을 삽입합니다.

**규칙**: 다음 토큰 쌍 사이에 CONCAT 삽입:
```
(CHAR, CHAR), (CHAR, LPAREN), (RPAREN, CHAR),
(RPAREN, LPAREN), (STAR, CHAR), (STAR, LPAREN),
(PLUS, CHAR), (PLUS, LPAREN), (QUESTION, CHAR), (QUESTION, LPAREN)
```

**예시**:
```
입력: [CHAR(a), CHAR(b)]
출력: [CHAR(a), CONCAT, CHAR(b)]

입력: [LPAREN, CHAR(a), RPAREN, CHAR(b)]
출력: [LPAREN, CHAR(a), RPAREN, CONCAT, CHAR(b)]
```

### Step 9: 정규식 파싱 - 중위→후위 변환

**목표**: 연산자 우선순위를 처리하기 위해 후위 표기법으로 변환

**알고리즘**: Shunting-yard 알고리즘

**연산자 우선순위**:
```
STAR, PLUS, QUESTION: 3 (높음)
CONCAT: 2
PIPE: 1 (낮음)
```

**알고리즘**:
```
function to_postfix(tokens):
    output = []
    operator_stack = []

    for token in tokens:
        if token is CHAR:
            output.append(token)
        else if token is LPAREN:
            operator_stack.push(token)
        else if token is RPAREN:
            while top(operator_stack) ≠ LPAREN:
                output.append(operator_stack.pop())
            operator_stack.pop()  // LPAREN 제거
        else:  // 연산자
            while (operator_stack not empty and
                   top(operator_stack) ≠ LPAREN and
                   precedence(top) >= precedence(token)):
                output.append(operator_stack.pop())
            operator_stack.push(token)

    while operator_stack not empty:
        output.append(operator_stack.pop())

    return output
```

**예시**:
```
입력 (중위): a | b * c
       = CHAR(a) PIPE CHAR(b) CONCAT CHAR(c) STAR
후위 변환: CHAR(a) CHAR(b) CHAR(c) STAR CONCAT PIPE
       = a b c * · |
```

### Step 10: 후위 표기법으로 NFA 구축

**목표**: 후위 표기법의 정규식을 NFA로 변환

**알고리즘**:
```
function postfix_to_nfa(postfix_tokens):
    stack = []

    for token in postfix_tokens:
        if token is CHAR(c):
            stack.push(char_nfa(c))

        else if token is CONCAT:
            nfa2 = stack.pop()
            nfa1 = stack.pop()
            stack.push(concat(nfa1, nfa2))

        else if token is PIPE:
            nfa2 = stack.pop()
            nfa1 = stack.pop()
            stack.push(union(nfa1, nfa2))

        else if token is STAR:
            nfa = stack.pop()
            stack.push(star(nfa))

        else if token is PLUS:
            nfa = stack.pop()
            stack.push(plus(nfa))

        else if token is QUESTION:
            nfa = stack.pop()
            stack.push(option(nfa))

    return stack.pop()  // 최종 NFA
```

### Step 11: 매칭 함수 구현

**목표**: 정규식과 문자열의 매칭 여부 판정

**할 일**:
1. 정규식을 NFA로 변환
2. Project 2의 NFA 시뮬레이터로 문자열 처리
3. 수락 여부 반환

**알고리즘**:
```
function match(pattern, text):
    nfa = regex_to_nfa(pattern)
    return nfa.accepts(text)

function regex_to_nfa(pattern):
    tokens = tokenize(pattern)
    tokens_with_concat = insert_concat(tokens)
    postfix = to_postfix(tokens_with_concat)
    return postfix_to_nfa(postfix)
```

### Step 12: 전체 매칭 vs 부분 매칭

**목표**: 전체 문자열 매칭과 부분 문자열 검색 구분

**전체 매칭** (현재 구현):
```
match("ab", "ab")   → True
match("ab", "cab")  → False
match("ab", "abc")  → False
```

**부분 매칭** (search):
```
search("ab", "cab")  → True (위치 1에서 발견)
search("ab", "abc")  → True (위치 0에서 발견)
```

**부분 매칭 구현**:
```
function search(pattern, text):
    // 방법 1: 패턴을 .*pattern.*으로 감싸기
    full_pattern = ".*(" + pattern + ").*"
    return match(full_pattern, text)

    // 방법 2: 모든 시작 위치에서 시도
    for i in range(len(text)):
        if match(pattern, text[i:]):
            return True
    return False
```

## 추가 기능 (선택)

### 문자 클래스 지원

```
[abc]  → a|b|c
[a-z]  → a|b|c|...|z
[^ab]  → a,b를 제외한 모든 문자
.      → 임의의 단일 문자
```

### 앵커 지원

```
^  → 문자열 시작
$  → 문자열 끝
```

### 캡처 그룹

```
(ab)+  → 캡처 그룹
(?:ab)+  → 비캡처 그룹
```

## 추가 연습 문제

### 연습 1: 정규식 테스트

다음 정규식들을 구현하고 테스트하세요:

1. `a*b*` - 0개 이상의 a 다음 0개 이상의 b
2. `(ab)+` - "ab"의 1회 이상 반복
3. `a?b+c*` - 옵션 a, 필수 b들, 옵션 c들

### 연습 2: NFA 상태 수 분석

다음 정규식의 NFA 상태 수를 예측하고 확인하세요:
- `a`
- `a|b`
- `a*`
- `(a|b)*`

### 연습 3: 성능 비교

1. NFA 직접 시뮬레이션
2. NFA→DFA 변환 후 시뮬레이션

두 방식의 성능을 다양한 패턴과 입력으로 비교하세요.

## 디버깅 팁

### 흔한 실수

1. **암묵적 연결 누락**
   - `ab`를 `a`와 `b` 두 개의 분리된 NFA로 처리

2. **연산자 우선순위 오류**
   - `a|bc`를 `(a|b)c`로 처리 (올바른 것: `a|(bc)`)

3. **후위 변환 오류**
   - 스택 연산 순서 실수

### 단계별 검증

```
입력: "(a|b)*c"

1. 토큰화 확인:
   [LPAREN, CHAR(a), PIPE, CHAR(b), RPAREN, STAR, CHAR(c)]

2. 연결 삽입 확인:
   [LPAREN, CHAR(a), PIPE, CHAR(b), RPAREN, STAR, CONCAT, CHAR(c)]

3. 후위 변환 확인:
   [CHAR(a), CHAR(b), PIPE, STAR, CHAR(c), CONCAT]

4. NFA 구축 확인:
   - 상태와 전이가 예상대로인지 확인

5. 매칭 테스트:
   - "c" → True
   - "ac" → True
   - "abc" → True
   - "a" → False
```

## 다음 단계

이 프로젝트를 완료했다면:
1. 정규식의 한계 학습 (aⁿbⁿ 같은 비정규 언어)
2. 백트래킹 vs NFA 시뮬레이션 방식 비교
3. [Project 5: Lexer Generator](./05-lexer.md)로 진행

## 참고 자료

- Sipser, Chapter 1.3: Regular Expressions
- Thompson, K. (1968). "Regular Expression Search Algorithm"
- Cox, R. "Regular Expression Matching Can Be Simple And Fast"
