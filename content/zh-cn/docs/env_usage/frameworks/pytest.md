---
title: PyTest
description: 可用来管理测试，生成测试报告
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 51
---

## 软件测试
>在正式开始pytest 之间我们先了解一下软件的测试，软件测试一般分为如下四个方面
>- 单元测试：称模块测试，针对软件设计中的最小单位——程序模块，进行正确性检查的测试工作
>- 集成测试：称组装测试，通常在单元测试的基础上，将所有程序模块进行有序的、递增测试，重点测试不同模块的接口部分
>- 系统测试：将整个软件系统看成一个整体进行测试，包括对功能、性能以及软件所运行的软硬件环境进行测试
>- 验收测试：指按照项目任务书或合同、供需双方约定的验收依据文档进行的对整个系统的测试与评审，决定是否接收或拒收系统

pytest最初是作为一个单元测试框架而设计的，但它也提供了许多功能，使其能够进行更广泛的测试，包括集成测试，系统测试，他是一个非常成熟的全功能的python 测试框架。
它通过收集测试函数和模块，并提供丰富的断言库来简化测试的编写和运行，是一个非常成熟且功能强大的 Python 测试框架，具有以下几个特点：
- **简单灵活**：Pytest 容易上手，且具有灵活性。
- **支持参数化**：您可以轻松地为测试用例提供不同的参数。
- **全功能**：Pytest 不仅支持简单的单元测试，还可以处理复杂的功能测试。您甚至可以使用它来进行自动化测试，如 Selenium 或 Appium 测试，以及接口自动化测试（结合 Pytest 和 Requests 库）。
- **丰富的插件生态**：Pytest 有许多第三方插件，您还可以自定义扩展。一些常用的插件包括：
    - `pytest-selenium`：集成 Selenium。
    - `pytest-html`：生成HTML测试报告。
    - `pytest-rerunfailures`：在失败的情况下重复执行测试用例。
    - `pytest-xdist`：支持多 CPU 分发。
- **与 Jenkins 集成良好**。
- **支持 Allure 报告框架**。

本文将基于测试需求简单介绍pytest的用法，其[完整手册](https://learning-pytest.readthedocs.io/zh/latest/)在这里，供同学们进行深入学习。
## Pytest安装

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

## Pytest使用

### 命名规则
```python
# 首先在使用pytest 时我们的模块名通常是以test开头或者test结尾，也可以修改配置文件，自定义命名规则
# test_*.py 或 *_test.py
test_demo1
demo2_test

# 模块中的类名要以Test 开始且不能有init 方法
class TestDemo1:
class TestLogin:

# 类中定义的测试方法名要以test_开头
test_demo1(self)
test_demo2(self)

# 测试用例
class test_one:
    def test_demo1(self):
        print("测试用例1")

    def test_demo2(self):
        print("测试用例2")
```
### Pytest 参数
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


### Pytest 选择测试用例执行

**在 Pytest 中，您可以按照测试文件夹、测试文件、测试类和测试方法的不同维度来选择执行测试用例。**

- 按照测试文件夹执行
```python
# 执行所有当前文件夹及子文件夹下的所有测试用例
pytest .
# 执行跟当前文件夹同级的tests文件夹及子文件夹下的所有测试用例
pytest ../tests

# 按照测试文件执行
# 运行test_se.py下的所有的测试用例
pytest test_se.py

# 按照测试类执行，必须以如下格式：
pytest 文件名 .py:: 测试类，其中“::”是分隔符，用于分割测试module和测试类。
# 运行test_se.py文件下的，类名是TestSE下的所有测试用例
pytest test_se.py::TestSE

# 测试方法执行，必须以如下格式：
pytest 文件名 .py:: 测试类 :: 测试方法，其中 “::” 是分隔符，用于分割测试module、测试类，以及测试方法。
# 运行test_se.py文件下的，类名是TestSE下的，名字为test_get_new_message的测试用例
pytest test_se.py::TestSE::test_get_new_message

# 以上选择测试用例的方法均是在**命令行**，如果您想直接在测试程序里执行可以直接在main函数中**调用pytest.main()**,其格式为：
pytest.main([模块.py::类::方法])
```

> 此外，Pytest 还支持控制测试用例执行的多种方式，例如过滤执行、多进程运行、重试运行等。


## 使用Pytest编写验证
- 在测试过程中，我们使用之前验证过的加法器，进入Adder文件夹，在picker_out_adder目录下新建一个test_adder.py文件，内容如下：
```python
# 导入测试模块和所需的库
from Adder import *
import pytest
import ctypes
import random

# 使用 pytest fixture 来初始化和清理资源
@pytest.fixture
def adder():
    # 创建 DUTAdder 实例，加载动态链接库
    dut = DUTAdder()
    # 执行一次时钟步进，准备 DUT
    dut.Step(1)
    # yield 语句之后的代码会在测试结束后执行，用于清理资源
    yield dut
    # 清理DUT资源，并生成测试覆盖率报告和波形
    dut.Finish()

class TestFullAdder:
    # 将 full_adder 定义为静态方法，因为它不依赖于类实例
    @staticmethod
    def full_adder(a, b, cin):
        cin = cin & 0b1
        Sum = ctypes.c_uint64(a).value
        Sum += ctypes.c_uint64(b).value + cin
        Cout = (Sum >> 64) & 0b1
        Sum &= 0xffffffffffffffff
        return Sum, Cout

    # 使用 pytest.mark.usefixtures 装饰器指定使用的 fixture
    @pytest.mark.usefixtures("adder")
    # 定义测试方法，adder 参数由 pytest 通过 fixture 注入
    def test_adder(self, adder):
        # 进行多次随机测试
        for _ in range(114514):
            # 随机生成 64 位的 a 和 b，以及 1 位的进位 cin
            a = random.getrandbits(64)
            b = random.getrandbits(64)
            cin = random.getrandbits(1)
            # 设置 DUT 的输入
            adder.a.value = a
            adder.b.value = b
            adder.cin.value = cin
            # 执行一次时钟步进
            adder.Step(1)
            # 使用静态方法计算预期结果
            sum, cout = self.full_adder(a, b, cin)
            # 断言 DUT 的输出与预期结果相同
            assert sum == adder.sum.value
            assert cout == adder.cout.value

if __name__ == "__main__":
    pytest.main(['-v', 'test_adder.py::TestFullAdder'])
```

- 运行测试之后输出如下：
```shell
collected 1 item

 test_adder.py ✓                                                 100% ██████████

Results (4.33s):
```

>测试成功表明，在经过114514次循环之后，我们的设备暂时没有发现bug。然而，使用多次循环的随机数生成测试用例会消耗大量资源，并且这些随机生成的测试用例可能无法有效覆盖所有边界条件。在下一部分，我们将介绍一种更有效的测试用例生成方法。
