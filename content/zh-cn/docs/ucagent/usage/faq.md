---
title: FAQ
description: 常见问题与解答。
categories: [教程]
tags: [docs]
weight: 6
---

## FAQ

- 模型切换：在 `config.yaml` 改 `openai.model_name`
- 验证过程中出现错误怎么办：使用 `Ctrl+C` 进入交互模式，通过 `status` 查看当前状态，使用 `help` 获取调试命令。
- Check 失败：先 `ReadTextFile` 阅读 reference_files；再按返回信息修复，循环 RunTestCases → Check
- 自定义阶段：修改 `vagent/lang/zh/config/default.yaml` 的 `stage`；或用 `--override` 临时覆盖
- 添加工具：`vagent/tools/` 下新建类，继承 `UCTool`，运行时 `--ex-tools YourTool`
- MCP 连接失败：检查端口/防火墙，改 `--mcp-server-port`；无嵌入可加 `--no-embed-tools`
- 只读保护：通过 `--no-write/--nw` 指定路径限制写入（必须位于 workspace 内）

### 为什么快速启动找不到config.yaml/定制流程时找不到config.yaml?

- 使用pip 安装后并没有`config.yaml`那个文件，所以在快速启动的[启动 MCP Server](../introduce.md#命令)没有加`--config config.yaml`这个选项。
- 可以通过在工作目录添加`config.yaml`文件并且加上`--config config.yaml`参数来启动；也可以使用克隆仓库来使用UCAgent的方式来解决。



### 运行中如何调整消息窗口与 token 上限？

- 在 TUI 输入：`message_config` 查看当前配置；
- 设置：`message_config max_keep_msgs 8` 或 `message_config max_token 4096`；
- 作用范围：影响会话历史裁剪与送入 LLM 的最大 token 上限（通过 Summarization/Trim 节点生效）。

### 文档中的 “CK bug” 要改吗？

- 是。术语统一为 “TC bug”。同时确保 bug 文档里的 `<TC-*>` 能匹配失败用例（文件/类/用例名）。

### 为什么找不到 WriteTextFile 工具？

- 该工具已移除。请改用 `EditTextFile`（支持 overwrite/append/replace 三种模式）或其他文件工具（Copy/Move/Delete 等）。
