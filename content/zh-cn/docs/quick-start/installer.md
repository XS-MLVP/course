---
title: 搭建验证环境
description: 安装相关依赖，**下载、构建并安装**对应的工具。
categories: [教程]
tags: [docs]
weight: 1
---

## 源码安装Picker工具

### 依赖安装

1.  [cmake](https://cmake.org/download/) ( >=3.11 )
2.  [gcc](https://gcc.gnu.org/) ( 支持c++20,至少为gcc版本10, **建议11及以上** )
3.  [python3](https://www.python.org/downloads/) ( >=3.8 )
4.  [verilator](https://verilator.org/guide/latest/install.html#git-quick-install) ( **>=4.218** )
5.  [verible-verilog-format](https://github.com/chipsalliance/verible) ( >=0.0-3428-gcfcbb82b )
6.  [swig](http://www.swig.org/) ( >=**4.2.0**, 用于多语言支持 )

> 请注意，请确保`verible-verilog-format`等工具的路径已经添加到环境变量`$PATH`中，可以直接命令行调用。

### 下载源码

```bash
git clone https://github.com/XS-MLVP/picker.git --depth=1
cd picker
make init
```

### 构建并安装

```bash
cd picker
make
# 可通过 make BUILD_XSPCOMM_SWIG=python,java,scala,golang 开启其他语言支持。
# 各语言需要自己的开发环境，需要自行配置，例如javac等
sudo -E make install
```

> 默认的安装的目标路径是 `/usr/local`， 二进制文件被置于 `/usr/local/bin`，模板文件被置于 `/usr/local/share/picker`。
> 如果需要修改安装目录，可以通过指定ARGS给cmake传递参数，例如`make ARGS="-DCMAKE_INSTALL_PREFIX=your_instal_dir"`
> 安装时会自动安装 `xspcomm`基础库（[https://github.com/XS-MLVP/xcomm](https://github.com/XS-MLVP/xcomm)），该基础库是用于封装 `RTL` 模块的基础类型，位于 `/usr/local/lib/libxspcomm.so`。 **可能需要手动设置编译时的链接目录参数(-L)**
> 如果开启了Java等语言支持，还会安装 `xspcomm` 对应的多语言软件包。

**picker也可以编译为wheel文件，通过pip安装**

通过以下命令把picker打包成wheel安装包：

```bash
make wheel # or BUILD_XSPCOMM_SWIG=python,java,scala,golang make wheel
```

编译完成后，wheel文件位于dist目录，然后通过pip安装，例如：

```bash
pip install dist/xspcomm-0.0.1-cp311-cp311-linux_x86_64.whl
pip install dist/picker-0.0.1-cp311-cp311-linux_x86_64.whl
```

安装完成后，执行`picker`命令可以得到以下输出:

```
XDut Generate.
Convert DUT(*.v/*.sv) to C++ DUT libs.

Usage: ./build/bin/picker [OPTIONS] [SUBCOMMAND]

Options:
  -h,--help                   Print this help message and exit
  -v,--version                Print version
  --show_default_template_path
                              Print default template path
  --show_xcom_lib_location_cpp
                              Print xspcomm lib and include location
  --show_xcom_lib_location_java
                              Print xspcomm-java.jar location
  --show_xcom_lib_location_scala
                              Print xspcomm-scala.jar location
  --show_xcom_lib_location_python
                              Print python module xspcomm location
  --show_xcom_lib_location_golang
                              Print golang module xspcomm location
  --check                     check install location and supproted languages

Subcommands:
  export                      Export RTL Projects Sources as Software libraries such as C++/Python
  pack                        Pack UVM transaction as a UVM agent and Python class
```

### 安装测试

当前picker有export和pack两个子命令。

export 子命令用于将RTL设计转换成其他高级编程语言对应的“库”，可以通过软件的方式进行驱动。

```bash
picker export --help
```

```plaintext
Export RTL Projects Sources as Software libraries such as C++/Python
Usage: picker export [OPTIONS] file...

Positionals:
  file TEXT ... REQUIRED      DUT .v/.sv source file, contain the top module

Options:
  -h,--help                   Print this help message and exit
  --fs,--filelist TEXT ...    DUT .v/.sv source files, contain the top module, split by comma.
                              Or use '*.txt' file  with one RTL file path per line to specify the file list
  --sim TEXT [verilator]      vcs or verilator as simulator, default is verilator
  --lang,--language TEXT:{python,cpp,java,scala,golang} [python]
                              Build example project, default is python, choose cpp, java or python
  --sdir,--source_dir TEXT    Template Files Dir, default is ${picker_install_path}/../picker/template
  --sname,--source_module_name TEXT ...
                              Pick the module in DUT .v file, default is the last module in the -f marked file
  --tname,--target_module_name TEXT
                              Set the module name and file name of target DUT, default is the same as source.
                              For example, -T top, will generate UTtop.cpp and UTtop.hpp with UTtop class
  --tdir,--target_dir TEXT    Target directory to store all the results. If it ends with '/' or is empty,
                              the directory name will be the same as the target module name
  --internal TEXT             Exported internal signal config file, default is empty, means no internal pin
  -F,--frequency TEXT [100MHz]
                              Set the frequency of the **only VCS** DUT, default is 100MHz, use Hz, KHz, MHz, GHz as unit
  -w,--wave_file_name TEXT    Wave file name, emtpy mean don't dump wave
  -c,--coverage               Enable coverage, default is not selected as OFF
  --cp_lib,--copy_xspcomm_lib BOOLEAN [1]
                              Copy xspcomm lib to generated DUT dir, default is true
  -V,--vflag TEXT             User defined simulator compile args, passthrough.
                              Eg: '-v -x-assign=fast -Wall --trace' || '-C vcs -cc -f filelist.f'
  -C,--cflag TEXT             User defined gcc/clang compile command, passthrough. Eg:'-O3 -std=c++17 -I./include'
  --verbose                   Verbose mode
  -e,--example                Build example project, default is OFF
  --autobuild BOOLEAN [1]     Auto build the generated project, default is true
```

pack子命令用于将UVM中的 sequence_item 转换为其他语言，然后通过TLM进行通信（目前支持Python，其他语言在开发中）

```bash
picker pack --help
```

```plaintext
Pack uvm transaction as a uvm agent and python class
Usage: picker pack [OPTIONS] file...

Positionals:
  file TEXT ... REQUIRED      Sv source file, contain the transaction define

Options:
  -h,--help                   Print this help message and exit
  -e,--example                Generate example project based on transaction, default is OFF
  -c,--force                  Force delete folder when the code has already generated by picker
  -r,--rename TEXT ...        Rename transaction name in picker generate code

```

#### 参数解释
##### export:
*  `file TEXT ... REQUIRED`：必须。位置参数，DUT.v/.sv 源文件，包含顶层模块
* `-h,--help`: 可选。打印此帮助信息并退出
* `--fs,--filelist TEXT ...`: 可选。DUT .v/.sv 源文件，包含顶层模块，逗号分隔。或使用 '*.txt' 文件，每行指定一个 RTL 文件路径来指定文件列表
* `--sim TEXT [verilator]`: 可选。使用 vcs 或 verilator 作为模拟器，默认是 verilator
* `--lang,--language TEXT:{python,cpp,java,scala,golang} [python]`: 可选。构建示例项目，默认是 python，可选择 cpp、java 或 python
* `--sdir,--source_dir TEXT`: 可选。模板文件目录，默认是 ${picker_install_path}/../picker/template
* `--sname,--source_module_name TEXT ...`: 可选。在 DUT .v 文件中选择模块，默认是 -f 标记的文件中的最后一个模块
* `--tname,--target_module_name TEXT`: 可选。设置目标 DUT 的模块名和文件名，默认与源相同。例如，-T top 将生成 UTtop.cpp 和 UTtop.hpp，并包含 UTtop 类
* `--tdir,--target_dir TEXT`: 可选。代码生成渲染文件的目标目录，默认为DUT的模块名。如果该参数以'/'结尾，则在该参数指定的目录中创建以DUT模块名的子目录。
* `--internal TEXT`: 可选。导出的内部信号配置文件，默认为空，表示没有内部引脚
* `-F,--frequency TEXT [100MHz]`: 可选。设置 **仅 VCS** DUT 的频率，默认是 100MHz，可以使用 Hz、KHz、MHz、GHz 作为单位
* `-w,--wave_file_name TEXT`: 可选。波形文件名，空表示不导出波形
* `-c,--coverage`: 可选。启用覆盖率，默认不选择为 OFF
* `--cp_lib,--copy_xspcomm_lib BOOLEAN [1]`: 可选。将 xspcomm 库复制到生成的 DUT 目录，默认是 true
* `-V,--vflag TEXT`: 可选。用户定义的模拟器编译参数，透传。例如：'-v -x-assign=fast -Wall --trace' 或 '-C vcs -cc -f filelist.f'
* `-C,--cflag TEXT`: 可选。用户定义的 gcc/clang 编译命令，透传。例如：'-O3 -std=c++17 -I./include'
* `--verbose`: 可选。详细模式
* `-e,--example`: 可选。构建示例项目，默认是 OFF
* `--autobuild BOOLEAN [1]`: 可选。自动构建生成的项目，默认是 true

静态多模块支持：

picker在生成dut_top.sv/v的封装时，可以通过`--sname`参数指定多个模块名称和对应的数量。例如在a.v和b.v设计文件中分别有模块A和B，需要DUT中有2个A，3个B，生成的模块名称为C（若不指定，默认名称为A_B），则可执行如下命令：

```bash
picker path/a.v,path/b.v --sname A,2,B,3 --tname C
```

环境变量：

- `DUMPVARS_OPTION`: 设置`$dumpvars`的option参数。例如`DUMPVARS_OPTION="+mda" picker ....` 开启vcs中数组波形的支持。
- `SIMULATOR_FLAGS`: 传递给后端仿真器的参数。具体可参考所使用的后端仿真器文档。
- `CFLAGS`: 设置后端仿真器的`-cflags`参数。


##### pack:
* `file`: 必需。待解析的UVM transaction文件
* `--example, -e`: 可选。根据UVM的transaction生成示例项目。
* `--force， -c`: 可选。若已存在picker根据当前transaction解析出的文件，通过该命令可强制删除该文件，并重新生成
* `--rename, -r`: 可选。配置生成文件以及生成的agent的名称，默认为transaction名。

### 测试Examples

编译完成后，在picker目录执行以下命令，进行测试：
```
bash example/Adder/release-verilator.sh --lang cpp
bash example/Adder/release-verilator.sh --lang python

# 默认仅开启 cpp 和 Python 支持
#   支持其他语言编译命令为：make BUILD_XSPCOMM_SWIG=python,java,scala,golang
bash example/Adder/release-verilator.sh --lang java
bash example/Adder/release-verilator.sh --lang scala
bash example/Adder/release-verilator.sh --lang golang

bash example/RandomGenerator/release-verilator.sh --lang cpp
bash example/RandomGenerator/release-verilator.sh --lang python
bash example/RandomGenerator/release-verilator.sh --lang java
```

### 参考材料

如何基于picker进行芯片验证，可参考：[https://open-verify.cc/mlvp/docs/](https://open-verify.cc/mlvp/docs/)
