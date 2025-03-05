---
title: Hypothesis
description: Can Be Used to Generate Stimuli
categories: [Sample Projects, Tutorials]
tags: [examples, docs]
weight: 52
---


#  Hypothesis
In the previous section, we manually wrote test cases and specified inputs and expected outputs for each case. This method has some issues, such as incomplete test case coverage and the tendency to overlook **boundary conditions**. Hypothesis is a Python library for property-based testing. Its main goal is to make testing **simpler, faster, and more reliable**. It uses a method called **property-based testing**, where you can write some hypotheses for your code, and Hypothesis will automatically generate test cases to verify these hypotheses. This makes it easier to write comprehensive and efficient tests. Hypothesis can automatically generate various types of input data, including basic types (e.g., integers, floats, strings), container types (e.g., lists, sets, dictionaries), and custom types. It tests based on the properties (assertions) you provide. If a test fails, it will try to narrow down the input data to find the smallest failing case. With Hypothesis, you can better cover the boundary conditions of your code and uncover errors you might not have considered. This helps improve the quality and reliability of your code.

## Basic Concepts
- Test Function: The function or method to be tested.
- Properties: Conditions that the test function should satisfy. Properties are applied to the test function as decorators.
- Strategy: A generator for test data. Hypothesis provides a range of built-in strategies, such as integers, strings, lists, etc. You can also **define custom strategies**.
- Test Generator: A function that generates test data based on strategies. Hypothesis automatically generates test data and passes it as parameters to the test function.

This article will briefly introduce Hypothesis based on testing requirements. The [complete manual](https://hypothesis.readthedocs.io/en/latest/) is available for in-depth study.

## Installation

Install with pip and import in Python to use:

```shell
pip install hypothesis

import hypothesis
```


## Basic Usage

### Properties and Strategies
Hypothesis uses property decorators to define the properties of test functions. The most common decorator is @given, which specifies the properties the test function should satisfy.
We can define a test function test_addition using the @given decorator and add properties to x. The test generator will automatically generate test data for the function and pass it as parameters, for example:
```python
def addition(number: int) -> int:
    return number + 1

@given(x=integers(), y=integers())　　
def test_addition(x, y):　　
	assert x + 1 == addition（1）
```
In this example, integers() is a built-in strategy for generating integer test data. Hypothesis offers a variety of built-in strategies for generating different types of test data. Besides integers(), there are strategies for strings, booleans, lists, dictionaries, etc. For instance, using the text() strategy to generate string test data and using lists(text()) to generate lists of strings:

```python
@given(s=text(), l=lists(text()))
def test_string_concatenation(s, l):　　
	result = s + "".join(l)　　
	assert len(result) == len(s) + sum(len(x) for x in l)
```

You can also define custom strategies to generate specific types of test data, for example, a strategy for non-negative integers:

```python
def non_negative_integers():
　　return integers(min_value=0)
@given(x=non_negative_integers())
　　def test_positive_addition(x):
　　assert x + 1 > x
```

### Expectations
We can use expect to specify the expected result of a function:
```python
@given(x=integers())
def test_addition(x):
    expected = x + 1
    actual = addition(x)
```
### Hypotheses and Assertions
When using Hypothesis for testing, we can use standard Python assertions to verify the properties of the test function. Hypothesis will automatically generate test data and run the test function based on the properties defined in the decorator. If an assertion fails, Hypothesis will try to narrow down the test data to find the smallest failing case.

Suppose we have a string reversal function. We can use an assert statement to check if reversing a string twice equals itself:
```python
def test_reverse_string(s):
    expected = x + 1
    actual = addition(x)
	assert actual == expected
```

## Writing Tests

- Tests in Hypothesis consist of two parts: a function that looks like a regular test in your chosen framework but with some extra parameters, and a @given decorator specifying how to provide those parameters. Here's an example of how to use it to verify a full adder, which we tested previously:

- Based on the previous section's code, we modify the method of generating test cases from random numbers to the integers() method. The modified code is as follows:

```python
from Adder import *
import pytest
import ctypes
import random
from hypothesis import given, strategies as st

# Initializing and Cleaning Up Resources Using pytest Fixture
from Adder import *
import pytest
import ctypes
from hypothesis import given, strategies as st

# Using pytest fixture to initialize and clean up resources
@pytest.fixture(scope="class")
def adder():
    # Create DUTAdder instance and load dynamic library
    dut = DUTAdder()
    # Perform a clock step to prepare the DUT
    dut.Step(1)
    # Code after yield executes after tests finish, for cleanup
    yield dut
    # Clean up DUT resources and generate coverage report and waveform
    dut.Finish()

class TestFullAdder:
    # Define full_adder as a static method, as it doesn't depend on class instance
    @staticmethod
    def full_adder(a, b, cin):
        cin = cin & 0b1
        Sum = ctypes.c_uint64(a).value
        Sum += ctypes.c_uint64(b).value + cin
        Cout = (Sum >> 64) & 0b1
        Sum &= 0xffffffffffffffff
        return Sum, Cout

    # Use Hypothesis to automatically generate test cases
    @given(
        a=st.integers(min_value=0, max_value=0xffffffffffffffff),
        b=st.integers(min_value=0, max_value=0xffffffffffffffff),
        cin=st.integers(min_value=0, max_value=1)
    )
    # Define test method, adder parameter injected by pytest via fixture
    def test_full_adder_with_hypothesis(self, adder, a, b, cin):
        # Calculate expected sum and carry
        sum_expected, cout_expected = self.full_adder(a, b, cin)
        # Set DUT inputs
        adder.a.value = a
        adder.b.value = b
        adder.cin.value = cin
        # Perform a clock step
        adder.Step(1)
        # Assert DUT outputs match expected results
        assert sum_expected == adder.sum.value
        assert cout_expected == adder.cout.value

if __name__ == "__main__":
    # Run specified tests in verbose mode
    pytest.main(['-v', 'test_adder.py::TestFullAdder'])

```
> In this example, the @given decorator and strategies are used to generate random data that meets specified conditions. st.integers() is a strategy for generating integers within a specified range, used to generate numbers between 0 and 0xffffffffffffffff for a and b, and between 0 and 1 for cin. Hypothesis will automatically rerun this test multiple times, each time using different random inputs, helping reveal potential boundary conditions or edge cases.
- Run the tests, and the output will be as follows:
```shell
collected 1 item

 test_adder.py ✓                                                 100% ██████████

Results (0.42s):
       1 passed
```
> As we can see, the tests were completed in a short amount of time.