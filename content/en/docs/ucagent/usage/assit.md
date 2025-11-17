---
title: Human-AI Collaborative Verification
description: How to collaborate with AI to verify a module.
categories: [Tutorial]
tags: [docs]
weight: 3
---

UCAgent supports human‑AI collaborative verification. You can pause AI execution, intervene manually, then continue AI execution. This mode applies to scenarios needing fine control or complex decisions.

**Collaboration Flow:**

1. Pause AI execution:
   - Direct LLM access mode: press `Ctrl+C` to pause.
   - Code Agent collaboration mode: pause according to the agent’s method (e.g. Gemini-cli uses `Esc`).
2. Human intervention:
   - Manually edit files, test cases or configuration.
   - Use interactive commands for debugging or adjustment.
3. Stage control:
   - Use `tool_invoke Check` to check current stage status.
   - Use `tool_invoke Complete` to mark stage complete and enter next stage.
4. Continue execution:
   - Use `loop [prompt]` to continue AI execution and optionally provide extra prompt info.
   - In Code Agent mode, input prompts via the agent console.
5. Permission management:
   - Use `add_un_write_path`, `del_un_write_path` to set file write permissions, controlling whether AI can edit specific files.
   - Applies to direct LLM access or forced use of UCAgent file tools.
