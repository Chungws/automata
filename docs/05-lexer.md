# Project 5: Lexer Generator

## 개요

토큰 규칙을 정의하면 어휘 분석기(Lexer)를 생성하는 도구를 구현합니다.
이 프로젝트는 Project 4의 정규식 엔진을 실용적으로 응용합니다.

## 학습 목표

- 컴파일러 프론트엔드의 첫 단계인 어휘 분석 이해
- 최장 매치(Longest Match)와 우선순위 규칙 이해
- 여러 정규식을 결합하여 하나의 DFA로 만드는 방법 이해

## 이론적 배경

### 어휘 분석이란?

소스 코드(문자 스트림)를 토큰 스트림으로 변환하는 과정:

```
입력: "int x = 42 + y;"

출력:
  (KEYWORD, "int")
  (IDENTIFIER, "x")
  (ASSIGN, "=")
  (NUMBER, "42")
  (PLUS, "+")
  (IDENTIFIER, "y")
  (SEMICOLON, ";")
```

### 토큰 규칙

각 토큰 타입은 정규식으로 정의됩니다:

```
NUMBER      : [0-9]+
IDENTIFIER  : [a-zA-Z_][a-zA-Z0-9_]*
KEYWORD     : "int" | "if" | "else" | "while" | "return"
PLUS        : "+"
ASSIGN      : "="
SEMICOLON   : ";"
WHITESPACE  : [ \t\n]+
```

### 최장 매치 규칙 (Maximal Munch)

가능한 가장 긴 토큰을 선택합니다:

```
입력: "integer"

가능한 토큰:
  - "int" (KEYWORD) + "eger" (IDENTIFIER)
  - "integer" (IDENTIFIER)

선택: "integer" (IDENTIFIER) ← 더 긴 매치
```

### 우선순위 규칙

같은 길이로 매치되면 먼저 정의된 규칙 선택:

```
규칙 순서:
  1. KEYWORD: "int"
  2. IDENTIFIER: [a-zA-Z]+

입력: "int"
→ KEYWORD 선택 (더 높은 우선순위)

입력: "integer"
→ IDENTIFIER 선택 (더 긴 매치)
```

### 렉서 구현 방식

```
┌─────────────────────────────────────────────────────────────┐
│                      방식 비교                               │
├─────────────────┬─────────────────┬─────────────────────────┤
│     방식        │      장점       │         단점            │
├─────────────────┼─────────────────┼─────────────────────────┤
│ 개별 NFA 순회   │ 구현 간단       │ 느림                    │
│ 결합 NFA        │ 중간           │ 중간                     │
│ 결합 DFA        │ 빠름           │ 메모리 사용, 구현 복잡   │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## Step-by-Step 구현 가이드

### Step 1: 토큰 정의 구조 설계

**목표**: 토큰 타입과 패턴을 정의하는 구조 설계

**할 일**:
1. TokenRule 구조 정의
2. 토큰 타입(이름)과 패턴(정규식) 저장
3. 우선순위 처리 (정의 순서 = 우선순위)

**구조 설계**:
```
TokenRule:
    name: String        // 토큰 이름 (예: "NUMBER")
    pattern: String     // 정규식 패턴 (예: "[0-9]+")
    skip: Boolean       // True면 토큰 생성 안 함 (예: 공백)

Token:
    type: String        // 토큰 타입
    value: String       // 매치된 문자열
    position: Integer   // 입력에서의 위치
```

### Step 2: 간단한 렉서 구현 (순차 매칭)

**목표**: 가장 간단한 방식으로 동작하는 렉서 구현

**알고리즘**:
```
function tokenize(input, rules):
    tokens = []
    position = 0

    while position < length(input):
        best_match = None
        best_rule = None
        best_length = 0

        // 모든 규칙에 대해 현재 위치에서 매칭 시도
        for rule in rules:
            match = try_match(rule.pattern, input[position:])
            if match and length(match) > best_length:
                best_match = match
                best_rule = rule
                best_length = length(match)

        if best_match is None:
            error("Unexpected character at position " + position)

        if not best_rule.skip:
            tokens.append(Token(best_rule.name, best_match, position))

        position += best_length

    return tokens
```

**테스트**:
```
규칙:
  NUMBER: [0-9]+
  PLUS: \+
  WHITESPACE: [ ]+ (skip)

입력: "12 + 34"
기대: [(NUMBER, "12"), (PLUS, "+"), (NUMBER, "34")]
```

### Step 3: 최장 매치 구현

**목표**: 각 규칙에서 가능한 가장 긴 매치 찾기

**할 일**:
1. 정규식 매칭을 수정하여 최장 매치 반환
2. NFA 시뮬레이션에서 모든 수락 지점 기록
3. 가장 긴 수락 지점 반환

**알고리즘**:
```
function longest_match(nfa, input):
    current_states = epsilon_closure({nfa.start})
    last_accept_pos = -1

    for i, char in enumerate(input):
        // 현재 상태에서 수락 상태가 있으면 기록
        if current_states ∩ nfa.accept ≠ ∅:
            last_accept_pos = i

        // 다음 상태로 전이
        current_states = step(current_states, char)

        // 더 이상 진행 불가능하면 중단
        if current_states is empty:
            break

    // 마지막 위치 체크
    if current_states ∩ nfa.accept ≠ ∅:
        last_accept_pos = length(input)

    if last_accept_pos == -1:
        return None
    return input[0:last_accept_pos]
```

### Step 4: 우선순위 처리 구현

**목표**: 같은 길이의 매치에서 우선순위 적용

**할 일**:
1. 규칙 순서를 우선순위로 사용
2. 같은 길이면 먼저 정의된 규칙 선택

**수정된 알고리즘**:
```
function tokenize(input, rules):
    tokens = []
    position = 0

    while position < length(input):
        best_match = None
        best_rule = None
        best_length = 0
        best_priority = infinity

        for i, rule in enumerate(rules):
            match = longest_match(rule.nfa, input[position:])
            if match:
                // 더 긴 매치 또는 같은 길이지만 높은 우선순위
                if (length(match) > best_length or
                    (length(match) == best_length and i < best_priority)):
                    best_match = match
                    best_rule = rule
                    best_length = length(match)
                    best_priority = i

        // ... 나머지 동일
```

### Step 5: 에러 처리 구현

**목표**: 매칭 실패 시 유용한 에러 메시지 제공

**할 일**:
1. 매칭 실패 위치 보고
2. 문제의 문자 표시
3. 가능하면 복구 시도 (에러 토큰 생성)

**에러 처리 전략**:
```
전략 1: 즉시 중단
  error("Unexpected character '" + char + "' at position " + pos)

전략 2: 에러 토큰 생성 후 계속
  tokens.append(Token("ERROR", char, position))
  position += 1
  continue

전략 3: 동기화 지점까지 건너뛰기
  // 다음 공백이나 알려진 구분자까지 건너뛰기
  while not is_sync_point(input[position]):
      position += 1
```

### Step 6: 줄/열 번호 추적

**목표**: 토큰의 줄과 열 위치 추적

**할 일**:
1. 개행 문자 카운트
2. 열 위치 계산
3. Token 구조에 위치 정보 추가

**확장된 구조**:
```
Token:
    type: String
    value: String
    line: Integer
    column: Integer

Position:
    offset: Integer   // 전체 입력에서의 오프셋
    line: Integer
    column: Integer
```

**위치 추적**:
```
function update_position(current_pos, matched_text):
    for char in matched_text:
        if char == '\n':
            current_pos.line += 1
            current_pos.column = 1
        else:
            current_pos.column += 1
        current_pos.offset += 1
```

### Step 7: 결합 NFA 구성 (최적화)

**목표**: 모든 토큰 규칙을 하나의 NFA로 결합

여러 NFA를 개별로 시뮬레이션하는 대신, 하나의 NFA로 결합하여 한 번에 처리합니다.

**할 일**:
1. 각 규칙의 NFA 생성
2. 새 시작 상태에서 모든 NFA로 ε-전이
3. 각 NFA의 수락 상태에 규칙 번호 태그

**구조**:
```
         ┌─ε─→ [NFA for rule 0] ─→ ((accept, rule=0))
         │
(start)──┼─ε─→ [NFA for rule 1] ─→ ((accept, rule=1))
         │
         └─ε─→ [NFA for rule 2] ─→ ((accept, rule=2))
```

**알고리즘**:
```
function build_combined_nfa(rules):
    start = new_state()
    all_transitions = {}
    accept_to_rule = {}

    for i, rule in enumerate(rules):
        nfa = regex_to_nfa(rule.pattern)

        // ε-전이로 연결
        add_transition(all_transitions, start, ε, nfa.start)

        // 전이 병합
        merge(all_transitions, nfa.transitions)

        // 수락 상태에 규칙 태그
        accept_to_rule[nfa.end] = i

    return CombinedNFA(start, all_transitions, accept_to_rule)
```

### Step 8: 결합 NFA로 토큰화

**목표**: 결합 NFA를 사용하여 효율적으로 토큰화

**알고리즘**:
```
function tokenize_combined(input, combined_nfa):
    tokens = []
    position = 0

    while position < length(input):
        result = simulate_combined(combined_nfa, input[position:])

        if result is None:
            error("Unexpected character")

        match, rule_index = result
        rule = rules[rule_index]

        if not rule.skip:
            tokens.append(Token(rule.name, match, position))

        position += length(match)

    return tokens

function simulate_combined(nfa, input):
    current = epsilon_closure({nfa.start})
    last_accept = None  // (position, rule_index)

    for i, char in enumerate(input):
        // 현재 수락 상태 확인
        accepting = current ∩ nfa.accept_states
        if accepting:
            // 가장 높은 우선순위(낮은 인덱스) 규칙 선택
            best_rule = min(nfa.accept_to_rule[s] for s in accepting)
            last_accept = (i, best_rule)

        current = step(current, char)
        if current is empty:
            break

    // 마지막 위치 체크
    accepting = current ∩ nfa.accept_states
    if accepting:
        best_rule = min(nfa.accept_to_rule[s] for s in accepting)
        last_accept = (length(input), best_rule)

    if last_accept is None:
        return None
    pos, rule_index = last_accept
    return (input[0:pos], rule_index)
```

### Step 9: DFA 변환 (추가 최적화)

**목표**: 결합 NFA를 DFA로 변환하여 더 빠른 매칭

**할 일**:
1. Project 3의 NFA→DFA 변환 사용
2. DFA 상태에 도달 가능한 규칙들 태그
3. DFA 시뮬레이션으로 토큰화

**DFA 상태 태깅**:
```
DFA 상태 {nfa_s1, nfa_s2, nfa_s3}에서:
  - nfa_s1이 rule 0의 수락 상태
  - nfa_s3이 rule 2의 수락 상태
  → DFA 상태는 {rule 0, rule 2} 태그
  → 매칭 시 rule 0 선택 (높은 우선순위)
```

### Step 10: API 설계

**목표**: 사용하기 편리한 인터페이스 설계

**Lexer Generator API**:
```
// 규칙 정의
lexer = LexerGenerator()
lexer.add_rule("NUMBER", r"[0-9]+")
lexer.add_rule("IDENTIFIER", r"[a-zA-Z_][a-zA-Z0-9_]*")
lexer.add_rule("PLUS", r"\+")
lexer.add_rule("WHITESPACE", r"[ \t\n]+", skip=True)

// 렉서 생성
tokenizer = lexer.build()

// 토큰화
tokens = tokenizer.tokenize("x + 123")
// [(IDENTIFIER, "x"), (PLUS, "+"), (NUMBER, "123")]
```

**Iterator 패턴**:
```
tokenizer = lexer.build()
for token in tokenizer.tokens("x + 123"):
    print(token.type, token.value)
```

## 추가 기능 (선택)

### 상태(State) 지원

문자열 리터럴, 주석 등을 위한 상태 기반 렉싱:

```
DEFAULT 상태:
  STRING_START: '"' → STRING 상태로 전환

STRING 상태:
  STRING_CHAR: [^"\\]+
  ESCAPE: \\[nrt"\\]
  STRING_END: '"' → DEFAULT 상태로 전환
```

### 액션(Action) 지원

토큰 매칭 시 커스텀 동작 실행:

```
lexer.add_rule("NUMBER", r"[0-9]+", action=lambda m: int(m))
lexer.add_rule("KEYWORD", r"int|if|while", action=check_keyword)
```

## 실용적인 예제

### 예제 1: 간단한 계산기 렉서

```
규칙:
  NUMBER: [0-9]+(\.[0-9]+)?
  PLUS: \+
  MINUS: -
  MULT: \*
  DIV: /
  LPAREN: \(
  RPAREN: \)
  WHITESPACE: [ \t]+ (skip)

입력: "3.14 * (2 + 1)"
출력:
  (NUMBER, "3.14")
  (MULT, "*")
  (LPAREN, "(")
  (NUMBER, "2")
  (PLUS, "+")
  (NUMBER, "1")
  (RPAREN, ")")
```

### 예제 2: 프로그래밍 언어 렉서

```
규칙 (우선순위 순):
  // 키워드 (식별자보다 먼저!)
  IF: "if"
  ELSE: "else"
  WHILE: "while"
  RETURN: "return"

  // 식별자와 숫자
  IDENTIFIER: [a-zA-Z_][a-zA-Z0-9_]*
  NUMBER: [0-9]+

  // 연산자
  EQ: "=="
  ASSIGN: "="
  LE: "<="
  LT: "<"

  // 구분자
  SEMICOLON: ";"
  LBRACE: "{"
  RBRACE: "}"

  // 공백과 주석
  WHITESPACE: [ \t\n]+ (skip)
  COMMENT: //[^\n]* (skip)
```

## 추가 연습 문제

### 연습 1: JSON 렉서

JSON 문서를 토큰화하는 렉서를 구현하세요:
- STRING, NUMBER, TRUE, FALSE, NULL
- LBRACE, RBRACE, LBRACKET, RBRACKET
- COLON, COMMA

### 연습 2: 키워드 vs 식별자

"interface"가 키워드인 언어의 렉서를 구현하고, "interfaces"가 식별자로 인식되는지 확인하세요.

### 연습 3: 문자열 리터럴

이스케이프 시퀀스(`\n`, `\"`, `\\`)를 포함한 문자열 리터럴을 토큰화하세요.

## 디버깅 팁

### 흔한 실수

1. **우선순위 오류**
   - 키워드를 식별자보다 나중에 정의

2. **최장 매치 실패**
   - `>=`가 `>`와 `=` 두 토큰으로 분리됨

3. **공백 처리 누락**
   - 공백을 skip하지 않아 에러 발생

### 디버깅 출력

```
function tokenize_debug(input, rules):
    ...
    print("Position:", position)
    print("Remaining:", input[position:position+20], "...")
    print("Best match:", best_match, "as", best_rule.name)
    ...
```

## 다음 단계

이 프로젝트를 완료했다면:
1. 정규 언어의 한계를 체감 (중첩 구조 처리 불가)
2. 컴파일러의 다음 단계인 파싱 학습
3. [Project 6: CFG Parser](./06-cfg-parser.md)로 진행

## 참고 자료

- Dragon Book, Chapter 3: Lexical Analysis
- Lex & Flex 도구 문서
- "Crafting Interpreters" - Bob Nystrom
