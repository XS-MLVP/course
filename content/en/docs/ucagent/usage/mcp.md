---
title: MCP Integration Mode (Recommended)
description: How to use UCAgent via MCP integration mode.
categories: [Tutorial]
tags: [docs]
weight: 1
---

## MCP Integration (Recommended) Integrate Code Agent

Collaborate with external CLI via MCP. This mode works with all LLM clients that support MCP-Server invocation, such as Cherry Studio, Claude Code, Gemini-CLI, VS Code Copilot, Qwen Code, etc. Daily usage is to use `make` directly; for detailed commands see [Quick Start](../introduce.md#quick-start), or check the root `Makefile`.

- Prepare RTL and the corresponding SPEC docs under `examples/{dut}`. `{dut}` is the module name; if it is `Adder`, the directory is `examples/Adder`.
- Package RTL, place docs, and start MCP server: `make mcp_{dut}` (e.g., `make mcp_Adder`).
- Configure your MCP client:

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

- Start the client: for Qwen Code, run `qwen` under `UCAgent/output`, then input the prompt.
- prompt:
  > Please get your role and basic guidance via RoleInfo, then complete the task. Use ReadTextFile to read files. Operate only within the current working directory; do not go outside it.
