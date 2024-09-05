---
title: 如何编写测试点
weight: 3
---

## 验证中的测试点

在 mlvp 中，**测试点(Cover Point)** 是指对设计的某个功能进行验证的最小单元，**测试组(Cover Croup)** 是一类测试点的集合。

定义一个测试点，需要指定测试点的名称及测试点的触发条件。例如，可以定义了一个测试点，“当加法器运算结果不为 0 时，结果运算正确”，此时，测试点的触发条件可以为 “加法器的 sum 信号不为零”。

当测试点的触发条件满足时，测试点被触发，此时，验证报告将会记录下该测试点的触发。并会提升验证的功能覆盖率。当所有测试点都被触发时，验证的功能覆盖率达到 100%。

## 如何编写测试点

编写测试点前，首先需要创建一个测试组，并指定测试组的名称


```python
from mlvp.reporter import CovGroup

g = CovGroup("Adder addition function")
```

接着，需要再这个测试组中添加测试点。

```python
# import mlvp.funcov as fc

# g.add_watch_point(adder.io_cout, {"io_cout is 0": fc.Eq(0)}, name="Cout is 0")
```



TBD











## 将测试组加入 PreRequest

在 mlvp 中，可以直接将

