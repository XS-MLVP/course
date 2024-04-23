---
title: Hypothesis
description: 可用来生成随机激励
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 52
---


#  Hypothesis
> 在传统的软件测试中，我们通常需要手动编写测试用例，并为每个用例指定输入和预期输出。这种方式存在一些问题，例如测试用例覆盖不全面、边界条件容易被忽略等。Hypothesis 库通过属性基测试的思想，可以自动生成测试数据，并使用这些数据进行自动化测试。它的目标是发现潜在的错误和边界情况，从而提高代码的质量和可靠性

Hypothesis 的核心思想是使用假设（hypothesis）来推断代码的行为，并根据这些假设来生成测试数据

## 1. 基本概念
1. 测试函数：即待测试的函数或方法，我们需要对其进行测试。
2. 属性：定义了测试函数应该满足的条件。属性是以装饰器的形式应用于**测试函数**上的。
3. 策略：用于生成测试数据的生成器。Hypothesis 提供了一系列内置的策略，如整数、字符串、列表等。我们也可以自定义策略。
4. 测试生成器：基于策略生成测试数据的函数。Hypothesis 会自动为我们生成测试数据，并将其作为参数传递给测试函数。

## 2. 安装
可以使用pip 命令安装 Hypothesis，然后在python 中导入就可以使用
```bash hl: title:
pip install hypothesis

import hypothesis
```


## 3. 使用

### 3.1. 属性和策略   
>Hypothesis 使用属性装饰器来定义测试函数的属性。最常用的装饰器是 @given，它指定了测试函数应该满足的属性。

我们可以通过@given 装饰器定义了一个测试函数 test_addition。并给x 添加对应的属性，测试生成器会自动为测试函数生成测试数据，并将其作为参数传递给函数，例如
```bash hl: title:
def addition(number: int) -> int:
    return number + 1

@given(x=integers(), y=integers())　　
def test_addition(x, y):　　   
	assert x + 1 == addition（1）
```

其中Integers () 是一个内置的策略，用于生成整数类型的测试数据。Hypothesis 提供了丰富的内置策略，用于生成各种类型的测试数据。除了 Integers ()之外，还有字符串、布尔值、列表、字典等策略。例如使用 text () 策略生成字符串类型的测试数据，使用 lists (text ()) 策略生成字符串列表类型的测试数据
```bash hl: title:
@given(s=text(), l=lists(text()))
def test_string_concatenation(s, l):　　   
	result = s + "".join(l)　　   
	assert len(result) == len(s) + sum(len(x) for x in l)
```

除了可以使用内置的策略以外，还可以使用自定义策略来生成特定类型的测试数据，例如我们可以生产一个非负整形的策略
```bash hl: title:
def non_negative_integers():
　　return integers(min_value=0)
@given(x=non_negative_integers())
　　def test_positive_addition(x):
　　assert x + 1 > x
```

### 3.2. 期望
我们可以通过expect 来指明需要的函数期待得到的结果
```bash hl: title:
@given(x=integers())
def test_addition(x):
    expected = x + 1
    actual = addition(x)
   
    
```

### 3.3. 假设和断言
在使用 Hypothesis 进行测试时，我们可以使用标准的 Python 断言来验证测试函数的属性。Hypothesis 会自动为我们生成测试数据，并根据属性装饰器中定义的属性来运行测试函数。如果断言失败，Hypothesis 会尝试缩小测试数据的范围，以找出导致失败的最小样例。

假如我们有一个字符串反转函数，我们可以通过assert 来判断翻转两次后他是不是等于自身
```bash hl: title:
def test_reverse_string(s):
    expected = x + 1
    actual = addition(x)
	assert actual == expected
```

### 3.4 使用Hypothesis结合pytest验证全加器
在上一节的例子上，我们可以进行一些修改，将生成测试用例的方法从随机数修改为integers ()方法，修改后的代码如下：

```bash hl: title:
from UT_Adder import *
import pytest
import ctypes
from hypothesis import given, strategies as st


def full_adder(a, b, cin):
	cin = cin & 0b1
	Sum = ctypes.c_uint64(a).value
	Sum = Sum + ctypes.c_uint64(b).value + cin
	Cout = (Sum > 0xffffffffffffffff)
	Sum = Sum & 0xffffffffffffffff
	return Sum, Cout

@given(
    a=st.integers(min_value=0, max_value=0xffffffffffffffff),
    b=st.integers(min_value=0, max_value=0xffffffffffffffff),
    cin=st.integers(min_value=0, max_value=1)
)
def test_full_adder_with_hypothesis(a, b, cin):
	dut=DUTAdder("libDPIAdder.so")
	dut.Step(1)
	sum_expected, cout_expected = full_adder(a, b, cin)
	dut.a.xdata.value = a
	dut.b.xdata.value = b
	dut.cin.xdata.value = cin
	dut.Step(1)
	assert sum_expected == dut.sum.xdata.value
	assert cout_expected == dut.cout.xdata.value

if __name__=="__main__":
	pytest.main(['-v', 'test_adder.py::test_full_adder_with_hypothesis'])

```

运行测试，输出结果如下：
```bash hl: title:

test_adder.py ✓                                                 100% ██████████

Results (1.65s):
       1 passed

```

这个例子中，@given 装饰器和 strategies 用于生成符合条件的随机数据。st.integers() 是生成指定范围整数的策略，用于为 a 和 b 生成 0 到 0xffffffffffffffff 之间的数，以及为 cin 生成 0 或 1。Hypothesis会自动重复运行这个测试，每次都使用不同的随机输入，这有助于揭示潜在的边界条件或异常情况。对比使用随机数生成测试用例的test，可以看到，使用given方法生成的测试用例覆盖率更高。