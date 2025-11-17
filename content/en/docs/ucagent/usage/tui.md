---
title: TUI
description: TUI layout and operations.
categories: [Tutorial]
tags: [docs]
weight: 5
---

## TUI (UI & Operations)

UCAgent provides a urwid‑based terminal UI (TUI) for interactively observing task progress, message stream, and console output locally, and for entering commands directly (e.g., enter/exit loop, switch modes, run debug commands, etc.).

### Layout

![TUI Layout](/docs/ucagent/usage/tui/tui-part.png)

- Mission panel (left)

  - Stage list: show current task stages (index, title, failures, elapsed). Color meanings:
    - Green: completed stage
    - Red: current stage
    - Yellow: skipped stage (shows "skipped")
  - Changed Files: recently modified files (with mtime and relative time, e.g., "3m ago"). Newer files are highlighted in green.
  - Tools Call: tool call status and counters. Busy tools are highlighted in yellow (e.g., SqThink(2)).
  - Daemon Commands: demo commands running in background (with start time and elapsed).

- Status panel (top right)

  - Shows API and agent status summary, and current panel size parameters (useful when adjusting layout).

- Messages panel (upper middle right)

  - Live message stream (model replies, tool output, system tips).
  - Supports focus and scrolling; the title shows "current/total" position, e.g., Messages (123/456).

- Console (bottom)
  - Output: command and system output area with paging.
  - Input: command input line (default prompt "(UnityChip) "). Provides history, completion, and busy hints.

Tip: the UI auto‑refreshes every second (does not affect input). When messages or output are long, it enters paging or manual scrolling.

### Shortcuts

- Enter: execute current input; if empty, repeat the last command; q/Q/exit/quit to exit TUI.
- Esc:
  - If browsing Messages history, exit scrolling and return to the end;
  - If Output is in paging view, exit paging;
  - Otherwise focus the bottom input box.
- Tab: command completion; press Tab again to show more candidates in batches.
- Shift+Right: clear Console Output.
- Shift+Up / Shift+Down: move focus up/down in Messages (browse history).
- Ctrl+Up / Ctrl+Down: increase/decrease Console output area height.
- Ctrl+Left / Ctrl+Right: decrease/increase Mission panel width.
- Shift+Up / Shift+Down (another path): adjust Status panel height (min 3, max 100).
- Up / Down:
  - If Output is in paging mode, Up/Down scrolls pages;
  - Otherwise navigate command history (put the command into input line for editing and Enter to run).

Paging mode hint: when Output enters paging, the footer shows "Up/Down: scroll, Esc: exit"; press Esc to exit paging and return to input.

### Commands and Usage

- Normal commands: enter and press Enter, e.g., loop, tui, help (handled by internal debugger).
- History commands: when input is empty, pressing Enter repeats the last command.
- Clear: type clear and press Enter; only clears Output (does not affect message history).
- Demo/background commands: append `&` to run in background; when finished, an end hint appears in Output; use `list_demo_cmds` to see current background commands.
- Directly run system/dangerous commands: prefix with `!` (e.g., `!loop`); after running, it prioritizes scrolling to the latest output.
- List background commands: `list_demo_cmds` shows running demo commands and start times.

#### Message Configuration (message_config)

- Purpose: view/adjust message trimming policy at runtime; control history retention and LLM input token limit.
- Commands:
  - `message_config` to view current config
  - `message_config <key> <value>` to set a config item
- Configurable items:
  - max_keep_msgs: number of historical messages to keep (affects conversation memory window)
  - max_token: token limit for trimming before sending to model (affects cost/truncation)
- Examples:
  - `message_config`
  - `message_config max_keep_msgs 8`
  - `message_config max_token 4096`

Other notes

- Auto‑completion: supports command names and some parameters; if there are many candidates, they are shown in batches; press Tab multiple times to view remaining items.
- Busy hints: while a command is executing, the input box title cycles through (wait.), (wait..), (wait...), indicating processing.
- Message focus: when not manually scrolled, focus follows the latest message automatically; after entering manual scrolling, it stays until Esc or scrolled to the end.
- Error tolerance: if some UI operations fail (e.g., terminal doesn’t support some control sequences), the TUI tries to fall back to a safe state and continue running.
