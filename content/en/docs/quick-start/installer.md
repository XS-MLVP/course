---
title: Setting Up the Verification Environment
description: Install relevant dependencies, download, build, and install the corresponding tools.
categories: [Tutorial]
tags: [docs]
weight: 1
---

## Source Installation of Picker Tool

### Dependency Installation

1.  [cmake](https://cmake.org/download/) ( >=3.11 )
2.  [gcc](https://gcc.gnu.org/) (Supports c++20, at least version 10, **recommended 11 or above** )
3.  [python3](https://www.python.org/downloads/) ( >=3.8 )
4.  [verilator](https://verilator.org/guide/latest/install.html#git-quick-install) ( **==4.218** )
5.  [verible-verilog-format](https://github.com/chipsalliance/verible) ( >=0.0-3428-gcfcbb82b )
6.  [swig](http://www.swig.org/) ( >=**4.2.0**, for multi-language support)

> Please ensure that the paths of tools like `verible-verilog-format` are added to the environment variable `$PATH` so they can be invoked directly from the command line.

### Download Source Code

```bash
git clone https://github.com/XS-MLVP/picker.git
cd picker
make init
```

### Build and Install

```bash
cd picker
export BUILD_XSPCOMM_SWIG=python # Specify supported language via BUILD_XSPCOMM_SWIG
make
sudo -E make install
```

> The default installation target path is `/usr/local`, with binaries placed in `/usr/local/bin` and template files in `/usr/local/share/picker`.
> The installation will automatically install the `xspcomm` base library, which encapsulates the basic types of `RTL` modules and is located in `/usr/local/lib/libxspcomm.so`. You might **need to manually set the linking directory parameter (-L)** during compilation.
> Additionally, if Python support is enabled, the `xspcomm` Python package will be installed in `/usr/local/share/picker/python/xspcomm/`.
> To generate HTML files for test coverage, you also need to install lcov (genhtml). You can directly install it using apt-get.

### Installation Test

Run the command and check the output:

```bash
➜  picker git:(master) picker
XDut Generate.
Convert DUT(*.v/*.sv) to C++ DUT libs. Notice that [file] option allow only one file.

Usage:
  XDut Gen [file] [OPTION...]

  -f, --filelist arg            DUT .v/.sv source files, contain the top
                                module, split by comma.
                                Or use '*.txt' file  with one RTL file path
                                per line to specify the file list (default:
                                "")
      --sim arg                 vcs or verilator as simulator, default is
                                verilator (default: verilator)
  -l, --language arg            Build example project, default is cpp,
                                choose cpp or python (default: cpp)
  -s, --source_dir arg          Template Files Dir, default is
                                ${picker_install_path}/../picker/template
                                (default: /usr/local/share/picker/template)
  -t, --target_dir arg          Render files to target dir, default is
                                ./picker_out (default: ./picker_out)
  -S, --source_module_name arg  Pick the module in DUT .v file, default is
                                the last module in the -f marked file
                                (default: "")
  -T, --target_module_name arg  Set the module name and file name of target
                                DUT, default is the same as source. For
                                example, -T top, will generate UTtop.cpp
                                and UTtop.hpp with UTtop class (default:
                                "")
      --internal arg            Exported internal signal config file,
                                default is empty, means no internal pin
                                (default: "")
  -F, --frequency arg           Set the frequency of the **only VCS** DUT,
                                default is 100MHz, use Hz, KHz, MHz, GHz as
                                unit (default: 100MHz)
  -w, --wave_file_name arg      Wave file name, emtpy mean don't dump wave
                                (default: "")
  -c, --coverage                Enable coverage, default is not selected as
                                OFF
  -V, --vflag arg               User defined simulator compile args,
                                passthrough. Eg: '-v -x-assign=fast -Wall
                                --trace' || '-C vcs -cc -f filelist.f'
                                (default: "")
  -C, --cflag arg               User defined gcc/clang compile command,
                                passthrough. Eg:'-O3 -std=c++17
                                -I./include' (default: "")
  -v, --verbose                 Verbose mode
  -e, --example                 Build example project, default is OFF
  -h, --help                    Print usage
```

#### Parameter Explanation

* `[file]`: Required. Verilog or SystemVerilog source file of the DUT containing the top module.
* `--filelist, -f`: Optional. Verilog or SystemVerilog source files of the DUT, separated by commas. Alternatively, use a `*.txt` file with one RTL file path per line to specify the file list.
* `--sim`: Optional. Simulator type, can be vcs or verilator, default is verilator.
* `--language, -l`: Optional. Language for building the example project, can be cpp or python, default is cpp.
* `--source_dir, -s`: Optional. Template files directory, default is ${mcv_install_path}/../mcv/template.
* `--target_dir, -t`: Optional. Target directory for rendered files, default is ./mcv_out.
* `--source_module_name, -S`: Optional. Pick the module in the DUT's Verilog file, default is the last module in the file marked with -f.
* `--target_module_name, -T`: Optional. Set the module name and file name of the target DUT, default is the same as the source. For example, -T top will generate UTtop.cpp and UTtop.hpp with UTtop class.
* `--internal`: Optional. Exported internal signal configuration file, default is empty, meaning no internal pins.
* `--frequency, -F`: Optional. Set the frequency of the only VCS DUT, default is 100MHz, can use Hz, KHz, MHz, GHz as units.
* `--wave_file_name, -w`: Optional. Wave file name, empty means don't export waves.
* `--coverage, -c`: Optional. Enable coverage, generates .dat coverage data after test completion.
* `--vflag, -V`: Optional. User-defined simulator compile arguments, passthrough. For example: '-v -x-assign=fast -Wall --trace' or '-f filelist.f'.
* `--cflag, -C`: Optional. User-defined gcc/clang compile arguments, passthrough. For example: '-O3 -std=c++17 -I./include'.
* `--verbose, -v`: Optional. Verbose mode, keeps intermediate files.
* `--example, -e`: Optional. Build example project, default is OFF.
* `--help, -h`: Optional. Print usage help.

### Functional Testing

```bash
cd picker # Enter the project root directory, i.e., the directory where git clone was executed
./example/Adder/release-verilator.sh -l cpp -e
```

The program should output similar content, indicating a successful installation:

```bash
...
[cycle 114515] a=0xa9c430d2942bd554, b=0xe26feda874dac8b7, cin=0x0
DUT: sum=0x8c341e7b09069e0b, cout=0x1
REF: sum=0x8c341e7b09069e0b, cout=0x1
Test Passed, destory UTAdder
...
```

At this point, the Picker tool installation is complete.
