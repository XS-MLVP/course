---
title: PyTest
description: 可用来管理测试，生成测试报告
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 51
---

## 1. 软件测试
在正式开始pytest 之间我们先了解一下软件的测试，软件测试一般分为如下四个方面
- 单元测试：称模块测试，针对软件设计中的最小单位——程序模块，进行正确性检查的测试工作
- 集成测试：称组装测试，通常在单元测试的基础上，将所有程序模块进行有序的、递增测试，重点测试不同模块的接口部分
- 系统测试：将整个软件系统看成一个整体进行测试，包括对功能、性能以及软件所运行的软硬件环境进行测试
- 验收测试：指按照项目任务书或合同、供需双方约定的验收依据文档进行的对整个系统的测试与评审，决定是否接收或拒收系统


> pytest最初是作为一个单元测试框架而设计的，但它也提供了许多功能，使其能够进行更广泛的测试，包括集成测试，系统测试，他是一个非常成熟的全功能的python 测试框架。
> 它通过收集测试函数和模块，并提供丰富的断言库来简化测试的编写和运行
1. **收集测试用例**：pytest 会搜索当前目录及其子目录中的 Python 文件，找到符合命名约定的测试文件和测试函数。
2. **运行测试**：它可以通过命令行运行所有测试用例，也可以运行特定的测试文件、模块或者单个测试函数
3. **断言** ：提供了丰富的断言库，用于验证测试结果是否符合预期。这些断言包括等值比较、异常抛出、容器包含等等
4. **Fixture**：pytest 使用 fixture 机制来管理测试用例的环境设置和清理工作
5. 


- 简单灵活，容易上手
- 支持参数化
- 测试用例的skip和xfail，自动失败重试等处理

## 2. 安装

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


## 3. 使用

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
- 测试用例的例子
```bash hl: title:
class test_one:
    def test_demo1(self):
        print("测试用例1")

    def test_demo2(self):
        print("测试用例2")
```
### 3.2. 参数解析
- 打印详细运行日志信息：pytest -v (最高级别信息-verbose)
- S 是带控制台输出结果，也是输出详细，可以打印测试用例中 print 的输出：pytest -v -s 文件名
- 执行单独一个 pytest 模块：pytest 文件名. Py
- 运行某个模块里面某个类：pytest 文件名. Py:: 类名
- 运行某个模块里面某个类里面的方法：pytest 文件名. Py:: 类名:: 方法名
- -k：运行测试用例名称中包含某个字符串的测试用例：pytest -k "类名 and not 方法名"，如 pytest -k "TestDemo and not test_one"
- -m ：也叫冒烟用例运行带有某标记的测试用例 (pytest. mark. 标记名)
- -x：出现一个失败用例就立即停止
-  --maxfail = num：当错误达到 num 的时候就停止运行：
-  --html 路径：生成html 报告


> 冒烟用例：

### 3.3. 使用
可以在main 方法或者终端中使用pytest

```bash hl: title:

# 不带参数使用
if __name__ == '__main__':
	pytest.main()
# 带参数使用
if __name__ == '__main__':
	pytest.main(["‐vs"])
# 命令行使用
 ./testcase/test_one.py --html=./report/report.html

```
