---
title: How to Use Pytest to Manage Test Cases
weight: 2
---

## Writing Test Cases 
In `mlvp`, test cases are managed using `pytest`. `pytest` is a powerful Python testing framework. If you are not familiar with `pytest`, you can refer to the [official pytest documentation](https://docs.pytest.org/en/latest/) .
### Writing Your First Test Case 
First, we need to create a test case file, for example, `test_adder.py`. The file should start with `test_` or end with `_test.py` so that `pytest` can recognize it. Then we can write our first test case in it.

```python
# test_adder.py

async def my_test():
    env = AdderEnv()
    env.add_agent.exec_add(1, 2, 0)

def test_adder():
    mlvp.run(my_test())
```
`pytest` cannot directly run coroutine test cases, so we need to call `mlvp.run` in the test case to execute the asynchronous test case.Once the test case is written, we can run `pytest` in the terminal.

```bash
pytest
```
`pytest` will look for all files in the current directory that start with `test_` or end with `_test.py` and will run the functions that start with `test_`, treating each function as a test case.
### Running Coroutine Test Cases 
To enable `pytest` to run coroutine test cases directly, `mlvp` provides the `mlvp_async` marker to mark asynchronous test cases.

```python
# test_adder.py

@pytest.mark.mlvp_async
async def test_adder():
    env = AdderEnv(DUTAdder())
    await env.add_agent.exec_add(1, 2, 0)
```
As shown, we simply need to add the `@pytest.mark.mlvp_async` marker to the test case function, and `pytest` will be able to run coroutine test cases directly.
## Generating Test Reports 
When running `pytest`, `mlvp` will automatically collect the execution results of test cases, tally coverage information, and generate a validation report. To generate this report, you need to add the `--mlvp-report` parameter when calling `pytest`.

```bash
pytest --mlvp-report
```
By default, `mlvp` will generate a default report name for each run and place the report in the `reports` directory. You can specify the report storage directory using the `--report-dir` parameter and the report name using the `--report-name` parameter.However, at this point, since `mlvp` cannot determine the coverage file name, the report cannot display coverage information. If you want coverage information to be shown in the report, you need to pass the functional coverage group and line coverage file name in each test case.

```python
@pytest.mark.mlvp_async
async def test_adder(request):
    adder = DUTAdder(
        waveform_filename="adder.fst",
        coverage_filename="adder.dat"
    )
    g = CovGroup("Adder")

    env = AdderEnv(adder)
    await env.add_agent.exec_add(1, 2, 0)

    adder.Finish()
    set_func_coverage(request, cov_groups)
    set_line_coverage(request, "adder.dat")
```

In the code above, when creating the DUT, we pass the names of the waveform file and coverage file, allowing the DUT to generate a coverage file with the specified name during execution. Then we define a coverage group to collect the functional coverage information of the DUT, which will be explained in detail in the next document.
Next, we call the DUT's `Finish` method to stop recording the waveform file. Finally, we use the `set_func_coverage` and `set_line_coverage` functions to set the functional coverage group and line coverage file information.When we run `pytest` again, `mlvp` will automatically collect the coverage information and display it in the report.Managing Resources with `mlvp`
However, the above process is quite cumbersome, and to ensure that file names do not conflict between each test case, we need to pass different file names in each test case. Additionally, if a test case encounters an exception, it will not complete, resulting in the coverage file not being generated.
Therefore, `mlvp` provides the `mlvp_pre_request` Fixture to manage resources and simplify the writing of test cases.

```python
# test_adder.py

@pytest.mark.mlvp_async
async def test_adder(my_request):
    dut = my_request
    env = AdderEnv(dut)
    await env.add_agent.exec_add(1, 2, 0)

@pytest.fixture()
def my_request(mlvp_pre_request: PreRequest):
    mlvp_pre_request.add_cov_groups(CovGroup("Adder"))
    return mlvp_pre_request.create_dut(DUTAdder)
```
Fixtures are a concept in `pytest`. In the code above, we define a fixture named `my_request`. If any other test case has an output parameter containing the `my_request` parameter, `pytest` will automatically call the `my_request` fixture and pass its return value to the test case.In the code above, we defined a custom fixture `my_request` and used it in the test case, which means that the resource management will be handled within the fixture, allowing the test case to focus solely on the test logic. The `my_request` fixture must use `mlvp`'s provided `mlvp_pre_request` fixture as a parameter for resource management. The `mlvp_pre_request` fixture provides a series of methods for managing resources.By using `add_cov_groups`, the coverage group will be automatically included in the report.
Using `create_dut`, a DUT instance is created, and `mlvp` will automatically manage the generation of the DUT's waveform and coverage files, ensuring that file names do not conflict.In `my_request`, you can customize the return values passed to the test case. If you want any test case to access the fixture, you can define the fixture in the `conftest.py` file.
Thus, we have achieved the separation of test case resource management and logic writing, eliminating the need to manually manage resource creation and release in each test case.