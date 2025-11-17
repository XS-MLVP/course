---
title: Options
description: Explanation of CLI arguments and flags.
categories: [Tutorial]
tags: [docs]
weight: 4
---

## Arguments and Options

Use UCAgent:

```bash
ucagent <workspace> <dut_name> {options}
```

### Inputs

- workspace: working directory:
  - workspace/<DUT_DIR>: device under test (DUT), i.e., the Python package <DUT_DIR> exported by the picker; e.g., Adder
  - workspace/<DUT_DIR>/README.md: natural‑language description of verification requirements and goals for this DUT
  - workspace/<DUT_DIR>/\*.md: other reference documents
  - workspace/<DUT_DIR>/\*.v/sv/scala: source files used for bug analysis
  - Other verification‑related files (e.g., provided test cases, requirement specs, etc.)
- dut_name: the name of the DUT, i.e., <DUT_DIR>, for example: Adder

### Outputs

- workspace: working directory:
  - workspace/Guide_Doc: guidance and documents followed during the verification process
  - workspace/uc_test_report: generated Toffee‑test report
  - workspace/unity_test/tests: auto‑generated test cases
  - workspace/\*.md: generated docs including bug analysis, checkpoints, verification plan, and conclusion

See also the detailed outputs in [Introduction](../introduce.md#detailed-output).

### Positional Arguments

| Argument  | Required | Description                             | Example  |
| :-------- | :------: | :-------------------------------------- | :------- |
| workspace |   Yes    | Working directory                       | ./output |
| dut       |   Yes    | DUT name (subdirectory under workspace) | Adder    |

### Execution and Interaction

| Option             | Short | Values/Type                | Default  | Description                                                                                   |
| :----------------- | :---- | :------------------------- | :------- | :-------------------------------------------------------------------------------------------- |
| --stream-output    | -s    | flag                       | off      | Stream output to console                                                                      |
| --human            | -hm   | flag                       | off      | Enter human input/breakpoint mode on start                                                    |
| --interaction-mode | -im   | standard/enhanced/advanced | standard | Interaction mode; enhanced includes planning and memory mgmt, advanced adds adaptive strategy |
| --tui              |       | flag                       | off      | Enable terminal TUI                                                                           |
| --loop             | -l    | flag                       | off      | Enter main loop immediately after start (with --loop-msg); for direct mode                    |
| --loop-msg         |       | str                        | empty    | First message injected when entering loop                                                     |
| --seed             |       | int                        | random   | Random seed (auto random if unspecified)                                                      |
| --sys-tips         |       | str                        | empty    | Override system prompt                                                                        |

### Config and Templates

| Option               | Short | Values/Type                | Default    | Description                                                                                      |
| :------------------- | :---- | :------------------------- | :--------- | :----------------------------------------------------------------------------------------------- |
| --config             |       | path                       | none       | Config file path, e.g., `--config config.yaml`                                                   |
| --template-dir       |       | path                       | none       | Custom template directory                                                                        |
| --template-overwrite |       | flag                       | no         | Allow overwriting existing files when rendering templates into workspace                         |
| --output             |       | dir                        | unity_test | Output directory name                                                                            |
| --override           |       | A.B.C=VALUE[,X.Y=VAL2,...] | none       | Override config with dot‑path assignments; strings need quotes, others parsed as Python literals |
| --gen-instruct-file  | -gif  | file                       | none       | Generate an external Agent guide file under workspace (overwrite if exists)                      |
| --guid-doc-path      |       | path                       | none       | Use a custom Guide_Doc directory (default uses internal copy)                                    |

### Planning and ToDo

| Option           | Short | Values/Type | Default | Description                                                            |
| :--------------- | :---- | :---------- | :------ | :--------------------------------------------------------------------- |
| --force-todo     | -fp   | flag        | no      | Enable ToDo tools in standard mode and include ToDo info in each round |
| --use-todo-tools | -utt  | flag        | no      | Enable ToDo‑related tools (not limited to standard mode)               |

### ToDo Tools Overview & Examples

Note: ToDo tools are for enhancing model planning; users can define the model’s ToDo list. This feature requires strong model capability and is disabled by default.

Enabling: use `--use-todo-tools` in any mode; or in standard mode use `--force-todo` to force enable and include ToDo info in each round.

Conventions and limits: step indices are 1‑based; number of steps must be 2–20; length of notes and each step text ≤ 100; exceeding limits will be rejected with an error string.

Tool overview

| Class             | Call Name         | Main Function                      | Parameters                                   | Return                    | Key Constraints/Behavior                                                     |
| :---------------- | :---------------- | :--------------------------------- | :------------------------------------------- | :------------------------ | :--------------------------------------------------------------------------- |
| CreateToDo        | CreateToDo        | Create current ToDo (overwrite)    | task_description: str; steps: List[str]      | Success msg + summary     | Validate step count/length; write then return summary                        |
| CompleteToDoSteps | CompleteToDoSteps | Mark steps as completed, with note | completed_steps: List[int]=[]; notes: str="" | Success (count) + summary | Only affects incomplete steps; prompt to create if none; ignore out‑of‑range |
| UndoToDoSteps     | UndoToDoSteps     | Undo completion status, with note  | steps: List[int]=[]; notes: str=""           | Success (count) + summary | Only affects completed steps; prompt to create if none; ignore out‑of‑range  |
| ResetToDo         | ResetToDo         | Reset/clear current ToDo           | none                                         | Reset success msg         | Clear steps and notes; can recreate afterwards                               |
| GetToDoSummary    | GetToDoSummary    | Get current ToDo summary           | none                                         | Summary / no‑ToDo prompt  | Read‑only, no state change                                                   |
| ToDoState         | ToDoState         | Get status phrase (kanban/status)  | none                                         | Status description        | Dynamic display: no ToDo/completed/progress stats, etc.                      |

Invocation examples (MCP/internal tool call, JSON args):

```json
{
	"tool": "CreateToDo",
	"args": {
		"task_description": "Complete verification closure for Adder core functions",
		"steps": [
			"Read README and spec, summarize features",
			"Define checkpoints and pass criteria",
			"Generate initial unit tests",
			"Run and fix failing tests",
			"Fill coverage and output report"
		]
	}
}
```

```json
{
	"tool": "CompleteToDoSteps",
	"args": { "completed_steps": [1, 2], "notes": "Initial issues resolved, ready to add tests" }
}
```

```json
{ "tool": "UndoToDoSteps", "args": { "steps": [2], "notes": "Step 2 needs checkpoint tweaks" } }
```

```json
{ "tool": "ResetToDo", "args": {} }
```

```json
{ "tool": "GetToDoSummary", "args": {} }
```

```json
{ "tool": "ToDoState", "args": {} }
```

### External and Embedding Tools

| Option           | Short | Values/Type      | Default | Description                                               |
| :--------------- | :---- | :--------------- | :------ | :-------------------------------------------------------- |
| --ex-tools       |       | name1[,name2...] | none    | Comma‑separated external tool class names (e.g., SqThink) |
| --no-embed-tools |       | flag             | no      | Disable built‑in retrieval/memory embedding tools         |

### Logging

| Option     | Short | Values/Type | Default | Description                                   |
| :--------- | :---- | :---------- | :------ | :-------------------------------------------- |
| --log      |       | flag        | no      | Enable logging                                |
| --log-file |       | path        | auto    | Log output file (use default if unspecified)  |
| --msg-file |       | path        | auto    | Message log file (use default if unspecified) |

### MCP Server

| Option                     | Short | Values/Type | Default   | Description                           |
| :------------------------- | :---- | :---------- | :-------- | :------------------------------------ |
| --mcp-server               |       | flag        | no        | Start MCP server (with file tools)    |
| --mcp-server-no-file-tools |       | flag        | no        | Start MCP server (without file tools) |
| --mcp-server-host          |       | host        | 127.0.0.1 | Server listen address                 |
| --mcp-server-port          |       | int         | 5000      | Server port                           |

### Stage Control and Safety

| Option              | Short | Values/Type      | Default | Description                                                  |
| :------------------ | :---- | :--------------- | :------ | :----------------------------------------------------------- |
| --force-stage-index |       | int              | 0       | Force start from specified stage index                       |
| --skip              |       | int (repeatable) | []      | Skip specified stage index; can be provided multiple times   |
| --unskip            |       | int (repeatable) | []      | Unskip specified stage index; can be provided multiple times |
| --no-write / --nw   |       | path1 path2 ...  | none    | Restrict writable targets; must exist within workspace       |

### Version and Check

| Option    | Short | Values/Type | Default | Description                                                                |
| :-------- | :---- | :---------- | :------ | :------------------------------------------------------------------------- |
| --check   |       | flag        | no      | Check default config, lang directories, templates, and Guide_Doc then exit |
| --version |       | flag        |         | Print version and exit                                                     |

### Example

```bash
python3 ucagent.py ./output Adder \
	\
	-s \
	-hm \
	-im enhanced \
	--tui \
	-l \
	--loop-msg 'start verification' \
	--seed 12345 \
	--sys-tips '按规范完成Adder的验证' \
	\
	--config config.yaml \
	--template-dir ./templates \
	--template-overwrite \
	--output unity_test \
	--override 'conversation_summary.max_tokens=16384,conversation_summary.max_summary_tokens=2048,conversation_summary.use_uc_mode=True,lang="zh",openai.model_name="gpt-4o-mini"' \
	--gen-instruct-file GEMINI.md \
	--guid-doc-path ./output/Guide_Doc \
	\
	--use-todo-tools \
	\
	--ex-tools 'SqThink,AnotherTool' \
	--no-embed-tools \
	\
	--log \
	--log-file ./output/ucagent.log \
	--msg-file ./output/ucagent.msg \
	\
	--mcp-server-no-file-tools \
	--mcp-server-host 127.0.0.1 \
	--mcp-server-port 5000 \
	\
	--force-stage-index 2 \
	--skip 5 --skip 7 \
	--unskip 6 \
	--nw ./output/Adder ./output/unity_test

```

- Positional arguments
  - ./output: workspace working directory
  - Adder: dut subdirectory name
- Execution and interaction
  - -s: stream output
  - -hm: human intervention on start
  - -im enhanced: enhanced interaction mode (with planning and memory)
  - --tui: enable TUI
  - -l: enter loop immediately after start
  - --loop/--loop-msg: inject first message when entering loop
  - --seed 12345: fix random seed
  - --sys-tips: custom system prompt
- Config and templates
  - --config config.yaml: load project config from `config.yaml`
  - --template-dir ./templates: set template directory to `./templates`
  - --template-overwrite: allow overwrite when rendering templates
  - --output unity_test: output directory name `unity_test`
  - --override '...': override config keys (dot‑path=value, multiple comma‑separated; string values require inner quotes and wrap the whole with single quotes); the example sets conversation summary limits, enables trimming, sets doc language to Chinese, and model name to gpt‑4o‑mini
  - -gif/--gen-instruct-file GEMINI.md: generate external collaboration guide at `<workspace>/GEMINI.md`
  - --guid-doc-path ./output/Guide_Doc: customize Guide_Doc directory as `./output/Guide_Doc`
- Planning and ToDo
  - --use-todo-tools: enable ToDo tools and force attaching ToDo info
- External and embedding tools
  - --ex-tools 'SqThink,AnotherTool': enable external tools `SqThink,AnotherTool`
  - --no-embed-tools: disable built‑in retrieval/memory tools
- Logging
  - --log: enable log file
  - --log-file ./output/ucagent.log: set log output file to `./output/ucagent.log`
  - --msg-file ./output/ucagent.msg: set message log file to `./output/ucagent.msg`
- MCP Server
  - --mcp-server-no-file-tools: start MCP (without file tools)
  - --mcp-server-host: server listen address `127.0.0.1`
  - --mcp-server-port: server listen port `5000`
- Stage control and safety
  - --force-stage-index 2: start from stage index 2
  - --skip 5 --skip 7: skip stage 5 and stage 7
  - --unskip 7: unskip stage 7
  - --nw ./output/Adder ./output/unity_test: restrict writable paths to `./output/Adder` and `./output/unity_test`
- Notes
  - --check and --version exit immediately, not combined with run
  - --mcp-server and --mcp-server-no-file-tools are mutually exclusive; here we choose the latter. Path arguments (e.g., --template-dir/--guid-doc-path/--nw) must exist, otherwise an error occurs
  - String values in --override must be quoted, and wrap the whole argument in single quotes to prevent the shell from consuming the inner quotes (the example already does this)
