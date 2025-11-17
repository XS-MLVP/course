---
title: Tool List
description: UCAgent built-in tool catalog (by category).
categories: [Reference]
tags: [docs]
weight: 6
---

Below is an overview of the built‑in tools (UCTool family) in this repository, grouped by function: name (call name), purpose, and parameter description (field: type — meaning).

Tips:

- Tools with "file write" capability are only available locally/in allowed‑write mode; in MCP no‑file‑tools mode, write‑type tools are not exposed.
- All tools validate parameters via `args_schema`; MCP clients will render parameter forms from the schema.

## Basics / Info

- RoleInfo (RoleInfo)

  - Purpose: return the current agent’s role information (can customize `role_info` at startup).
  - Parameters: none

- HumanHelp (HumanHelp)
  - Purpose: ask a human for help (use only when truly stuck).
  - Parameters:
    - message: str — help message

## Planning / ToDo

- CreateToDo
  - Purpose: create a ToDo (overwrites any existing ToDo).
  - Parameters:
    - task_description: str — task description
    - steps: List[str] — steps (1–20 steps)
- CompleteToDoSteps
  - Purpose: mark specified steps as completed, with optional notes.
  - Parameters:
    - completed_steps: List[int] — step indices to mark done (1‑based)
    - notes: str — notes
- UndoToDoSteps
  - Purpose: undo step completion status, with optional notes.
  - Parameters:
    - steps: List[int] — step indices to undo (1‑based)
    - notes: str — notes
- ResetToDo
  - Purpose: reset/clear the current ToDo.
  - Parameters: none
- GetToDoSummary / ToDoState
  - Purpose: get ToDo summary / short kanban‑style status phrase.
  - Parameters: none

## Memory / Retrieval

- SemanticSearchInGuidDoc (SemanticSearchInGuidDoc)

  - Purpose: semantic search within Guide_Doc / project docs, returning the most relevant fragments.
  - Parameters:
    - query: str — query text
    - limit: int — number of results (1–100, default 3)

- MemoryPut
  - Purpose: write long‑term memory by scope.
  - Parameters:
    - scope: str — namespace/scope (e.g. general / task‑specific)
    - data: str — content (can be JSON text)
- MemoryGet
  - Purpose: retrieve memory by scope.
  - Parameters:
    - scope: str — namespace/scope
    - query: str — query text
    - limit: int — number of results (1–100, default 3)

## Test / Execution

- RunPyTest (RunPyTest)

  - Purpose: run pytest under a directory/file; can return stdout/stderr.
  - Parameters:
    - test_dir_or_file: str — test directory or file
    - pytest_ex_args: str — extra pytest args (e.g. "-v --capture=no")
    - return_stdout: bool — whether to return stdout
    - return_stderr: bool — whether to return stderr
    - timeout: int — timeout in seconds (default 15)

- RunUnityChipTest (RunUnityChipTest)
  - Purpose: UnityChip‑oriented test runner wrapper producing toffee_report.json etc.
  - Parameters: same as RunPyTest; additionally internal fields (workspace / result_dir / result_json_path).

## File / Path / Text

- SearchText (SearchText)

  - Purpose: text search within workspace; supports glob and regex.
  - Parameters:
    - pattern: str — search pattern (plain/glob/regex)
    - directory: str — relative directory (empty for repo‑wide; if a file path, only search that file)
    - max_match_lines: int — max matched lines per file (default 20)
    - max_match_files: int — max files to return (default 10)
    - use_regex: bool — use regex or not
    - case_sensitive: bool — case sensitive or not
    - include_line_numbers: bool — whether to include line numbers

- FindFiles (FindFiles)

  - Purpose: find files by glob.
  - Parameters:
    - pattern: str — filename pattern (fnmatch glob)
    - directory: str — relative directory (empty for repo‑wide)
    - max_match_files: int — max files to return (default 10)

- PathList (PathList)

  - Purpose: list directory structure (depth‑limited).
  - Parameters:
    - path: str — directory (relative to workspace)
    - depth: int — depth (‑1 all, 0 current)

- ReadBinFile (ReadBinFile)

  - Purpose: read binary file (returns [BIN_DATA]).
  - Parameters:
    - path: str — file path (relative to workspace)
    - start: int — start byte (default 0)
    - end: int — end byte (default ‑1 means EOF)

- ReadTextFile (ReadTextFile)

  - Purpose: read text file (with line numbers, returns [TXT_DATA]).
  - Parameters:
    - path: str — file path (relative to workspace)
    - start: int — start line (1‑based, default 1)
    - count: int — number of lines (‑1 to end of file)

- EditTextFile (EditTextFile)

  - Purpose: edit/create text file; modes: replace/overwrite/append.
  - Parameters:
    - path: str — file path (relative to workspace; created if not exists)
    - data: str — text to write (None to clear)
    - mode: str — edit mode (replace/overwrite/append; default replace)
    - start: int — start line for replace mode (1‑based)
    - count: int — number of lines to replace in replace mode (‑1 to end, 0 insert)
    - preserve_indent: bool — whether to preserve indentation in replace mode

- CopyFile (CopyFile)

  - Purpose: copy file; optional overwrite.
  - Parameters:
    - source_path: str — source file
    - dest_path: str — destination file
    - overwrite: bool — whether to overwrite if destination exists

- MoveFile (MoveFile)

  - Purpose: move/rename file; optional overwrite.
  - Parameters:
    - source_path: str — source file
    - dest_path: str — destination file
    - overwrite: bool — whether to overwrite if destination exists

- DeleteFile (DeleteFile)

  - Purpose: delete file.
  - Parameters:
    - path: str — file path

- CreateDirectory (CreateDirectory)

  - Purpose: create directory (recursive).
  - Parameters:
    - path: str — directory path
    - parents: bool — create parents recursively
    - exist_ok: bool — ignore if already exists

- ReplaceStringInFile (ReplaceStringInFile)

  - Purpose: exact string replacement (strict matching; can create file).
  - Parameters:
    - path: str — target file
    - old_string: str — full original text to replace (with context, exact match)
    - new_string: str — new content

- GetFileInfo (GetFileInfo)
  - Purpose: get file info (size, mtime, human‑readable size etc.).
  - Parameters:
    - path: str — file path

## Extension Example

- SimpleReflectionTool (SimpleReflectionTool)
  - Purpose: example "self‑reflection" tool (from extool.py), as an extension reference.
  - Parameters:
    - message: str — self‑reflection text

Notes:

- Tool call timeout defaults to 20s (individual tools may override); for long tasks, periodically output progress to avoid timeout.
- In MCP no‑file‑tools mode, write‑type tools are not exposed by default; if writing is required, prefer the local Agent mode or restrict writable directories explicitly.
