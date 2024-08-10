---
title: PyTest
description: Used for managing tests and generating test reports.
categories: [Sample Projects, Tutorials]
tags: [examples, docs]
weight: 51
---

## Software Testing
> Before we start with pytest, let's understand software testing. Software testing generally involves the following four aspects:
>- Unit Testing: Also known as module testing, it involves checking the correctness of program modules, which are the smallest units in software design.
>- Integration Testing: Also known as assembly testing, it usually builds on unit testing by sequentially and incrementally testing all program modules, focusing on the interface parts of different modules.
>- System Testing: It treats the entire software system as a whole for testing, including testing the functionality, performance, and the software's running environment.
>- Acceptance Testing: Refers to testing the entire system according to the project task book, contract, and acceptance criteria agreed upon by both the supply and demand sides, to determine whether to accept or reject the system.

pytest was initially designed as a unit testing framework, but it also provides many features that allow it to be used for a wider range of testing, including integration testing and system testing. It is a very mature full-featured Python testing framework.
It simplifies test writing and execution by collecting test functions and modules and providing a rich assertion library. It is a very mature and powerful Python testing framework with the following key features:
- **Simple and Flexible**: Pytest is easy to get started with and is flexible.
- **Supports Parameterization**: You can easily provide different parameters for test cases.
- **Full-featured**: Pytest not only supports simple unit testing but can also handle complex functional testing. You can even use it for automation testing, such as Selenium or Appium testing, as well as interface automation testing (combining Pytest with the Requests library).
- **Rich Plugin Ecosystem**: Pytest has many third-party plugins, and you can also customize extensions. Some commonly used plugins include:
    - `pytest-selenium`: Integrates Selenium.
    - `pytest-html`: Generates HTML test reports.
    - `pytest-rerunfailures`: Repeats test cases in case of failure.
    - `pytest-xdist`: Supports multi-CPU distribution.
- **Well Integrated with Jenkins**.
- **Supports Allure Report Framework**.

This article will briefly introduce the usage of pytest based on testing requirements. The [complete manual](https://learning-pytest.readthedocs.io/zh/latest/) is available here for students to study in depth.
## Installing Pytest

```bash hl: title:
# Install pytest:
pip install pytest
# Upgrade pytest
pip install -U pytest
# Check pytest version
pytest --version
# Check installed package list
pip list
# Check pytest help documentation
pytest -h
# Install third-party plugins
pip install pytest-sugar
pip install pytest-rerunfailures
pip install pytest-xdist
pip install pytest-assume
pip install pytest-html
```

## Using Pytest

### Naming Convention
```python
# When using pytest, our module names are usually prefixed with test or end with test. You can also modify the configuration file to customize the naming convention.
# test_*.py or *_test.py
test_demo1
demo2_test

# The class name in the module must start with Test and cannot have an init method.
class TestDemo1:
class TestLogin:

# The test methods defined in the class must start with test_
test_demo1(self)
test_demo2(self)

# Test Case
class test_one:
    def test_demo1(self):
        print("Test Case 1")

    def test_demo2(self):
        print("Test Case 2")
```
### Pytest Parameters
pytest supports many parameters, which can be viewed using the help command.
```bash hl :title
pytest -help
```
Here are some commonly used ones:

-m: Specify multiple tag names with an expression. pytest provides a decorator @pytest.mark.xxx for marking tests and grouping them (xxx is the group name you defined), so you can quickly select and run them, with different groups separated by and or or.

-v: Outputs more detailed information during runtime. Without -v, the runtime does not display the specific test case names being run; with -v, it prints out the specific test cases in the console.

-q: Similar to the verbosity in unittest, used to simplify the runtime output. When running tests with -q, only simple runtime information is displayed, for example:
``` bash hl :title
.s..  [100%]
3 passed, 1 skipped in 9.60s
```
-k: You can run specified test cases using an expression. It is a fuzzy match, with and or or separating keywords, and the matching range includes file names, class names, and function names.

-x: Exit the test if one test case fails. This is very useful for debugging. When a test fails, stop running the subsequent tests.

-s: Display print content. When running test scripts, we often add some print content for debugging or printing some content. However, when running pytest, this content is not displayed. If you add -s, it will be displayed.
``` bash hl : title
pytest test_se.py -s
```


### Selecting Test Cases to Execute with Pytest

**In Pytest, you can select and execute test cases based on different dimensions such as test folders, test files, test classes, and test methods.**

- Execute by test folder
```python
# Execute all test cases in the current folder and subfolders
pytest .
# Execute all test cases in the tests folder and its subfolders, which are at the same level as the current folder
pytest ../tests

# Execute by test file
# Run all test cases in test_se.py
pytest test_se.py

# Execute by test class, must be in the following format:
pytest file_name.py::TestClass, where "::" is the separator used to separate the test module and test class.
# Run all test cases under the class named TestSE in the test_se.py file
pytest test_se.py::TestSE

# Execute by test method, must be in the following format:
pytest file_name.py::TestClass::TestMethod, where "::" is the separator used to separate the test module, test class, and test method.
# Run the test case named test_get_new_message under the class named TestSE in the test_se.py file 
pytest test_se.py::TestSE::test_get_new_message

# The above methods of selecting test cases are all on the **command line**. If you want to execute directly in the test program, you can directly call pytest.main(), the format is:
pytest.main([module.py::class::method])
```

> In addition, Pytest also supports multiple ways to control the execution of test cases, such as filtering execution, running in multiple processes, retrying execution, etc.


## Writing Validation with Pytest
- During testing, we use the previously validated adder. Go to the Adder folder, create a new test_adder.py file in the picker_out_adder directory, with the following content:
```python 
# Import test modules and required libraries
from UT_Adder import *
import pytest
import ctypes
import random

# Use pytest fixture to initialize and clean up resources
@pytest.fixture
def adder():
    # Create an instance of DUTAdder, load the dynamic link library
    dut = DUTAdder()
    # Execute one clock step to prepare the DUT
    dut.Step(1)
    # The code after the yield statement will be executed after the test ends, used to clean up resources
    yield dut
    # Clean up DUT resources and generate test coverage reports and waveforms
    dut.Finish()

class TestFullAdder:
    # Define full_adder as a static method, as it does not depend on class instances
    @staticmethod
    def full_adder(a, b, cin):
        cin = cin & 0b1
        Sum = ctypes.c_uint64(a).value
        Sum += ctypes.c_uint64(b).value + cin
        Cout = (Sum >> 64) & 0b1
        Sum &= 0xffffffffffffffff
        return Sum, Cout

    # Use the pytest.mark.usefixtures decorator to specify the fixture to use
    @pytest.mark.usefixtures("adder")
    # Define the test method, where adder is injected by pytest through the fixture
    def test_adder(self, adder):
        # Perform multiple random tests
        for _ in range(114514):
            # Generate random 64-bit a, b, and 1-bit cin
            a = random.getrandbits(64)
            b = random.getrandbits(64)
            cin = random.getrandbits(1)
            # Set the input of the DUT
            adder.a.value = a
            adder.b.value = b
            adder.cin.value = cin
            # Execute one clock step
            adder.Step(1)
            # Calculate the expected result using a static method
            sum, cout = self.full_adder(a, b, cin)
            # Assert that the output of the DUT is the same as the expected result
            assert sum == adder.sum.value
            assert cout == adder.cout.value

if __name__ == "__main__":
    pytest.main(['-v', 'test_adder.py::TestFullAdder'])
```

- After running the test, the output is as follows:
```shell
collected 1 item                                                               

 test_adder.py ✓                                                 100% ██████████

Results (4.33s):
```

> The successful test indicates that after 114514 loops, our device has not found any bugs for now. However, using randomly generated test cases with multiple loops consumes a considerable amount of resources, and these randomly generated test cases may not effectively cover all boundary conditions. In the next section, we will introduce a more efficient method for generating test cases.
