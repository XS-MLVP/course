---
title: Customize
description: How to define parameters, workflow and tools.
categories: [Tutorial]
tags: [docs]
weight: 4
---

## Add Tools and MCP Server Tools

For advanced users who can modify this repository code, the following explains how to:

- Add a new tool (for local / in‑agent invocation)
- Expose the tool as an MCP Server tool (for external IDE / client invocation)
- Control which tools are exposed and how they are invoked

Key locations involved:

- `vagent/tools/uctool.py`: tool base class UCTool, `to_fastmcp` (LangChain Tool → FastMCP Tool)
- `vagent/util/functions.py`: `import_and_instance_tools` (import & instantiate by name), `create_verify_mcps` (start FastMCP)
- `vagent/verify_agent.py`: assemble tool list, `start_mcps` to combine and launch server
- `vagent/cli.py` / `vagent/verify_pdb.py`: CLI and TUI MCP start commands

### 1) Tool System and Assembly

- Tool base class UCTool:
  - Inherits LangChain `BaseTool`; built‑in: `call_count`, `call_time_out`, streaming / blocking tips, MCP Context injection (`ctx.info`), re‑entry prevention, etc.
  - It is recommended to make custom tools inherit UCTool to obtain better MCP behavior and debugging experience.
- Runtime assembly (during VerifyAgent initialization):
  - Basic tools: `RoleInfo`, `ReadTextFile`
  - Embed tools: reference retrieval & memory (unless `--no-embed-tools`)
  - File tools: read / write / search / path etc. (can be removed in MCP no‑file tools mode)
  - Stage tools: dynamically provided by `StageManager` according to workflow
  - External tools: from config item `ex_tools` and CLI `--ex-tools` (instantiated with zero parameters via `import_and_instance_tools`)
- Name resolution:
  - Short name: class / factory function must be exported in `vagent/tools/__init__.py` (e.g. `from .mytool import HelloTool`), then you can write `HelloTool` in `ex_tools`
  - Full path: `mypkg.mytools.HelloTool` / `mypkg.mytools.Factory`

### 2) Add a New Tool (Local / In‑Agent)

Specification requirements:

- Unique `name`, clear `description`
- Use pydantic `BaseModel` to define `args_schema` (MCP conversion depends on it)
- Implement `_run` (sync) or `_arun` (async); inheriting UCTool gives timeout, streaming and ctx injection automatically

Example 1: synchronous tool (counted greeting)

```python
from pydantic import BaseModel, Field
from vagent.tools.uctool import UCTool

class HelloArgs(BaseModel):
    who: str = Field(..., description="Person to greet")

class HelloTool(UCTool):
    name: str = "Hello"
    description: str = "Greet a target and count calls"
    args_schema = HelloArgs

    def _run(self, who: str, run_manager=None) -> str:
        return f"Hello, {who}! (called {self.call_count+1} times)"
```

Register & use:

- Temporary: `--ex-tools mypkg.mytools.HelloTool`
- Persistent: project `config.yaml`

```yaml
ex_tools:
  - mypkg.mytools.HelloTool
```

(Optional) short name registration: export `HelloTool` in `vagent/tools/__init__.py`, then you can write `--ex-tools HelloTool`.

Example 2: asynchronous streaming tool (`ctx.info` + timeout)

```python
from pydantic import BaseModel, Field
from vagent.tools.uctool import UCTool
import asyncio

class ProgressArgs(BaseModel):
    steps: int = Field(5, ge=1, le=20, description="Number of progress steps")

class ProgressTool(UCTool):
    name: str = "Progress"
    description: str = "Demonstrate streaming output and timeout handling"
    args_schema = ProgressArgs

    async def _arun(self, steps: int, run_manager=None):
        for i in range(steps):
            self.put_alive_data(f"step {i+1}/{steps}")  # for blocking prompt / log buffer
            await asyncio.sleep(0.5)
        return "done"
```

Explanation: `UCTool.ainvoke` will inject ctx in MCP mode and start a blocking prompt thread; when `sync_block_log_to_client=True` it periodically pushes logs via `ctx.info`, on timeout returns error plus buffered logs.

### 3) Expose as MCP Server Tools

Tool → MCP conversion (`vagent/tools/uctool.py::to_fastmcp`):

- Required: `args_schema` inherits `BaseModel`; "injected parameter" signatures are not supported.
- UCTool subclasses get FastMCP tools with `context_kwarg="ctx"` and streaming interaction capability.

Server side startup:

- `VerifyAgent.start_mcps` combines tools: `tool_list_base + tool_list_task + tool_list_ext + [tool_list_file]`
- `vagent/util/functions.py::create_verify_mcps` converts tool sequence into FastMCP tools and starts uvicorn (`mcp.streamable_http_app()`).

How to choose exposure scope:

- CLI:
  - Start (with file tools): `--mcp-server`
  - Start (without file tools): `--mcp-server-no-file-tools`
  - Host: `--mcp-server-host`, Port: `--mcp-server-port`
- TUI commands: `start_mcp_server [host] [port]` / `start_mcp_server_no_file_ops [host] [port]`

### 4) Client Call Flow

FastMCP Python client (see `tests/test_mcps.py`):

```python
from fastmcp import Client

client = Client("http://127.0.0.1:5000/mcp", timeout=10)
print(client.list_tools())
print(client.call_tool("Hello", {"who": "UCAgent"}))
```

IDE / Agent (Claude Code, Copilot, Qwen Code, etc.): set `httpUrl` to `http://<host>:<port>/mcp` to discover and call tools.

### 5) Lifecycle, Concurrency and Timeout

- Counting: UCTool has `call_count`; non‑UCTool tools are wrapped with counting by `import_and_instance_tools`.
- Concurrency protection: `is_in_streaming` / `is_alive_loop` prevent re‑entry; the same instance disallows concurrent execution.
- Timeout: `call_time_out` (default 20s) + client timeout; when blocking can use `put_alive_data` + `sync_block_log_to_client=True` to push heartbeat.

### 6) Configuration Strategy and Best Practices

- `ex_tools` list is a "whole overwrite"; project `config.yaml` must write full list.
- Short name vs full path: short name is more convenient; full path applies when private package without modifying this repo.
- No‑arg constructor / factory: assembler directly calls `(...)()`; complex configuration should be handled inside factory (read env / config file).
- File write permission: in MCP no‑file tools mode do not expose write‑type tools; if writing is needed, use inside local agent or explicitly allow write directory.

#### Inject External Tools via Environment Variable (EX_TOOLS)

Configuration files support Bash style environment variable placeholder: `$(VAR: default)`. You can let `ex_tools` inject a list of tool classes from env (supports full module name or short name under `vagent.tools`).

1. In project `config.yaml` or user `~/.ucagent/setting.yaml` write:

```yaml
ex_tools: $(EX_TOOLS: [])
```

2. Provide list via environment variable (must be YAML parsable array literal):

```zsh
export EX_TOOLS='["SqThink","HumanHelp"]'
# Or full class path:
# export EX_TOOLS='["vagent.tools.extool.SqThink","vagent.tools.human.HumanHelp"]'
```

3. After startup these tools appear in local dialog and MCP Server. Short name needs export in `vagent/tools/__init__.py`; otherwise use full module path.

4. Combined with CLI `--ex-tools` option (both sides assembled).

### 7) Common Issue Troubleshooting

- Tool not in MCP list: not assembled (ex_tools not configured / not exported), `args_schema` not BaseModel, server not started as expected.
- Call reports "injected parameter not supported": tool definition includes LangChain injected args; change to explicit args_schema parameters.
- Timeout: increase `call_time_out` or client timeout; in long tasks output progress to maintain heartbeat.
- Short name invalid: not exported in `vagent/tools/__init__.py`; use full path or export it.

After completing the above steps: your tool can be automatically invoked by ReAct locally, and can also be exposed via MCP Server for unified invocation by external IDE / clients.


