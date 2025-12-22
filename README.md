# Automata Theory Learning Projects

오토마타 이론을 프로젝트 기반으로 학습하기 위한 자료입니다.

## Overview

촘스키 계층을 따라 단계별로 계산 모델을 구현합니다:

```
Phase 1: Finite Automata     → DFA, NFA, NFA→DFA 변환
Phase 2: Regular Languages   → 정규식 엔진, 렉서
Phase 3: Context-Free        → CFG 파서
Phase 4: Computability       → 튜링 기계
```

## Projects

| # | Project | Description |
|---|---------|-------------|
| 1 | DFA Simulator | 결정적 유한 오토마타 시뮬레이터 |
| 2 | NFA Simulator | 비결정적 유한 오토마타 시뮬레이터 |
| 3 | NFA to DFA | 부분집합 구성법으로 NFA→DFA 변환 |
| 4 | Regex Engine | Thompson 구성법 기반 정규식 엔진 |
| 5 | Lexer Generator | 토큰 규칙으로 어휘 분석기 생성 |
| 6 | CFG Parser | 재귀 하강 파서 구현 |
| 7 | Turing Machine | 튜링 기계 시뮬레이터 |

## Getting Started

1. [docs/00-roadmap.md](docs/00-roadmap.md)에서 전체 학습 경로 확인
2. 각 프로젝트 문서의 Step-by-Step 가이드 따라 구현
3. 테스트 케이스로 검증

## Directory Structure

```
automata/
├── README.md
├── docs/           # 프로젝트 가이드 문서
│   ├── 00-roadmap.md
│   ├── 01-dfa-simulator.md
│   ├── 02-nfa-simulator.md
│   ├── 03-nfa-to-dfa.md
│   ├── 04-regex-engine.md
│   ├── 05-lexer.md
│   ├── 06-cfg-parser.md
│   └── 07-turing-machine.md
├── projects/       # 구현 코드 (직접 작성)
└── tests/          # 테스트 케이스
```

## Prerequisites

- 기본 프로그래밍 능력 (Python 권장)
- 집합론 기초
- 그래프 기초

## References

- "Introduction to the Theory of Computation" - Michael Sipser
- "Compilers: Principles, Techniques, and Tools" (Dragon Book)
- "Crafting Interpreters" - Bob Nystrom
