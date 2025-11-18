---
title: 黑客马拉松
description: 黑客马拉松赛题
categories: [参考]
tags: [docs]
weight: 7
---

## YunSuan介绍

YunSuan模块是开源高性能RISC-V处理器项目XiangShan（香山）的核心组成部分，专门负责实现处理器的各种算术和逻辑运算功能，包括整数运算单元、浮点运算单元、向量处理单元等。YunSuan模块与XiangShan处理器的流水线紧密集成，为RISC-V指令集提供完整的运算支持。

## 赛题简介

本次比赛分为两个排名赛道，找bug赛道和token效率赛道，本次赛题均选自该模块的向量处理单元。每个模块含有五道题，1、2题为简单难度；3题为中等难度；4、5题困难难度。

### 找bug

你需要将选题中的bug找出，确认后在网站上提交；
发现注入bug记100-500分；
若发现全新bug（即在未注入bug的版本中找到新bug，第一个提交队伍活动额外奖金）记 1000-2000分；
最后将按积分进行排名，前3名发奖金

### token效率

利用UCAgent工具的API模式寻找bug，计算token效率：E = bug数/消耗总token （发现人工注入bug必须 > 80%）；
结果按E进行队伍排序，前3名发奖金；

**备注：token将由UCAgent统计；你需要修改UCAgent以达到更高的token效率**
**UCAgent链接：https://github.com/XS-MLVP/UCAgent**

本次给出每个模块第一道题目，剩余题目将于活动当天一并给出
## 赛题&模块：
### VectorFloatFMA

VectorFloatFMA是XiangShan处理器中YunSuan模块的关键组件，专门执行RISC-V V扩展的向量浮点乘加指令，支持FP16、FP32和FP64格式的并行计算，包括乘法、乘加、乘减等操作，并处理舍入模式、异常标志及特殊情况如NaN和无穷大，以实现高性能向量浮点运算。

[无bug版本](VectorFloatFMA.v)

[题目1（简单）](VectorFloatFMA_BUG1.v)

Spec：[向量浮点指令](https://docs.riscv.org/reference/isa/unpriv/v-st-ext.html#sec-vector-float)
### VectorFloatAdder模块

VectorFloatAdder是一个支持多种浮点运算的向量加法器模块，能够处理半精度（f16）、单精度（f32）和双精度（f64）浮点数，并支持扩展操作（如扩展输入和扩展结果）。它支持包括加法、减法、最小值、最大值、比较、符号注入、分类和归约操作在内的多种操作。该模块通过多个子模块并行处理不同精度的数据，并根据操作码和格式选择相应的结果和异常标志。

[无bug版本](VectorFloatAdder.v)

[题目1（简单）](VectorFloatAdder_BUG1.v)

Spec：[向量浮点指令](https://docs.riscv.org/reference/isa/unpriv/v-st-ext.html#sec-vector-float)

### VectorIdiv模块

VectorIdiv 是一个支持多种数据位宽的向量整数除法器模块。它通过并行实例化多个不同位宽的除法子模块来处理128位向量数据，采用状态机控制除法流程，最终输出商、余数向量和除零标志。该设计实现了高效的向量化整数除法运算。

[无bug版本](VectorIdiv.v)

[题目1（简单）](VectorIdiv_BUG1.v)

Spec：[向量整数除法指令](https://docs.riscv.org/reference/isa/unpriv/v-st-ext.html#vector-integer-divide-instructions)

