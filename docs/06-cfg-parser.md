# Project 6: CFG Parser

## 개요

문맥 자유 문법(Context-Free Grammar)을 기반으로 재귀 하강 파서(Recursive Descent Parser)를 구현합니다.
이 프로젝트는 정규 언어를 넘어서는 언어(중첩 구조)를 처리합니다.

## 학습 목표

- 문맥 자유 문법의 개념과 표현력 이해
- 정규 언어의 한계 인식 (왜 CFG가 필요한가)
- 재귀 하강 파싱 기법 구현
- 추상 구문 트리(AST) 구축

## 이론적 배경

### 정규 언어의 한계

정규 언어로 표현할 수 없는 것들:

```
1. 균형 잡힌 괄호: { (, (()), ((())), ... }
   → 유한 상태로 무한한 깊이의 중첩을 추적 불가능

2. aⁿbⁿ = { ab, aabb, aaabbb, ... }
   → a의 개수를 "기억"해야 함

3. 회문(Palindrome): { aba, abba, abcba, ... }
   → 앞부분을 "기억"해야 함
```

**펌핑 보조정리**: 정규 언어가 아님을 증명하는 도구

### 문맥 자유 문법 (CFG)

CFG는 4-tuple (V, Σ, R, S)로 정의됩니다:

| 요소 | 의미 | 예시 |
|------|------|------|
| V | 변수(비터미널) 집합 | {S, E, T, F} |
| Σ | 터미널 집합 | {+, *, (, ), id} |
| R | 생성 규칙 집합 | E → E + T |
| S | 시작 변수 | S |

### BNF 표기법

문법을 표현하는 표준 형식:

```
<expr>   ::= <term> (('+' | '-') <term>)*
<term>   ::= <factor> (('*' | '/') <factor>)*
<factor> ::= NUMBER | '(' <expr> ')'
```

확장 BNF (EBNF):
- `*` : 0회 이상 반복
- `+` : 1회 이상 반복
- `?` : 0회 또는 1회
- `|` : 선택

### 예시: 사칙연산 문법

```
E → E + T | E - T | T
T → T * F | T / F | F
F → ( E ) | number

또는 EBNF로:
E → T (('+' | '-') T)*
T → F (('*' | '/') F)*
F → '(' E ')' | number
```

### 유도 (Derivation)

문법으로 문자열을 생성하는 과정:

```
"3 + 4 * 2" 유도:

E → E + T
  → T + T
  → F + T
  → 3 + T
  → 3 + T * F
  → 3 + F * F
  → 3 + 4 * F
  → 3 + 4 * 2
```

### 파스 트리

유도 과정을 트리로 표현:

```
        E
       /|\
      E + T
      |  /|\
      T T * F
      |  |   |
      F  F   2
      |  |
      3  4
```

### 재귀 하강 파싱

각 비터미널에 대해 함수를 작성:

```
문법:
E → T (('+' | '-') T)*

코드:
function parse_E():
    left = parse_T()
    while current_token in ['+', '-']:
        op = current_token
        advance()
        right = parse_T()
        left = BinaryOp(left, op, right)
    return left
```

## Step-by-Step 구현 가이드

### Step 1: 대상 언어 정의

**목표**: 파싱할 언어의 문법 정의

이 프로젝트에서는 사칙연산 수식을 파싱합니다:

**문법** (EBNF):
```
expression  → term (('+' | '-') term)*
term        → factor (('*' | '/') factor)*
factor      → NUMBER | '(' expression ')'
```

**예시 입력**:
```
"42"
"3 + 4"
"3 + 4 * 2"
"(3 + 4) * 2"
"((1 + 2) * 3) - 4"
```

### Step 2: 토큰 정의

**목표**: 렉서의 출력 토큰 타입 정의

**토큰 타입**:
```
NUMBER    : [0-9]+
PLUS      : '+'
MINUS     : '-'
STAR      : '*'
SLASH     : '/'
LPAREN    : '('
RPAREN    : ')'
EOF       : 입력 끝
```

**토큰 구조**:
```
Token:
    type: TokenType
    value: String (또는 숫자면 int/float)
    position: Integer
```

### Step 3: 렉서 통합 또는 간단한 토크나이저 구현

**목표**: 문자열을 토큰 리스트로 변환

**선택지**:
1. Project 5의 렉서 사용
2. 간단한 토크나이저 직접 구현

**간단한 토크나이저**:
```
function tokenize(input):
    tokens = []
    i = 0

    while i < length(input):
        // 공백 건너뛰기
        while input[i] is whitespace:
            i += 1

        // 숫자
        if input[i] is digit:
            start = i
            while input[i] is digit:
                i += 1
            tokens.append(Token(NUMBER, input[start:i]))

        // 연산자
        else if input[i] == '+':
            tokens.append(Token(PLUS, '+'))
            i += 1
        else if input[i] == '-':
            // ... 등등

    tokens.append(Token(EOF, ''))
    return tokens
```

### Step 4: 파서 기본 구조 설계

**목표**: 파서 클래스의 기본 구조 정의

**파서 구조**:
```
Parser:
    tokens: List<Token>     // 토큰 리스트
    current: Integer        // 현재 위치
    current_token: Token    // 현재 토큰

    // 유틸리티 메서드
    advance()               // 다음 토큰으로 이동
    peek()                  // 현재 토큰 확인 (이동 없이)
    expect(type)            // 특정 타입 확인 및 이동
    match(types...)         // 타입 중 하나면 True + 이동
```

**유틸리티 구현**:
```
function advance():
    current += 1
    if current < length(tokens):
        current_token = tokens[current]

function peek():
    return current_token

function expect(expected_type):
    if current_token.type != expected_type:
        error("Expected " + expected_type + ", got " + current_token.type)
    token = current_token
    advance()
    return token

function match(types...):
    if current_token.type in types:
        advance()
        return True
    return False
```

### Step 5: AST 노드 정의

**목표**: 추상 구문 트리 노드 구조 정의

**노드 타입**:
```
NumberNode:
    value: Number

BinaryOpNode:
    left: Node
    operator: String  // '+', '-', '*', '/'
    right: Node

UnaryOpNode:  // 선택적 확장
    operator: String  // '-' (음수)
    operand: Node
```

**예시**:
```
입력: "3 + 4 * 2"

AST:
  BinaryOpNode(
    left: NumberNode(3),
    operator: '+',
    right: BinaryOpNode(
      left: NumberNode(4),
      operator: '*',
      right: NumberNode(2)
    )
  )
```

### Step 6: Factor 파싱 구현

**목표**: 가장 작은 단위인 factor 파싱

**문법**:
```
factor → NUMBER | '(' expression ')'
```

**구현**:
```
function parse_factor():
    token = current_token

    if token.type == NUMBER:
        advance()
        return NumberNode(token.value)

    else if token.type == LPAREN:
        advance()  // '(' 소비
        expr = parse_expression()
        expect(RPAREN)  // ')' 필수
        return expr

    else:
        error("Unexpected token: " + token)
```

**테스트**:
```
입력: "42"
기대: NumberNode(42)

입력: "(5)"
기대: NumberNode(5)

입력: "+"
기대: 에러
```

### Step 7: Term 파싱 구현

**목표**: 곱셈/나눗셈 처리

**문법**:
```
term → factor (('*' | '/') factor)*
```

**구현**:
```
function parse_term():
    left = parse_factor()

    while current_token.type in [STAR, SLASH]:
        op_token = current_token
        advance()
        right = parse_factor()
        left = BinaryOpNode(left, op_token.value, right)

    return left
```

**테스트**:
```
입력: "3"
기대: NumberNode(3)

입력: "3 * 4"
기대: BinaryOpNode(NumberNode(3), '*', NumberNode(4))

입력: "2 * 3 * 4"
기대: BinaryOpNode(
        BinaryOpNode(NumberNode(2), '*', NumberNode(3)),
        '*',
        NumberNode(4)
      )
```

### Step 8: Expression 파싱 구현

**목표**: 덧셈/뺄셈 처리

**문법**:
```
expression → term (('+' | '-') term)*
```

**구현**:
```
function parse_expression():
    left = parse_term()

    while current_token.type in [PLUS, MINUS]:
        op_token = current_token
        advance()
        right = parse_term()
        left = BinaryOpNode(left, op_token.value, right)

    return left
```

**테스트**:
```
입력: "3 + 4 * 2"
기대: BinaryOpNode(
        NumberNode(3),
        '+',
        BinaryOpNode(NumberNode(4), '*', NumberNode(2))
      )

// 연산자 우선순위가 올바르게 적용됨!
```

### Step 9: 파서 진입점 구현

**목표**: 전체 입력을 파싱하는 메인 함수

**구현**:
```
function parse(input):
    tokens = tokenize(input)
    parser = Parser(tokens)
    ast = parser.parse_expression()

    // 모든 입력이 소비되었는지 확인
    if parser.current_token.type != EOF:
        error("Unexpected token after expression: " + parser.current_token)

    return ast
```

### Step 10: AST 평가기 구현

**목표**: AST를 순회하여 결과 계산

**구현**:
```
function evaluate(node):
    if node is NumberNode:
        return node.value

    else if node is BinaryOpNode:
        left_val = evaluate(node.left)
        right_val = evaluate(node.right)

        if node.operator == '+':
            return left_val + right_val
        else if node.operator == '-':
            return left_val - right_val
        else if node.operator == '*':
            return left_val * right_val
        else if node.operator == '/':
            return left_val / right_val
```

**테스트**:
```
입력: "3 + 4 * 2"
AST 생성 후 평가
기대: 11 (4*2=8, 3+8=11)

입력: "(3 + 4) * 2"
기대: 14 ((3+4)=7, 7*2=14)
```

### Step 11: 에러 처리 개선

**목표**: 유용한 에러 메시지 제공

**에러 종류**:
```
1. 예상치 못한 토큰
   "Expected NUMBER, got PLUS at position 5"

2. 괄호 불일치
   "Unmatched '(' at position 3"
   "Unexpected ')' at position 7"

3. 표현식 불완전
   "Unexpected end of input after '+'"
```

**개선된 에러 처리**:
```
function expect(expected_type):
    if current_token.type != expected_type:
        raise ParseError(
            message: "Expected " + expected_type,
            got: current_token.type,
            position: current_token.position
        )
    ...
```

### Step 12: AST 출력 (시각화)

**목표**: AST를 읽기 쉬운 형태로 출력

**트리 형태 출력**:
```
function print_ast(node, indent=0):
    prefix = "  " * indent

    if node is NumberNode:
        print(prefix + "Number: " + node.value)

    else if node is BinaryOpNode:
        print(prefix + "BinaryOp: " + node.operator)
        print_ast(node.left, indent + 1)
        print_ast(node.right, indent + 1)
```

**출력 예시**:
```
입력: "3 + 4 * 2"

BinaryOp: +
  Number: 3
  BinaryOp: *
    Number: 4
    Number: 2
```

## 확장 구현 (선택)

### 확장 1: 단항 연산자

음수 지원:

```
문법 확장:
factor → NUMBER | '(' expression ')' | '-' factor

코드:
function parse_factor():
    if current_token.type == MINUS:
        advance()
        operand = parse_factor()
        return UnaryOpNode('-', operand)
    // ... 기존 코드
```

### 확장 2: 변수

변수 참조 지원:

```
문법 확장:
factor → NUMBER | IDENTIFIER | '(' expression ')'

평가 시 환경(environment) 필요:
function evaluate(node, env):
    if node is IdentifierNode:
        return env[node.name]
    // ...
```

### 확장 3: 함수 호출

```
문법 확장:
factor → NUMBER | IDENTIFIER | IDENTIFIER '(' args ')' | '(' expression ')'
args   → expression (',' expression)*

예시: "sin(3.14) + cos(0)"
```

### 확장 4: 비교 및 논리 연산

```
문법 확장:
expression → comparison
comparison → term (('==' | '!=' | '<' | '>' | '<=' | '>=') term)*

또는 우선순위 분리:
expression → logical_or
logical_or → logical_and ('||' logical_and)*
logical_and → comparison ('&&' comparison)*
comparison → term (comp_op term)*
```

## 추가 연습 문제

### 연습 1: 거듭제곱 연산자

오른쪽 결합 연산자 `^` 추가:
```
2 ^ 3 ^ 4 = 2 ^ (3 ^ 4) = 2 ^ 81
```

힌트: 재귀 호출 위치 변경

### 연습 2: 삼항 연산자

조건 연산자 `? :` 추가:
```
1 > 0 ? 10 : 20  → 10
```

### 연습 3: 에러 복구

에러 발생 후 파싱을 계속하여 여러 에러 보고:
```
입력: "3 + + 4 * * 5"
출력:
  Error: Unexpected '+' at position 4
  Error: Unexpected '*' at position 10
```

### 연습 4: JSON 파서

JSON 문서를 파싱하는 파서 구현:
```
value  → object | array | STRING | NUMBER | 'true' | 'false' | 'null'
object → '{' (pair (',' pair)*)? '}'
pair   → STRING ':' value
array  → '[' (value (',' value)*)? ']'
```

## 디버깅 팁

### 흔한 실수

1. **무한 재귀**
   - 좌측 재귀 문법을 그대로 구현
   - `E → E + T`를 `parse_E() { parse_E(); ... }`로 구현

2. **토큰 소비 누락**
   - `expect()` 후 `advance()` 호출 (expect가 이미 advance 포함해야 함)
   - 또는 `advance()` 누락

3. **연산자 우선순위 오류**
   - 모든 연산을 같은 수준에서 처리

### 디버깅 출력

```
function parse_expression():
    print("parse_expression: current = " + current_token)
    result = ...
    print("parse_expression: result = " + result)
    return result
```

### 단계별 검증

```
1. 토큰화만 테스트
   "3 + 4" → [NUM(3), PLUS, NUM(4), EOF]

2. 숫자만 파싱
   "42" → NumberNode(42)

3. 괄호만 테스트
   "(42)" → NumberNode(42)

4. 단일 연산
   "3 + 4" → BinaryOp(3, +, 4)

5. 우선순위 테스트
   "3 + 4 * 2" → BinaryOp(3, +, BinaryOp(4, *, 2))
```

## 다음 단계

이 프로젝트를 완료했다면:
1. LL(1) 문법의 조건 학습
2. FIRST/FOLLOW 집합 계산
3. 더 복잡한 언어 파싱 (프로그래밍 언어)
4. [Project 7: Turing Machine](./07-turing-machine.md)로 진행

## 참고 자료

- Sipser, Chapter 2: Context-Free Languages
- Dragon Book, Chapter 4: Syntax Analysis
- "Crafting Interpreters" - Bob Nystrom (Part II)
- "Writing An Interpreter In Go" - Thorsten Ball
