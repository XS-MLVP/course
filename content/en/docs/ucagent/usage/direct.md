---
title: Direct Mode
description: Direct usage, options, TUI interface, and FAQ.
categories: [Tutorial]
tags: [docs]
weight: 2
---

## Direct Usage

Based on local CLI and LLM. Requires an OpenAI‑compatible API and an embedding model API.

### Configure via Environment Variables (Recommended)

Config file content:

```yaml
# OpenAI-compatible API config
openai:
  model_name: "$(OPENAI_MODEL: Qwen/Qwen3-Coder-30B-A3B-Instruct)" # model name
  openai_api_key: "$(OPENAI_API_KEY: YOUR_API_KEY)" # API key
  openai_api_base: "$(OPENAI_API_BASE: http://10.156.154.242:8000/v1)" # API base URL
# Embedding model config
# Used for doc search and memory features; can be disabled via --no-embed-tools
embed:
  model_name: "$(EMBED_MODEL: Qwen/Qwen3-Embedding-0.6B)" # embedding model name
  openai_api_key: "$(EMBED_OPENAI_API_KEY: YOUR_API_KEY)" # embedding API key
  openai_api_base: "$(EMBED_OPENAI_API_BASE: http://10.156.154.242:8001/v1)" # embedding API URL
  dims: 4096 # embedding dimension
```

UCAgent config supports Bash‑style env placeholders: `$(VAR: default)`. On load, it will be replaced with the current env var `VAR`; if unset, the `default` is used.

- For example, in the built‑in `vagent/setting.yaml`:
  - `openai.model_name: "$(OPENAI_MODEL: <your_chat_model_name>)"`
  - `openai.openai_api_key: "$(OPENAI_API_KEY: [your_api_key])"`
  - `openai.openai_api_base: "$(OPENAI_API_BASE: http://<your_chat_model_url>/v1)"`
  - `embed.model_name: "$(EMBED_MODEL: <your_embedding_model_name>)"`
  - Also supports other providers: `model_type` supports `openai`, `anthropic`, `google_genai` (see `vagent/setting.yaml`).

You can switch models and endpoints just by exporting env vars, without editing the config file.

Example: set chat model and endpoint

```bash
# Specify chat model (OpenAI‑compatible)
export OPENAI_MODEL='Qwen/Qwen3-Coder-30B-A3B-Instruct'

# Specify API Key and Base (fill in according to your provider)
export OPENAI_API_KEY='your_api_key'
export OPENAI_API_BASE='https://your-openai-compatible-endpoint/v1'

# Optional: embedding model (if using retrieval/memory features)
export EMBED_MODEL='text-embedding-3-large'
export EMBED_OPENAI_API_KEY="$OPENAI_API_KEY"
export EMBED_OPENAI_API_BASE="$OPENAI_API_BASE"
```

Then start UCAgent as described earlier. To persist, append the above exports to your default shell startup file (e.g., bash: `~/.bashrc`, zsh: `~/.zshrc`, fish: `~/.config/fish/config.fish`), then reopen terminal or source it manually.

### Configure via config.yaml

- Create and edit `config.yaml` at the project root to configure the AI model and embedding model:

```yaml
# OpenAI-compatible API config
openai:
  openai_api_base: <your_openai_api_base_url> # API base URL
  model_name: <your_model_name> # model name, e.g., gpt-4o-mini
  openai_api_key: <your_openai_api_key> # API key

# Embedding model config
# Used for doc search and memory features; can be disabled via --no-embed-tools
embed:
  model_name: <your_embed_model_name> # embedding model name
  openai_api_base: <your_openai_api_base_url> # embedding API URL
  openai_api_key: <your_api_key> # embedding API key
  dims: <your_embed_model_dims> # embedding dimension, e.g., 1536
```

### Start

- Step 1 is the same as in MCP mode: prepare RTL and the corresponding SPEC docs under `examples/{dut}`. `{dut}` is the module name; if it is `Adder`, the directory is `examples/Adder`.
- Step 2 differs: package RTL, put the docs into the workspace, and start UCAgent TUI: `make test_{dut}`, where `{dut}` is the module. For `Adder`, run `make test_Adder` (see all targets in `Makefile`). This will:
  - Copy files from `examples/{dut}` to `output/{dut}` (.v/.sv/.md/.py, etc.)
  - Run `python3 ucagent.py output/ {dut} --config config.yaml -s -hm --tui -l`
  - Start UCAgent with TUI and automatically enter the loop

Tip: verification artifacts are written to `output/unity_test/` by default; to change it, use the CLI `--output` option to set the directory name.

### Direct CLI (without Makefile):

- Not installed (run inside project):
  - `python3 ucagent.py output/ Adder --config config.yaml -s -hm --tui -l`
- Installed as command:
  - `ucagent output/ Adder --config config.yaml -s -hm --tui -l`

Options aligned with `vagent/cli.py`:

- `workspace`: workspace directory (here `output/`)
- `dut`: DUT name (workspace subdirectory name, e.g., `Adder`)
- Common options:
  - `--tui` start terminal UI
  - `-l/--loop --loop-msg "..."` enter loop immediately after start and inject a hint
  - `-s/--stream-output` stream output
  - `-hm/--human` human‑intervention mode (can pause between stages)
  - `--no-embed-tools` if retrieval/memory tools are not needed
  - `--skip/--unskip` skip/unskip stages (can be passed multiple times)

### TUI Quick Reference (Direct Mode)

- List tools: `tool_list`
- Stage check: `tool_invoke Check timeout=0`
- View logs: `tool_invoke StdCheck lines=-1` (‑1 for all lines)
- Stop check: `tool_invoke KillCheck`
- Finish stage: `tool_invoke Complete timeout=0`
- Run tests:
  - Full: `tool_invoke RunTestCases target='' timeout=0`
  - Single test function: `tool_invoke RunTestCases target='tests/test_checker.py::test_run' timeout=120 return_line_coverage=True`
  - Filter: `tool_invoke RunTestCases target='-k add or mul'`
- Jump stage: `tool_invoke GoToStage index=2` (index starts from 0)
- Continue: `loop 继续修复 ALU754 的未命中分支并重试用例`

Recommended minimal write permission (only allow generation under verification artifacts):

- Allow only `unity_test/` and `unity_test/tests/` to be writable:
  - `add_un_write_path *`
  - `del_un_write_path unity_test`
  - `del_un_write_path unity_test/tests`

### FAQ and Tips

- Check stuck/no output:
  - First run `tool_invoke StdCheck lines=-1` to view all logs; if needed `tool_invoke KillCheck`; fix then retry `tool_invoke Check`.
- Tool name not found:
  - Run `tool_list` to confirm available tools; if missing, check whether in TUI mode and whether embedding tools were disabled (usually unrelated).
- Artifact location:
  - By default under `workspace/output_dir`, i.e., `output/unity_test/` for the examples on this page.

### Related Docs

- Full human‑AI collaboration flow and examples: see [Human‑AI Collaboration](./assit.md)
- MCP integration (e.g., gemini‑cli / qwen code): see [MCP Integration Mode](./mcp.md)
- TUI interface and operations in detail: see [TUI](./tui.md)
