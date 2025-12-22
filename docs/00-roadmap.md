# Automata Theory Learning Roadmap

## Overview

이 로드맵은 오토마타 이론을 프로젝트 기반으로 학습하기 위한 가이드입니다.
각 프로젝트는 이전 프로젝트의 개념을 기반으로 하므로 순서대로 진행하는 것을 권장합니다.

## Prerequisites

- 기본적인 프로그래밍 능력 (Python 권장)
- 집합론 기초 (합집합, 교집합, 멱집합)
- 그래프 기초 (노드, 엣지, 탐색)

## Learning Path

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 1: Finite Automata                     │
├─────────────────────────────────────────────────────────────────┤
│  [Project 1]          [Project 2]          [Project 3]          │
│  DFA Simulator   →    NFA Simulator   →    NFA→DFA Converter    │
│  (1-2 weeks)          (1-2 weeks)          (1-2 weeks)          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 PHASE 2: Regular Languages                      │
├─────────────────────────────────────────────────────────────────┤
│  [Project 4]                    [Project 5]                     │
│  Regex Engine              →    Lexer Generator                 │
│  (2-3 weeks)                    (1-2 weeks)                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               PHASE 3: Context-Free Languages                   │
├─────────────────────────────────────────────────────────────────┤
│  [Project 6]                                                    │
│  CFG Parser (Recursive Descent)                                 │
│  (2-3 weeks)                                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  PHASE 4: Computability                         │
├─────────────────────────────────────────────────────────────────┤
│  [Project 7]                                                    │
│  Turing Machine Simulator                                       │
│  (2-3 weeks)                                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: Finite Automata

### 학습 목표
- 상태 기계(State Machine)의 개념 이해
- 결정적 vs 비결정적 계산 모델의 차이 이해
- 동치성 증명의 직관적 이해

### Project 1: DFA Simulator
- **핵심 개념**: 상태, 전이, 수락/거부
- **결과물**: 문자열이 DFA에 의해 수락되는지 판별하는 시뮬레이터
- **문서**: [01-dfa-simulator.md](./01-dfa-simulator.md)

### Project 2: NFA Simulator
- **핵심 개념**: 비결정성, ε-전이, 동시 상태
- **결과물**: NFA 시뮬레이터 (백트래킹 또는 동시 상태 추적)
- **문서**: [02-nfa-simulator.md](./02-nfa-simulator.md)

### Project 3: NFA to DFA Converter
- **핵심 개념**: 부분집합 구성법, ε-closure
- **결과물**: NFA를 동등한 DFA로 변환하는 변환기
- **문서**: [03-nfa-to-dfa.md](./03-nfa-to-dfa.md)

## Phase 2: Regular Languages

### 학습 목표
- 정규 표현식과 유한 오토마타의 동치성 이해
- 실제 정규식 엔진의 작동 원리 파악
- 렉서(어휘 분석기)의 역할과 구현 방법 이해

### Project 4: Regex Engine
- **핵심 개념**: Thompson 구성법, 정규식 파싱
- **결과물**: 기본 정규식을 지원하는 매칭 엔진
- **문서**: [04-regex-engine.md](./04-regex-engine.md)

### Project 5: Lexer Generator
- **핵심 개념**: 토큰화, 최장 매치, 우선순위
- **결과물**: 토큰 규칙을 받아 렉서를 생성하는 도구
- **문서**: [05-lexer.md](./05-lexer.md)

## Phase 3: Context-Free Languages

### 학습 목표
- 정규 언어의 한계 이해 (펌핑 보조정리)
- 문맥 자유 문법과 파스 트리 이해
- 파싱 알고리즘의 원리 파악

### Project 6: CFG Parser
- **핵심 개념**: CFG, 재귀 하강 파싱, AST
- **결과물**: 수식 언어를 파싱하는 파서
- **문서**: [06-cfg-parser.md](./06-cfg-parser.md)

## Phase 4: Computability

### 학습 목표
- 계산 가능성의 정의 이해
- 튜링 기계의 보편성 이해
- 결정 불가능 문제의 존재 인식

### Project 7: Turing Machine Simulator
- **핵심 개념**: 테이프, 헤드, 무한 메모리
- **결과물**: 튜링 기계 정의를 실행하는 시뮬레이터
- **문서**: [07-turing-machine.md](./07-turing-machine.md)

## Theoretical Concepts by Phase

| Phase | 이론적 개념 | 증명/정리 |
|-------|------------|-----------|
| 1 | DFA, NFA, 상태 최소화 | NFA ≡ DFA (동치성) |
| 2 | 정규 표현식, 정규 문법 | Kleene's Theorem |
| 3 | CFG, PDA, 촘스키 계층 | CFG ≡ PDA |
| 4 | 튜링 기계, 계산 가능성 | Halting Problem (비결정성) |

## Recommended Resources

### 교재
- "Introduction to the Theory of Computation" - Michael Sipser
- "Automata and Computability" - Dexter Kozen

### 온라인 자료
- MIT OpenCourseWare: Theory of Computation
- Stanford CS154: Introduction to Automata and Complexity Theory

## Directory Structure

```
automata/
├── docs/                    # 이 문서들
│   ├── 00-roadmap.md
│   ├── 01-dfa-simulator.md
│   ├── 02-nfa-simulator.md
│   ├── 03-nfa-to-dfa.md
│   ├── 04-regex-engine.md
│   ├── 05-lexer.md
│   ├── 06-cfg-parser.md
│   └── 07-turing-machine.md
├── projects/                # 프로젝트 구현
│   ├── 01-dfa/
│   ├── 02-nfa/
│   ├── 03-nfa-to-dfa/
│   ├── 04-regex/
│   ├── 05-lexer/
│   ├── 06-parser/
│   └── 07-turing/
└── tests/                   # 테스트 케이스
```

## Tips for Success

1. **이론과 구현을 병행하라**: 개념을 배우면 바로 코드로 구현해보기
2. **시각화를 활용하라**: 상태 다이어그램을 그려보면 이해가 빨라짐
3. **테스트 케이스를 먼저 작성하라**: 예상 동작을 먼저 정의
4. **점진적으로 확장하라**: 최소 기능부터 시작해서 기능 추가
5. **손으로 시뮬레이션하라**: 코드 작성 전에 손으로 알고리즘 수행해보기
