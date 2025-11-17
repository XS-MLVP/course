---
title: Introduction
description: Overview and installation.
categories: [Tutorial]
tags: [docs]
weight: 1
---

{{% pageinfo %}}
As chip designs grow in complexity, verification effort and time increase dramatically, while LLM capabilities have surged. UCAgent is an LLM-driven automation agent for hardware unit-test verification, aiming to reduce repetitive verification work via staged workflow and tool orchestration.
This document covers Introduction, Installation, Usage, Workflow, and Advanced.
{{% /pageinfo %}}

## Introduction

### Background

- Verification time already accounts for 50–60% of chip development; design engineers spend ~49% of their time on verification, yet first-silicon success rate in 2024 was only ~14%.
- With the rise of LLMs and coding agents, reframing "hardware verification" as a "software testing problem" enables high automation.

### What is UCAgent

- An LLM-driven AI agent for unit-test (UT) of chip designs, centered on a staged workflow + tool orchestration to semi/fully automate requirement understanding, test generation, execution, and report.
- Collaboration-first: user-led with LLM as assistant.
- Built on Picker & Toffee; DUTs are tested as Python packages; integrates with OpenHands/Copilot/Claude Code/Gemini-CLI/Qwen Code via MCP.

### Capabilities and Goals

- Semi/fully automated: generate/refine tests and docs, run cases, and summarize reports.
- Completeness: functional coverage, line coverage, and doc consistency.
- Integrable: standard CLI, TUI; MCP server for external code agents.
- Goal: reduce repetitive human effort in verification.

## Installation

### System Requirements

- Python: 3.11+
- OS: Linux / macOS
- API: OpenAI-compatible API
- Memory: 4GB+ recommended
- Dependency: [picker](https://github.com/XS-MLVP/picker) (export Verilog DUT to a Python package)

### Methods

- Method 1: Clone and install

  ```bash
  git clone https://github.com/XS-MLVP/UCAgent.git
  cd UCAgent
  pip3 install .
  ```

- Method 2: pip install
  ```bash
  pip3 install git+https://git@github.com/XS-MLVP/UCAgent@main
  ucagent --help # verify installation
  ```

## Usage

### Quick Start

1. Install UCAgent via pip

   ```bash
   pip3 install git+https://git@github.com/XS-MLVP/UCAgent@main
   ```

2. Prepare DUT

- Create directory `{workspace}/Adder` where `{workspace}` is where `ucagent` runs.
  - `mkdir -p Adder`
- RTL: use the adder from Quick Start: https://open-verify.cc/mlvp/docs/quick-start/eg-adder/ and put it at `Adder/Adder.v`.
- Inject a bug: change output width to 63-bit (demonstrate width error).

  - Change line with `output [WIDTH-1:0] sum,` to `output [WIDTH-2:0] sum,` (e.g. line 9). Current Verilog:

    ```verilog{.line-numbers}
    // A verilog 64-bit full adder with carry in and carry out

    module Adder #(
        parameter WIDTH = 64
    ) (
        input [WIDTH-1:0] a,
        input [WIDTH-1:0] b,
        input cin,
        output [WIDTH-2:0] sum,
        output cout
    );

    assign {cout, sum}  = a + b + cin;

    endmodule
    ```

3. Export RTL to Python Module
   > picker can package the RTL verification module into a shared library and provide Python APIs to drive the circuit. See [Env Usage - Picker](https://open-verify.cc/mlvp/docs/env_usage/picker_usage/) and [picker docs](https://github.com/XS-MLVP/picker/blob/master/README.zh.md)

- From `{workspace}` run: `picker export Adder/Adder.v --rw 1 --sname Adder --tdir output/ -c -w output/Adder/Adder.fst`

4. Write README

- Document adder description, verification goals, bug analysis, etc. in `Adder/README.md` and copy it to `output/Adder/README.md`.

5. Install Qwen Code CLI

- Install globally via npm: `sudo npm install -g @qwen-code/qwen-code` (requires [nodejs](https://nodejs.org/)).
- More ways: [Qwen Code Deployment](https://qwenlm.github.io/qwen-code-docs/zh/deployment/)

6. Configure Qwen Code CLI

- Edit `~/.qwen/settings.json`:

```json
{
	"mcpServers": {
		"unitytest": {
			"httpUrl": "http://localhost:5000/mcp",
			"timeout": 10000
		}
	}
}
```

7. Start MCP Server <a id="command"></a>

- In `{workspace}`:
  ```bash
  ucagent output/ Adder -s -hm --tui --mcp-server-no-file-tools --no-embed-tools
  ```
  Seeing the following UI means success:
  ![tui.png](/docs/ucagent/introduce/tui.png)

8. Start Qwen Code

- In `UCAgent/output` run `qwen` to start Qwen Code; you should see >QWEN.

![qwen.png](/docs/ucagent/introduce/qwen.png)

9. Start verification

- In the console, enter the prompt and approve Qwen Code tool/command/file permission requests via `j/k`:
  > Please get your role and basic guidance via RoleInfo, then complete the task. Use ReadTextFile to read files. Operate only within the current working directory; do not go outside it.

![qwen-allow.png](/docs/ucagent/introduce/qwen-allow.png)

Sometimes Qwen Code pauses. You can confirm via the server TUI whether tasks are finished.

![tui-pause.png](/docs/ucagent/introduce/tui-pause.png)
If Mission shows stage still at 13, continue execution.

![qwen-pause.png](/docs/ucagent/introduce/qwen-pause.png)
If paused mid-way, simply type "continue" to proceed.

10. Results <a id="detailed-output"></a>

All results are under `output`:

```bash
.
├── Adder              # packaged Python DUT
├── Guide_Doc          # various template / specification files
├── uc_test_report     # toffee-test report (index.html etc.)
└── unity_test         # generated verification docs and test cases
    └── tests          # test case source and support files
```

- Guide_Doc: these files are "specification / example / template" style reference documents. On startup they are copied from `vagent/lang/zh/doc/Guide_Doc` into the workspace `Guide_Doc/` (here with `output` as workspace it is `output/Guide_Doc/`). They are not executed directly. They serve humans and AI as paradigms and norms for writing unity_test documentation and tests, and are read by semantic-retrieval tools during initialization.

  - dut_functions_and_checks.md  
    Purpose: defines the organization and naming norms for Function Groups FG-, Function Points FC-, and Check Points CK-\*. Must cover all function points; at least one check per function point.  
    Final artifact: unity_test/{DUT}\_functions_and_checks.md (e.g. `Adder_functions_and_checks.md`).
  - dut_fixture.md  
    Purpose: explains how to write the DUT Fixture / Env (interfaces, timing, reset, stimulus, monitor, check, hooks, etc.), giving standard form and required items.  
    Artifact: unity_test/DutFixture and EnvFixture related implementation / docs.
  - dut_api_instruction.md  
    Purpose: DUT API design & documentation spec (naming, parameters, returns, constraints, boundary conditions, error handling, examples).  
    Artifact: unity_test/{DUT}\_api.md or the API implementation + tests (e.g. `Adder_api.py`).
  - dut_function_coverage_def.md  
    Purpose: functional coverage definition method; how to derive coverage items (covergroup / coverpoint / bin) from FG/FC/CK, and organization / naming rules.  
    Artifact: coverage definition file and generated coverage data, plus related explanatory doc (e.g. `Adder_function_coverage_def.py`).
  - dut_line_coverage.md  
    Purpose: line coverage collection and analysis method; how to enable, count, interpret missed lines, and locate redundant or missing tests.  
    Artifact: line coverage data file and analysis notes (unity_test/{DUT}\_line_coverage_analysis.md, e.g. `Adder_line_coverage_analysis.md`).
  - dut_test_template.md  
    Purpose: skeleton / template for test cases; minimal viable structure and writing paradigm (Arrange-Act-Assert, setup/teardown, marks/selectors, etc.).  
    Artifact: baseline structural reference for concrete test files under tests/.
  - dut_test_case.md  
    Purpose: single test case authoring spec (naming, input space, boundary / exceptional cases, reproducibility, assertion quality, logging, marks).  
    Artifact: quality baseline and fill requirements for tests/test_xxx.py::test_yyy cases.
  - dut_test_program.md  
    Purpose: test plan / test orchestration (regression sets, layered / staged execution, marks & selection, timeout control, ordering, dependencies).  
    Artifact: regression configuration, commands / scripts, staged execution strategy docs.
  - dut_test_summary.md  
    Purpose: structure of stage / final summary (pass rate, coverage, main issues, fix status, risks / remaining problems, next plans).  
    Artifact: unity_test/{DUT}\_test_summary.md (e.g. `Adder_test_summary.md`) or report page (`output/uc_test_report`).
  - dut_bug_analysis.md  
    Purpose: Bug recording & analysis spec (reproduction steps, root cause, impact scope, fix suggestion, verification status, tags & tracking).  
    Artifact: unity_test/{DUT}\_bug_analysis.md (e.g. `Adder_bug_analysis.md`).

- uc_test_report: generated by toffee-test (index.html).  
  Contains line coverage, functional coverage, test case pass status, function point marks, etc.

- unity_test/tests: verification code directory:

  - `Adder.ignore`  
    Role: line coverage ignore list. Supports ignoring entire files or code segments via start-end line ranges.  
    Used by: `Adder_api.py` through `set_line_coverage(request, get_coverage_data_path(request, new_path=False), ignore=current_path_file("Adder.ignore"))`.  
    Relation to Guide_Doc: references `dut_line_coverage.md` (explains enabling / counting / analyzing line coverage, and meaning / scenarios for ignore rules).
  - `Adder_api.py`  
    Role: test common base: concentrates DUT construction, coverage wiring & sampling, pytest base fixtures and sample API.  
    Includes:
    - create_dut(request): instantiate DUT, set coverage file, optional waveform, bind StepRis sampling.
    - AdderEnv: encapsulates pins and common operations (Step).
    - api_Adder_add: exposed test API completing parameter validation, signal assignment, stepping, result read.
    - pytest fixtures: `dut` (module scope, coverage sampling / collection for toffee_test), `env` (function scope, fresh environment per test).  
      Relation to Guide_Doc:
    - dut_fixture.md: organization of fixtures / environment, Step / StepRis usage and responsibility boundaries.
    - dut_api_instruction.md: API design (naming, parameter constraints, returns, examples, exceptions) and doc spec.
    - dut_function_coverage_def.md: how functional coverage groups are wired to DUT and sampled in StepRis.
    - dut_line_coverage.md: setting line coverage file, ignore list, and reporting data to toffee_test.
  - `Adder_function_coverage_def.py`  
    Role: functional coverage definition: declares FG/FC/CK and watch*point conditions.  
    Defines coverage groups: FG-API, FG-ARITHMETIC, FG-BIT-WIDTH. Under each group defines FC-* and CK-\_ conditions (e.g. CK-BASIC / CK-CARRY-IN / CK-OVERFLOW etc.).
    - get_coverage_groups(dut): initialize and return group list for binding & sampling in Adder_api.py.  
      Relation to Guide_Doc:
    - dut_function_coverage_def.md: organization / naming of groups / points, expression of watch_point.
    - dut_functions_and_checks.md: source naming system & mapping; test mark_function coverage must align.
  - `test_Adder_api_basic.py`  
    Role: API-level basic function tests: typical inputs, carry, zero, overflow, boundary, etc.  
    Uses `from Adder_api import *` to get fixtures (dut/env) and API.  
    In each test: env.dut.fc_cover["FG-..."].mark_function("FC-...", <test_fn>, ["CK-..."]) to mark functional coverage hits.  
    Relation to Guide_Doc:
    - dut_test_case.md: single-test structure (goal / flow / expectation), naming & assertion norms, reproducibility, marks & logs.
    - dut_functions_and_checks.md: correct referencing & marking of FG/FC/CK.
    - dut_test_template.md: docstring & structure paradigm.
  - `test_Adder_functional.py`  
    Role: functional behavior tests (scenario / function-item angle), more comprehensive coverage than API basics.  
    Also uses mark_function with FG/FC/CK tags.  
    Relation to Guide_Doc:
    - dut_test_case.md: writing norms & assertion requirements for functional tests.
    - dut_functions_and_checks.md: coverage marking norms & completeness.
    - dut_test_template.md: organizational paradigm.
  - `test_example.py`  
    Role: blank example (scaffold) for minimal template when adding new test files.  
    Relation to Guide_Doc:
    - dut_test_template.md: template for structure, imports, marking method when creating new tests.

- unity_test/\*.md: verification-related docs:
  - Adder_basic_info.md  
    Purpose: DUT overview & interface description (function, ports, types, coarse-grained function classification).  
    Reference: `Guide_Doc/dut_functions_and_checks.md` (interface / function classification wording), `Guide_Doc/dut_fixture.md` (describe I/O & Step from verification view).
  - Adder_verification_needs_and_plan.md  
    Purpose: verification needs & plan (goals, risk points, test item planning, methodology).  
    Reference: `Guide_Doc/dut_test_program.md` (orchestration & selection strategy), `Guide_Doc/dut_test_case.md` (test quality requirements), `Guide_Doc/dut_functions_and_checks.md` (mapping from needs to FG/FC/CK).
  - Adder_functions_and_checks.md  
    Purpose: source list of FG/FC/CK; test marking & functional coverage definitions must match.  
    Reference: `Guide_Doc/dut_functions_and_checks.md` (structure / naming), `Guide_Doc/dut_function_coverage_def.md` (materialization as coverage implementation).
  - Adder_line_coverage_analysis.md  
    Purpose: line coverage conclusions & analysis: explain ignore list, missed lines, supplement suggestions.  
    Reference: `Guide_Doc/dut_line_coverage.md`; plus tests directory `Adder.ignore`.
  - Adder_bug_analysis.md  
    Purpose: defect analysis report: CK/TC correspondence, confidence, root cause, fix suggestions, regression method.  
    Reference: `Guide_Doc/dut_bug_analysis.md` (structure / elements), `Guide_Doc/dut_functions_and_checks.md` (naming consistency).
  - Adder_test_summary.md  
    Purpose: stage / final test summary (execution stats, coverage status, defect distribution, suggestions, conclusions).  
    Reference: `Guide_Doc/dut_test_summary.md`, echoes `Guide_Doc/dut_test_program.md`.

11. Process Summary

What to do:

- Package the DUT (e.g. Adder) as a testable Python module
- Start UCAgent (optionally with MCP Server) to let the code agent collaborate and advance verification by stages
- According to Guide_Doc norms generate / refine unity_test docs and tests, driving by functional + line coverage
- Discover and analyze defects; produce reports and conclusions

What was done:

- Used picker to export RTL as Python package (`output/Adder/`), prepared minimal README & file list
- Started `ucagent` (with `--mcp-server` / `--mcp-server-no-file-tools`), collaborated under TUI / MCP
- Under Guide_Doc constraints, generated / completed:
  - Function & check list: `unity_test/Adder_functions_and_checks.md` (FG/FC/CK)
  - Fixture / environment & API: `tests/Adder_api.py` (`create_dut`, `AdderEnv`, `api_Adder_*`)
  - Functional coverage definition: `tests/Adder_function_coverage_def.py` (bind `StepRis` sampling)
  - Line coverage config & ignore: `tests/Adder.ignore`, analysis `unity_test/Adder_line_coverage_analysis.md`
  - Test case implementation: `tests/test_*.py` (mark_function with FG/FC/CK)
  - Defect analysis & summary: `unity_test/Adder_bug_analysis.md`, `unity_test/Adder_test_summary.md`
- Advanced via tool orchestration: `RunTestCases` / `Check` / `StdCheck` / `KillCheck` / `Complete` / `GoToStage`
- Write permissions restricted to `unity_test/` and `tests` (`add_un_write_path` / `del_un_write_path`)

Achieved effects:

- Semi/fully automated generation of compliant docs and a regression-capable test set (supports full and targeted regression)
- Functional and line coverage data complete; missed points can be located and supplemented
- Defect root cause, fix suggestions, and verification method are evidence-based; structured report formed (`uc_test_report/index.html`)
- Supports MCP integration and TUI collaboration; process can pause / inspect / patch; easy iteration & reuse

Typical operation track (when stuck):

- `Check` → `StdCheck(lines=-1)` → `KillCheck` → fix → `Check` → `Complete`
