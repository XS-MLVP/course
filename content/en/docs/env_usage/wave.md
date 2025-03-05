---
title: Waveform Generation
description: Generate circuit waveforms.
categories: [Sample Projects, Tutorials]
tags: [examples, docs]
weight: 2
---

## Usage

When using the Picker tool to encapsulate the DUT, use the `-w [wave_file]` option to specify the waveform file to be saved. Different waveform file types are supported for different backend simulators, as follows:

1. [Verilator](https://www.veripool.org/wiki/verilator)
    - `.vcd` format waveform file.
    - `.fst` format waveform file, a more efficient compressed file.
2. [VCS](https://www.synopsys.com/verification/simulation/vcs.html)
    - `.fsdb` format waveform file, a more efficient compressed file.

Note that if you choose to generate the `libDPI_____.so` file yourself, the waveform file format is not restricted by the above constraints. The waveform file format is determined when the simulator constructs `libDPI.so`, so if you generate it yourself, you need to specify the waveform file format using the corresponding simulator's configuration.

### Python Example

Normally, the DUT needs to be **explicitly declared complete** to notify the simulator to perform post-processing tasks (writing waveform, coverage files, etc.). In Python, after completing all tests, **call the `.Finish()` method of the DUT** to notify the simulator that the task is complete, and then flush the files to disk.

Using the [Adder Example](/docs/quick-start/eg-adder/), the test program is as follows:

```python
from Adder import *

if __name__ == "__main__":
    dut = DUTAdder()

    for i in range(10):
        dut.a.value = i * 2
        dut.b.value = int(i / 4)
        dut.Step(1)
        print(dut.sum.value, dut.cout.value)

    dut.Finish() # flush the wave file to disk
```
After the run is completed, the waveform file with the specified name will be generated.


## Viewing Results

### GTKWave

Use GTKWave to open `fst` or `vcd` waveform files to view the waveform.

![GTKWave](GTKwave.png)

### Verdi

Use Verdi to open `fsdb` or `vcd` waveform files to view the waveform.

![Verdi](verdiwave.png)
