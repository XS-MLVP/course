---
title: PyTest
description: 可用来管理测试，生成测试报告
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 51
---

## 1. 软件测试
>在正式开始pytest 之间我们先了解一下软件的测试，软件测试一般分为如下四个方面
>- 单元测试：称模块测试，针对软件设计中的最小单位——程序模块，进行正确性检查的测试工作
>- 集成测试：称组装测试，通常在单元测试的基础上，将所有程序模块进行有序的、递增测试，重点测试不同模块的接口部分
>- 系统测试：将整个软件系统看成一个整体进行测试，包括对功能、性能以及软件所运行的软硬件环境进行测试
>- 验收测试：指按照项目任务书或合同、供需双方约定的验收依据文档进行的对整个系统的测试与评审，决定是否接收或拒收系统


>pytest最初是作为一个单元测试框架而设计的，但它也提供了许多功能，使其能够进行更广泛的测试，包括集成测试，系统测试，他是一个非常成熟的全功能的python 测试框架。
它通过收集测试函数和模块，并提供丰富的断言库来简化测试的编写和运行，是一个非常成熟且功能强大的 Python 测试框架，具有以下几个特点：
>- **简单灵活**：Pytest 容易上手，且具有灵活性。
>- **支持参数化**：您可以轻松地为测试用例提供不同的参数。
>- **全功能**：Pytest 不仅支持简单的单元测试，还可以处理复杂的功能测试。您甚至可以使用它来进行自动化测试，如 Selenium 或 Appium 测试，以及接口自动化测试（结合 Pytest 和 Requests 库）。
>- **丰富的插件生态**：Pytest 有许多第三方插件，您还可以自定义扩展。一些常用的插件包括：
>    - `pytest-selenium`：集成 Selenium。
>    - `pytest-html`：生成HTML测试报告。
>    - `pytest-rerunfailures`：在失败的情况下重复执行测试用例。
>    - `pytest-xdist`：支持多 CPU 分发。
>- **与 Jenkins 集成良好**。
>- **支持 Allure 报告框架**。

本文将基于测试需求简单介绍pytest的用法，其[完整手册](https://learning-pytest.readthedocs.io/zh/latest/)在这里，供同学们进行深入学习。
## 2. Pytest安装

```bash hl: title:
# 安装pytest：
pip install pytest
# 升级pytest
pip install -U pytest
# 查看pytest版本
pytest --version
# 查看已安装包列表
pip list
# 查看pytest帮助文档
pytest -h
# 安装第三方插件
pip install pytest-sugar
pip install pytest-rerunfailures
pip install pytest-xdist
pip install pytest-assume
pip install pytest-html
```

## 3. Pytest使用

### 3.1. 命名规则
- 首先在使用pytest 时我们的模块名通常是以test 开头或者test 结尾
```bash hl: title:
#test_*.py 或 *_test.py
test_demo1
demo2_test
```
- 模块中的类名要以Test 开始且不能有init 方法
```bash hl: title:
class TestDemo1:
class TestLogin:
```
- 类中定义的测试方法名要以test_开头
```bash hl: title:
test_demo1(self)
test_demo2(self)
```
- 测试用例
```bash hl: title:
class test_one:
    def test_demo1(self):
        print("测试用例1")

    def test_demo2(self):
        print("测试用例2")
```
### 3.2. Pytest 参数
pytest支持很多参数，可以通过help命令查看
```bash hl :title
pytest -help
```
我们在这里列出来常用的几个：

-m: 用表达式指定多个标记名。 pytest 提供了一个装饰器 @pytest.mark.xxx，用于标记测试并分组（xxx是你定义的分组名），以便你快速选中并运行，各个分组直接用 and、or 来分割。

-v: 运行时输出更详细的用例执行信息 不使用-v参数，运行时不会显示运行的具体测试用例名称；使用-v参数，会在 console 里打印出具体哪条测试用例被运行。

-q: 类似 unittest 里的 verbosity，用来简化运行输出信息。 使用 -q 运行测试用例，仅仅显示很简单的运行信息， 例如：
``` bash hl :title
.s..  [100%]
3 passed, 1 skipped in 9.60s
```
-k: 可以通过表达式运行指定的测试用例。 它是一种模糊匹配，用 and 或 or 区分各个关键字，匹配范围有文件名、类名、函数名。

-x: 出现一条测试用例失败就退出测试。 在调试时，这个功能非常有用。当出现测试失败时，停止运行后续的测试。

-s: 显示print内容 在运行测试脚本时，为了调试或打印一些内容，我们会在代码中加一些print内容，但是在运行pytest时，这些内容不会显示出来。如果带上-s，就可以显示了。
``` bash hl : title
pytest test_se.py -s
```


### 3.3. Pytest 选择测试用例执行

**在 Pytest 中，您可以按照测试文件夹、测试文件、测试类和测试方法的不同维度来选择执行测试用例。**

- 按照测试文件夹执行
```
# 执行所有当前文件夹及子文件夹下的所有测试用例
pytest .
# 执行跟当前文件夹同级的tests文件夹及子文件夹下的所有测试用例
pytest ../tests
```

- 按照测试文件执行
```
# 运行test_se.py下的所有的测试用例
pytest test_se.py
```

- 按照测试类执行
```
# 按照测试类执行，必须以如下格式：
pytest 文件名 .py:: 测试类，其中“::”是分隔符，用于分割测试module和测试类。
# 运行test_se.py文件下的，类名是TestSE下的所有测试用例
pytest test_se.py::TestSE
```

- 按照测试方法执行
```
# 同样的测试方法执行，必须以如下格式：
pytest 文件名 .py:: 测试类 :: 测试方法，其中 “::” 是分隔符，用于分割测试module、测试类，以及测试方法。
# 运行test_se.py文件下的，类名是TestSE下的，名字为test_get_new_message的测试用例 
pytest test_se.py::TestSE::test_get_new_message
```
- 以上选择测试用例的方法均是在**命令行**，如果您想直接在测试程序里执行可以直接在main函数中**调用pytest.main()**,其格式为：
```
pytest.main([模块.py::类::方法])
```

此外，Pytest 还支持控制测试用例执行的多种方式，例如过滤执行、多进程运行、重试运行等。


## 4. 使用Pytest编写验证
- 在测试过程中，我们使用之前验证过的加法器，进入Adder文件夹，删除之前生成的文件夹，执行如下命令：
```bash
picker Adder.v -w Adder.fst -S Adder -t picker_out_adder -l python -c --sim verilator
```

- 该命令的含义是：

1. 将Adder.v作为 Top 文件，并将Adder作为 Top Module，利用verilator仿真器将其编译为Python Class
3. 输出覆盖测试率(-c)
4. 最终的文件输出路径是 picker_out_adder

- make编译之后Adder目录结构如下：

```bash hl: title:
├── Adder.v 
└── picker_out_adder
    └── UT_Adder
        ├── Adder.fst.hier
        ├── __init__.py 
        ├── libDPIAdder.a
        ├── libUT_Adder.py  //picker导出的封装
        ├── libUTAdder.so
        ├── _UT_Adder.so
        └── xspcomm // xscomm库的python版本(picker生成)
            ├── info.py
            ├── __init__.py
            ├── __pycache__
            │   ├── __init__.cpython-310.pyc
            │   └── pyxspcomm.cpython-310.pyc
            ├── pyxspcomm.py    
            ├── _pyxspcomm.so -> _pyxspcomm.so.0.0.1
            └── _pyxspcomm.so.0.0.1
```

- 此时在picker_out_adder目录下新建一个test_adder.py文件，内容如下：

```bash hl：title
from UT_Adder import *
import pytest
import ctypes
from hypothesis import given, strategies as st
import random

def full_adder(a, b, cin):
    cin = cin & 0b1
    Sum = ctypes.c_uint64(a).value
    Sum = Sum + ctypes.c_uint64(b).value + cin
    Cout = (Sum >> 64) & 0b1
    Sum = Sum & 0xffffffffffffffff
    return Sum, Cout

def test_adder():
    dut=DUTAdder("libDPIAdder.so")
    dut.Step(1)
    dut=DUTAdder("libDPIAdder.so")
    dut.Step(1)
    for _ in range(114514):
        a = random.getrandbits(64)
        b = random.getrandbits(64)
        cin = random.getrandbits(1)
        dut.a.value = a
        dut.b.value = b
        dut.cin.value = cin
        dut.Step(1)
        sum, cout = full_adder(a, b, cin)
        assert sum == dut.sum.value
        assert cout == dut.cout.value
    dut.finalize()

if __name__ == "__main__":
    pytest.main(['-v', 'test_adder.py::test_adder'])
```
>其中，full_adder函数是一个模拟全加器的函数，使用 ctypes.c_uint64 将 a, b 包装成64位无符号整数，保证数值在进行算术操作时不会因为Python的整数自动扩展而出错。

- 运行python代码，可以看到输出如下：
```bash hl：title
 test_adder.py ✓                                                 100% ██████████

Results (4.71s):
       1 passed
```
>说明经过114514次循环，暂时没有检测出我们的DUT有bug，但是用多次循环随机数来生成测试用例的话，会消耗大量的资源，而且随机出来的测试用例也不一定能有有效的覆盖各种边界条件，在下一节中我们会介绍一个强大的方法来生成测试用例。