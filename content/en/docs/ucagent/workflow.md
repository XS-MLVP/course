---
title: Workflow
description: Overall workflow explanation.
categories: [Tutorial]
tags: [docs]
weight: 3
---

The whole process adopts an "stage‑by‑stage progressive advancement" approach: each stage has a clear goal, outputs and pass criteria; after completion you use tool Check to verify and tool Complete to enter the next stage. If a stage contains sub‑stages, you must finish the sub‑stages one by one in order and each must pass Check.

- Total top‑level stages: 11 (see `vagent/lang/zh/config/default.yaml`)
- Advancement principle: a stage that has not passed cannot be jumped; use tool CurrentTips to get detailed guidance for the current stage; when backfilling is needed use GotoStage to return to a specified stage.
- Three ways to skip / unskip a stage:
  - In project root `config.yaml` under some `stage` list element's `- name` entry set key `skip: true/false` to skip / not skip.
  - At CLI startup use `--skip` / `--unskip someStage` to control skipping / not skipping a stage.
  - After TUI starts use `skip_stage / unskip_stage someStage` to temporarily skip / unskip a stage.

## Overall Flow Overview (11 Stages)

Current flow contains:

1. Requirement Analysis & Verification Planning → 2) {DUT} Function Understanding → 3) Functional Specification Analysis & Test Point Definition → 4) Test Platform Basic Architecture Design → 5) Functional Coverage Model Implementation → 6) Basic API Implementation → 7) Basic API Functional Testing → 8) Test Framework Scaffolding → 9) Comprehensive Verification Execution & Bug Analysis → 10) Code Line Coverage Analysis & Improvement (skipped by default, can be enabled) → 11) Verification Review & Summary

Use the actual workflow as final; the diagram below is for reference only.
![Workflow Diagram](/docs/ucagent/workflow/workflow.png)

Note: in the paths below <OUT> defaults to the output directory name under the working directory (default `unity_test`). For example docs are output to `<workspace>/unity_test/`.

---

Stage 1: Requirement Analysis & Verification Planning

- Goal: understand the task, clarify verification scope and strategy.
- How:
  - Read `{DUT}/README.md`, sort out "which functions / inputs / outputs / boundaries and risks need testing".
  - Form an executable verification plan and goal list.
- Output: `<OUT>/{DUT}_verification_needs_and_plan.md` (written in Chinese).
- Pass criteria: document exists, structure conforms (auto check markdown_file_check).
- Checker:
  - UnityChipCheckerMarkdownFileFormat
    - Role: verify Markdown file existence and format; forbids writing newline as literal "\n".
    - Parameters:
      - markdown_file_list (str | List[str]): path or list of MD files to check. Example: `{OUT}/{DUT}_verification_needs_and_plan.md`
      - no_line_break (bool): whether to forbid newline written as literal "\n"; true forbids.

Stage 2: {DUT} Function Understanding

- Goal: grasp DUT interfaces and basic info; clarify if combinational or sequential circuit.
- How:
  - Read `{DUT}/README.md` and `{DUT}/__init__.py`.
  - Analyze IO ports, clock/reset needs and function scope.
- Output: `<OUT>/{DUT}_basic_info.md`.
- Pass criteria: document exists, format conforms (markdown_file_check).
- Checker: UnityChipCheckerMarkdownFileFormat (same parameter meanings).

Stage 3: Functional Specification Analysis & Test Point Definition (with sub‑stages FG/FC/CK)

- Goal: structure Function Groups (FG), Function Points (FC) and Check Points (CK) as basis for subsequent automation.
- How:
  - Read `{DUT}/*.md` and produced docs, build FG/FC/CK structure of `{DUT}_functions_and_checks.md`.
  - Normalize labels: <FG-groupName>, <FC-functionName>, <CK-checkName>; each function point must have at least 1 check point.
- Sub‑stages:
  - 3.1 Functional grouping & hierarchy (FG): checker UnityChipCheckerLabelStructure(FG)
  - 3.2 Function point definition (FC): checker UnityChipCheckerLabelStructure(FC)
  - 3.3 Check point design (CK): checker UnityChipCheckerLabelStructure(CK)
- Output: `<OUT>/{DUT}_functions_and_checks.md`.
- Pass criteria: all three label structures pass corresponding checks.
- Corresponding checkers (default configuration):
  - 3.1 UnityChipCheckerLabelStructure
    - Role: parse label structure in `{DUT}_functions_and_checks.md` and validate hierarchy & counts (FG).
    - Parameters:
      - doc_file (str): path to function/check doc. Example: `{OUT}/{DUT}_functions_and_checks.md`
      - leaf_node ("FG" | "FC" | "CK"): leaf type to validate. Example: `"FG"`
      - min_count (int, default 1): minimum count threshold.
      - must_have_prefix (str, default "FG-API"): required prefix for FG names for normalized grouping.
  - 3.2 UnityChipCheckerLabelStructure (FC)
    - Role: parse document and validate function point definitions.
    - Same parameters; leaf_node `"FC"`.
  - 3.3 UnityChipCheckerLabelStructure (CK)
    - Role: parse document and validate check point design (CK) and cache CK list for subsequent batch implementation.
    - Extra parameter: data_key (str) e.g. `"COVER_GROUP_DOC_CK_LIST"` for caching CK list.

Stage 4: Test Platform Basic Architecture Design (fixture / API framework)

- Goal: provide unified DUT creation and test lifecycle management capability.
- How:
  - In `<OUT>/tests/{DUT}_api.py` implement `create_dut()`; for sequential circuit configure clock (InitClock); combinational circuits need no clock.
  - Implement pytest fixture `dut` for init/cleanup and optional waveform / line coverage switches.
- Output: `<OUT>/tests/{DUT}_api.py` (with comments & docstrings).
- Pass criteria: DUT creation and fixture checks pass (UnityChipCheckerDutCreation / UnityChipCheckerDutFixture / UnityChipCheckerEnvFixture).
- Sub‑stage checkers:
  - UnityChipCheckerDutCreation: validate `create_dut(request)` signature, clock/reset, coverage path.
  - UnityChipCheckerDutFixture: validate lifecycle management, yield/cleanup, coverage collection call presence.
  - UnityChipCheckerEnvFixture: validate existence/count of `env*` fixtures and (optionally) Bundle encapsulation (`min_env` default 1).

Coverage path specification (important):

- In `create_dut(request)` you must obtain a new line coverage file path via `get_coverage_data_path(request, new_path=True)` and pass into `dut.SetCoverage(...)`.
- In cleanup phase of fixture `dut` you must obtain existing path via `get_coverage_data_path(request, new_path=False)` and call `set_line_coverage(request, <path>, ignore=...)` to write statistics.
- If such calls are missing the checker will error directly and give fix tips (including `tips_of_get_coverage_data_path` example).

Stage 5: Functional Coverage Model Implementation

- Goal: turn FG/FC/CK into countable coverage structures supporting progress measurement & regression.
- How:
  - In `<OUT>/tests/{DUT}_function_coverage_def.py` implement `get_coverage_groups(dut)`.
  - Build a CovGroup for each FG; for FC/CK build watch_point and check function (prefer lambda, else normal function).
- Sub‑stages:
  - 5.1 Coverage group creation (FG)
  - 5.2 Coverage point & check implementation (FC/CK), supporting "batch implementation" tips (COMPLETED_POINTS/TOTAL_POINTS).
- Output: `<OUT>/tests/{DUT}_function_coverage_def.py`.
- Pass criteria: coverage group checks (FG/FC/CK) and batch implementation check pass.
- Sub‑stage checkers:
  - 5.1 UnityChipCheckerCoverageGroup: compare coverage group definitions to doc FG consistency.
  - 5.2 UnityChipCheckerCoverageGroup: compare coverage point / check point implementation to doc FC/CK consistency.
  - 5.2 (batch) UnityChipCheckerCoverageGroupBatchImplementation: batch advance CK implementation & alignment, maintain progress (TOTAL/COMPLETED) with `batch_size` (default 20) and `data_key` `"COVER_GROUP_DOC_CK_LIST"`.

Stage 6: Basic API Implementation

- Goal: provide reusable operation encapsulations with prefix `api_{DUT}_*` hiding low‑level signal details.
- How:
  - In `<OUT>/tests/{DUT}_api.py` implement at least 1 basic API; recommend differentiating "low‑level functional API" and "task functional API".
  - Add detailed docstring: function, parameters, return, exceptions.
- Output: `<OUT>/tests/{DUT}_api.py`.
- Pass criteria: UnityChipCheckerDutApi passes (prefix must be `api_{DUT}_`).
- Checker UnityChipCheckerDutApi: scans/validates count, naming, signature and docstring completeness of `api_{DUT}_*` functions (`min_apis` default 1).

Stage 7: Basic API Functional Correctness Testing

- Goal: write at least 1 basic functional test case per implemented API and mark coverage.
- How:
  - Create `<OUT>/tests/test_{DUT}_api_*.py`; import `from {DUT}_api import *`.
  - First line of each test function: `dut.fc_cover['FG-API'].mark_function('FC-API-NAME', test_func, ['CK-XXX'])`.
  - Design typical / boundary / exceptional data; assert expected output.
  - Use tool RunTestCases for execution & regression.
- Output: `<OUT>/tests/test_{DUT}_api_*.py` and defect records if bugs found.
- Pass criteria: UnityChipCheckerDutApiTest passes (coverage, case quality, documentation record complete).

Stage 8: Test Framework Scaffolding Build

- Goal: bulk generate "placeholder" test templates for not‑yet‑implemented function points ensuring full coverage map.
- How:
  - Based on `{DUT}_functions_and_checks.md` create `test_*.py` under `<OUT>/tests/` with semantic file & case naming.
  - First line mark coverage; add TODO comment describing what to test; end with `assert False, 'Not implemented'` to prevent false pass.
- Output: batch test templates; coverage progress indicators (COVERED_CKS/TOTAL_CKS).
- Pass criteria: UnityChipCheckerTestTemplate passes (structure / marking / explanation complete).

Stage 9: Comprehensive Verification Execution & Bug Analysis

- Goal: turn templates into real tests, systematically discover and analyze DUT bugs.
- How:
  - Fill logic in `test_*.py`, prefer API calls not direct signal manipulation.
  - Design sufficient data and assertions; run RunTestCases; for Fail perform source‑based defect localization and record.
- Sub‑stage:
  - 9.1 Batch test case implementation & corresponding defect analysis (COMPLETED_CASES/TOTAL_CASES).
- Output: systematic test set and `/{DUT}_bug_analysis.md`.
- Pass criteria: UnityChipCheckerTestCase passes (quality / coverage / bug analysis).
- Parent checker UnityChipCheckerTestCase; sub‑stage batch checker UnityChipCheckerBatchTestsImplementation (maintains implementation progress with `batch_size` default 10, `data_key` `"TEST_TEMPLATE_IMP_REPORT"`).

TC bug labeling norms & consistency (strongly associated with docs/report):

- Term: uniformly use "TC bug" (no longer use "CK bug").
- Label structure: `<FG-*>/<FC-*>/<CK-*>/<BG-NAME-XX>/<TC-test_file.py::[ClassName]::test_case>`; BG confidence XX integer 0–100.
- Failed case vs documentation relationship:
  - <TC-\*> appearing in documentation must one‑to‑one match failed test cases in report (file/class/test names).
  - Failed test cases must mark their associated check point (CK) else judged "unmarked".
  - Failed cases not recorded in bug doc will be warned as "undocumented failed test".

Stage 10: Code Line Coverage Analysis & Improvement (default skipped, can enable)

- Goal: review uncovered code lines, add targeted supplements.
- How: run Check to get line coverage; if below threshold, add tests targeting uncovered lines and regress; loop until threshold reached.
- Output: line coverage report and supplemental tests.
- Pass criteria: UnityChipCheckerTestCaseWithLineCoverage meets threshold (default 0.9 adjustable in config).
- Note: stage marked `skip=true` in config; enable via `--unskip` specifying index.

Stage 11: Verification Review & Summary

- Goal: precipitate results, review process, provide improvement suggestions.
- How:
  - Improve defect entries in `/{DUT}_bug_analysis.md` (source‑based analysis).
  - Summarize and write `/{DUT}_test_summary.md`, re‑examine whether plan achieved; use GotoStage for backfill when necessary.
- Output: `<OUT>/{DUT}_test_summary.md` and final conclusion.
- Pass criteria: UnityChipCheckerTestCase re‑check passes.

Tips & Best Practices

- Use tools anytime: Detail / Status to view Mission progress & current stage; CurrentTips for step‑level guidance; Check / Complete to advance stage.
- Left Mission panel in TUI shows stage index, skip status and failure count; can combine CLI `--skip/--unskip/--force-stage-index` for control.

## Customizing Workflow (add / remove stages / sub‑stages)

### Principle Explanation

- Workflow is defined in language config `vagent/lang/zh/config/default.yaml` top‑level `stage:` list.
- Config load order: `setting.yaml` → `~/.ucagent/setting.yaml` → language default (including stage) → project root `config.yaml` → CLI `--override`.
- Note: list types (such as stage list) merge as "whole overwrite" not element‑level. Therefore to add / remove / modify stages, copy the default stage list into your project `config.yaml` and edit on that basis.
- Temporarily not executing a stage: prefer CLI `--skip <index>` or tool Skip/Goto during run; for persistent skipping write `skip: true` on that stage entry in your `config.yaml` (must still provide full stage list).

### Add a Stage

- Need: after "comprehensive verification execution" add a "static check & Lint report" stage requiring generation of `<OUT>/{DUT}_lint_report.md` and format check.
- Method: in project root `config.yaml` provide full `stage:` list and insert entry at suitable position (fragment example only shows new item; actual needs your full list):

```yaml
stage:
  # ...previous existing stages...
  - name: static_lint_and_style_check
    desc: "静态分析与代码风格检查报告"
    task:
      - "目标：完成 DUT 的静态检查/Lint，并输出报告"
      - "第1步：运行 lint 工具（按项目需要）"
      - "第2步：将结论整理为 <OUT>/{DUT}_lint_report.md（中文）"
      - "第3步：用 Check 校验报告是否存在且格式规范"
    checker:
      - name: markdown_file_check
        clss: "UnityChipCheckerMarkdownFileFormat"
        args:
          markdown_file_list: "{OUT}/{DUT}_lint_report.md" # MD 文件路径或列表
          no_line_break: true # 禁止字面量 "\n" 作为换行
    reference_files: []
    output_files:
      - "{OUT}/{DUT}_lint_report.md"
    skip: false
  # ...subsequent existing stages...
```

### Remove a Sub‑Stage

- Scenario: in "functional specification analysis & test point definition" temporarily not executing "function point definition (FC)" sub‑stage.
- Recommended approach: at runtime use CLI `--skip` to skip index; if long‑term config needed copy default `stage:` list to your `config.yaml` then in parent stage `functional_specification_analysis` remove corresponding sub‑stage entry from its `stage:` child list, or add `skip: true` to that sub‑stage.

Sub‑stage removal (fragment example only shows parent stage structure & its sub‑stage list):

```yaml
stage:
  - name: functional_specification_analysis
    desc: "功能规格分析与测试点定义"
    task:
      - "目标：将芯片功能拆解成可测试的小块，为后续测试做准备"
      # ...省略父阶段任务...
    stage:
      - name: functional_grouping # 保留 FG 子阶段
        # ...原有配置...
      # - name: function_point_definition  # 原来的 FC 子阶段（此行及其内容整体删除，或在其中加 skip: true）
      - name: check_point_design # 保留 CK 子阶段
        # ...原有配置...
    # ...其他字段...
```

Tips

- Only temporary skip needed: use `--skip` / `--unskip` fastest; no config file edit.
- Need permanent add/remove: copy default `stage:` list to project `config.yaml`, edit then commit; note list is whole overwrite—do not paste only fragment of added / removed items.
- New stage's checkers can reuse existing classes (Markdown / Fixture / API / Coverage / TestCase etc.) or extend custom checkers (put under `vagent/checkers/` and fill import path in `clss`).

## Customizing Checkers (checker)

Principle Explanation

- Each (sub) stage has a `checker:` list; when executing `Check` all checkers in that list are run sequentially.
- Config fields:
  - `name`: identifier of the checker inside the stage (readability / logs)
  - `clss`: checker class name; short name imported from `vagent.checkers` namespace; can also write full module path (e.g. `mypkg.mychk.MyChecker`)
  - `args`: parameters passed to checker constructor; supports template variables (e.g. `{OUT}`, `{DUT}`)
  - `extra_args`: optional; some checkers support custom tips / strategy (e.g. `fail_msg`, `batch_size`, `pre_report_file` etc.)
- Parsing & instantiation: `vagent/stage/vstage.py` reads `checker:` and generates instances per `clss/args`; at runtime `ToolStdCheck/Check` calls `do_check()`.
- Merge semantics: when merging config lists are "whole replacement"; to modify `checker:` of a stage in project `config.yaml`, copy that stage entry and replace its entire `checker:` list.

### Add a Checker

In parent stage "functional specification analysis & test point definition" add a "document format check" ensuring `{OUT}/{DUT}_functions_and_checks.md` does not write newline as literal `\n`.

```yaml
# Fragment example: needs placement into your full stage list corresponding stage
- name: functional_specification_analysis
  desc: "功能规格分析与测试点定义"
  # ...existing fields...
  output_files:
    - "{OUT}/{DUT}_functions_and_checks.md"
  checker:
    - name: functions_and_checks_doc_format
      clss: "UnityChipCheckerMarkdownFileFormat"
      args:
        markdown_file_list: "{OUT}/{DUT}_functions_and_checks.md" # 功能/检查点文档
        no_line_break: true # 禁止字面量 "\n"
  stage:
    # ...子阶段 FG/FC/CK 原有配置...
```

(Extensible) Custom checker (minimal implementation, place in `vagent/checkers/unity_test.py`)

In many scenarios the "added checker" is not reusing an existing checker but needs a new one. Minimal implementation steps:

1. Create a new class inheriting base `vagent.checkers.base.Checker`
2. In `__init__` declare needed parameters (matching YAML args)
3. Implement `do_check(self, timeout=0, **kw) -> tuple[bool, object]` returning (pass?, structured message)
4. For reading/writing workspace files use `self.get_path(rel)` to get absolute path; for cross‑stage shared data use `self.smanager_set_value / get_value`
5. If you want short name reference in `clss`, export the class in `vagent/checkers/__init__.py` (or write full module path in `clss`)

Minimal code skeleton (example):

```python
# File: vagent/checkers/unity_test.py
from typing import Tuple
import os
from vagent.checkers.base import Checker

class UnityChipCheckerMyCustomCheck(Checker):
    def __init__(self, target_file: str, threshold: int = 1, **kw):
        self.target_file = target_file
        self.threshold = threshold

    def do_check(self, timeout=0, **kw) -> Tuple[bool, object]:
        """Check whether target_file exists and perform simple rule validation."""
        real = self.get_path(self.target_file)
        if not os.path.exists(real):
            return False, {"error": f"file '{self.target_file}' not found"}
        # TODO: write your specific validation logic here (count / parse / compare etc.)
        return True, {"message": "MyCustomCheck passed"}
```

Reference in stage YAML (same as adding a checker):

```yaml
checker:
  - name: my_custom_check
    clss: "UnityChipCheckerMyCustomCheck" # If not exported in __init__.py write full path mypkg.mychk.UnityChipCheckerMyCustomCheck
    args:
      target_file: "{OUT}/{DUT}_something.py"
      threshold: 2
    extra_args:
      fail_msg: "未满足自定义阈值，请完善实现或调低阈值。" # Optional: customize default failure tip via extra_args
```

Advanced tips (as needed):

- Long task / external process: when running subprocess call `self.set_check_process(p, timeout)` so tools `KillCheck / StdCheck` can manage & view output.
- Template rendering: implement `get_template_data()` to render progress / stats into stage title and task text.
- Initialization hook: implement `on_init()` to load cache / prepare batch tasks (same as Batch series checkers).

### Delete a Checker

If temporarily not using "Stage 2 basic info document format check", set that stage's `checker:` empty or remove that item:

```yaml
- name: dut_function_understanding
  desc: "{DUT}功能理解"
  # ...existing fields...
  checker: [] # Remove original markdown_file_check
```

### Modify a Checker

Change line coverage check threshold from 0.9 to 0.8 and customize failure message:

```yaml
- name: line_coverage_analysis_and_improvement
  desc: "代码行覆盖率分析与提升{COVERAGE_COMPLETE}"
  # ...existing fields...
  checker:
    - name: line_coverage_check
      clss: "UnityChipCheckerTestCaseWithLineCoverage"
      args:
        doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
        doc_bug_analysis: "{OUT}/{DUT}_bug_analysis.md"
        test_dir: "{OUT}/tests"
        min_line_coverage: 0.8 # Lower threshold
      extra_args:
        fail_msg: "未达到 80% 的行覆盖率，请补充针对未覆盖行的测试。"
```

Optional: custom checker class

- Add new class under `vagent/checkers/`, inherit `vagent.checkers.base.Checker` and implement `do_check()`.
- After exporting in `vagent/checkers/__init__.py` you can use short name in `clss`; or directly write full module path.
- Strings in `args` support template variable rendering; `extra_args` can customize failure message (depends on checker implementation).

### Common Checker Parameters (Structured)

Below parameters all come from actual code implementation (`vagent/checkers/unity_test.py`); names, defaults and types align with code. Example fragments can be placed directly in phase YAML `checker[].args`.

#### UnityChipCheckerMarkdownFileFormat

- Parameters:
  - markdown_file_list (str | List[str]): Markdown file path or list to check.
  - no_line_break (bool, default false): whether to forbid newline written as literal "\n".
- Example:

```yaml
args:
  markdown_file_list: "{OUT}/{DUT}_basic_info.md"
  no_line_break: true
```

#### UnityChipCheckerLabelStructure

- Parameters:
  - doc_file (str)
  - leaf_node ("FG"|"FC"|"CK")
  - min_count (int, default 1)
  - must_have_prefix (str, default "FG-API")
  - data_key (str, optional)
- Example:

```yaml
args:
  doc_file: "{OUT}/{DUT}_functions_and_checks.md"
  leaf_node: "CK"
  data_key: "COVER_GROUP_DOC_CK_LIST"
```

#### UnityChipCheckerDutCreation

```yaml
args:
  target_file: "{OUT}/tests/{DUT}_api.py"
```

#### UnityChipCheckerDutFixture

```yaml
args:
  target_file: "{OUT}/tests/{DUT}_api.py"
```

#### UnityChipCheckerEnvFixture

```yaml
args:
  target_file: "{OUT}/tests/{DUT}_api.py"
  min_env: 1
```

#### UnityChipCheckerDutApi

```yaml
args:
  api_prefix: "api_{DUT}_"
  target_file: "{OUT}/tests/{DUT}_api.py"
  min_apis: 1
```

#### UnityChipCheckerCoverageGroup

```yaml
args:
  test_dir: "{OUT}/tests"
  cov_file: "{OUT}/tests/{DUT}_function_coverage_def.py"
  doc_file: "{OUT}/{DUT}_functions_and_checks.md"
  check_types: ["FG", "FC", "CK"]
```

#### UnityChipCheckerCoverageGroupBatchImplementation

```yaml
args:
  test_dir: "{OUT}/tests"
  cov_file: "{OUT}/tests/{DUT}_function_coverage_def.py"
  doc_file: "{OUT}/{DUT}_functions_and_checks.md"
  batch_size: 20
  data_key: "COVER_GROUP_DOC_CK_LIST"
```

#### UnityChipCheckerTestTemplate

```yaml
args:
  doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
  test_dir: "{OUT}/tests"
  ignore_ck_prefix: "test_api_{DUT}_"
  data_key: "TEST_TEMPLATE_IMP_REPORT"
  batch_size: 20
```

#### UnityChipCheckerDutApiTest

```yaml
args:
  api_prefix: "api_{DUT}_"
  target_file_api: "{OUT}/tests/{DUT}_api.py"
  target_file_tests: "{OUT}/tests/test_{DUT}_api*.py"
  doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
  doc_bug_analysis: "{OUT}/{DUT}_bug_analysis.md"
```

#### UnityChipCheckerBatchTestsImplementation

```yaml
args:
  doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
  doc_bug_analysis: "{OUT}/{DUT}_bug_analysis.md"
  test_dir: "{OUT}/tests"
  ignore_ck_prefix: "test_api_{DUT}_"
  batch_size: 10
  data_key: "TEST_TEMPLATE_IMP_REPORT"
  pre_report_file: "{OUT}/{DUT}/.TEST_TEMPLATE_IMP_REPORT.json"
```

#### UnityChipCheckerTestCase

```yaml
args:
  doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
  doc_bug_analysis: "{OUT}/{DUT}_bug_analysis.md"
  test_dir: "{OUT}/tests"
```

#### UnityChipCheckerTestCaseWithLineCoverage

```yaml
args:
  doc_func_check: "{OUT}/{DUT}_functions_and_checks.md"
  doc_bug_analysis: "{OUT}/{DUT}_bug_analysis.md"
  test_dir: "{OUT}/tests"
  cfg: "<CONFIG_OBJECT_OR_DICT>"
  min_line_coverage: 0.9
```

Hint: above "Example" fragments only show `args` snippet; actually they need to be placed under a phase entry `checker[].args`.
