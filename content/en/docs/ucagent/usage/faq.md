---
title: FAQ
description: Common questions and answers.
categories: [Tutorial]
tags: [docs]
weight: 6
---

## FAQ

- Switch model: set `openai.model_name` in `config.yaml`.
- Errors during verification: press `Ctrl+C` to enter interactive mode; run `status` and `help`.
- Check failed: read `reference_files` via `ReadTextFile`; fix per hints; iterate RunTestCases → Check.
- Custom stages: edit `vagent/lang/zh/config/default.yaml` or use `--override`.
- Add tools: create class under `vagent/tools/`, inherit `UCTool`, and load with `--ex-tools YourTool`.
- MCP connection: check port/firewall; change `--mcp-server-port`; add `--no-embed-tools` if no embedding.
- Read-only protection: limit writes with `--no-write/--nw` (paths must be under workspace).

### Why is there no default config.yaml in Quick Start?

- When installed via pip, there is no repo `config.yaml`, so Quick Start [Start MCP Server](../introduce.md#command) doesn't pass `--config config.yaml`.
- You can add a `config.yaml` in your workspace and start with `--config config.yaml`, or clone the repo to use the built-in configs.

### Adjust message window and token limit?

- In TUI: `message_config` to view; set `message_config max_keep_msgs 8` or `message_config max_token 4096`.
- Scope: affects conversation history trimming and the maximum token limit sent to the LLM (effective via the Summarization/Trim node).

### "CK bug" vs "TC bug"?

- Use the unified term "TC bug". Ensure `<TC-*>` in the bug doc maps to failing tests.

### Where is WriteTextFile?

- Removed. Use `EditTextFile` (overwrite/append/replace) or other file tools.
