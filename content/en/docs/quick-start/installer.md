---

title: Setting Up the Verification Environment
description: Install the necessary dependencies, **download, build, and install**  the required tools.
categories: [Tutorials]
tags: [docs]
weight: 1

---


## Installing the Picker Tool from Source 

### Installing Dependencies 
 
1. [cmake](https://cmake.org/download/)  ( >=3.11 )
 
2. [gcc](https://gcc.gnu.org/)  ( Supports C++20, at least GCC version 10, **recommended 11 or higher**  )
 
3. [python3](https://www.python.org/downloads/)  ( >=3.8 )
 
4. [verilator](https://verilator.org/guide/latest/install.html#git-quick-install)  ( **==4.218**  )
 
5. [verible-verilog-format](https://github.com/chipsalliance/verible)  ( >=0.0-3428-gcfcbb82b )
 
6. [swig](http://www.swig.org/)  ( >=**4.2.0** , for multi-language support )

> Please ensure that the tools like `verible-verilog-format` have been added to the environment variable `$PATH`, so they can be called directly from the command line.
### Downloading the Source Code 


```bash
git clone https://github.com/XS-MLVP/picker.git
cd picker
make init
```

### Building and Installing 


```bash
cd picker
make
# You can enable other language support via make BUILD_XSPCOMM_SWIG=python,java,scala,golang.
# Each language requires its development environment, which needs to be configured separately, such as javac, etc.
sudo -E make install
```

> The default installation target path is /usr/local, binary files are placed in /usr/local/bin, and template files are located in /usr/local/share/picker.
The installation will automatically install the xspcomm base library ([https://github.com/XS-MLVP/xcomm](https://github.com/XS-MLVP/xcomm) ), which is used to encapsulate basic types of RTL modules, located at /usr/local/lib/libxspcomm.so. You may need to manually set the link directory parameter (-L) during compilation.
If Java or other language support is enabled, corresponding multi-language packages for xspcomm will also be installed.
### Installation Test 

Run the command and check the output:

> picker export --help

```bash
Export RTL Projects Sources as Software libraries such as C++/Python Usage: picker
export [OPTIONS] file

Positionals:
  file TEXT REQUIRED          DUT .v/.sv source file, contain the top module

Options:
  -h,--help                   Print this help message and exit
  --fs,--filelist TEXT        DUT .v/.sv source files, contain the top module, 
                              split by comma. Or use '*.txt' file  with one RTL 
                              file path per line to specify the file list
  --sim TEXT [verilator]      vcs or verilator as simulator, default is verilator
  --lang,--language TEXT:{python,cpp,java,scala,golang} [python] 
                              Build example project, default is python, choose 
                              cpp, java or python
  --sdir,--source_dir TEXT [/usr/local/share/picker/template] 
                              Template Files Dir, default is ${picker_install_path}/../picker/template
  --tdir,--target_dir TEXT [./picker_out] 
                              Codegen render files to target dir, default is ./picker_out
  --sname,--source_module_name TEXT
                              Pick the module in DUT .v file, default is the last 
                              module in the --fs marked file
  --tname,--target_module_name TEXT
                              Set the module name and file name of target DUT, 
                              default is the same as source. For example, --tname top, 
                              will generate UTtop.cpp and UTtop.hpp with UTtop class
  --internal TEXT             Exported internal signal config file, default is empty, 
                              means no internal pin
  -F,--frequency TEXT [100MHz] 
                              Set the frequency of the **only VCS** DUT, default 
                              is 100MHz, use Hz, KHz, MHz, GHz as unit
  -w,--wave_file_name TEXT    Wave file name, emtpy mean don't dump wave
  -c,--coverage               Enable coverage, default is not selected as OFF
  -V,--vflag TEXT             User defined simulator compile args, passthrough. 
                              Eg: '-v -x-assign=fast -Wall --trace' || '-C vcs -cc -f filelist.f'
  -C,--cflag TEXT             User defined gcc/clang compile command, passthrough. 
                              Eg:'-O3 -std=c++17 -I./include'
  --verbose                   Verbose mode
  -e,--example                Build example project, default is OFF
  --autobuild BOOLEAN [1]     Auto build the generated project, default is true
```

#### Explanation of Parameters 
 
- `[file]`: Required. Verilog or SystemVerilog source file of the DUT, containing the top module.
 
- `--filelist, -fs`: Optional. Verilog or SystemVerilog source files of the DUT, separated by commas. Alternatively, you can use a `*.txt` file, specifying one RTL file path per line, to define the file list.
 
- `--sim`: Optional. Simulator type, can be vcs or verilator, default is verilator.
 
- `--language, --lang`: Optional. Language for building the example project, can be cpp or python, default is cpp.
 
- `--source_dir, -sdir`: Optional. Template files directory, default is ${mcv_install_path}/../mcv/template.
 
- `--target_dir, -tdir`: Optional. Target directory for rendering files, default is ./mcv_out.
 
- `--source_module_name, -sname`: Optional. Selects a module in the DUT's Verilog file, default is the last module in the file marked by --fs.
 
- `--target_module_name, -tname`: Optional. Sets the target DUT's module name and file name, default is the same as the source. For example, --tname top will generate UTtop.cpp and UTtop.hpp with the UTtop class.
 
- `--internal`: Optional. Exported internal signal configuration file, default is empty, meaning no internal pin.
 
- `--frequency, -F`: Optional. Sets the frequency of the **only VCS**  DUT, default is 100MHz, using Hz, KHz, MHz, GHz as units.
 
- `--wave_file_name, -w`: Optional. Waveform file name, empty means no waveform dump.
 
- `--coverage, -c`: Optional. Enables coverage, default is OFF.
 
- `--vflag, -V`: Optional. User-defined simulator compile arguments, passthrough. Example: '-v -x-assign=fast -Wall --trace' or '-f filelist.f'.
 
- `--cflag, -C`: Optional. User-defined gcc/clang compile commands, passthrough. Example: '-O3 -std=c++17 -I./include'.
 
- `--verbose, -v`: Optional. Verbose mode, retains intermediate files.
 
- `--example, -e`: Optional. Builds the example project, default is OFF.
 
- `--autobuild`: Optional. Automatically builds the generated project, default is true.
 
- `--help, -h`: Optional. Prints usage help.

### Installation Check 

You can check the Picker installation with the --check parameter, which will output the supported programming languages and their corresponding dependency locations.

> picker --check

```bash
[OK ] Version: 0.1.0-develop-e3b38d5
[OK ] Exec path: /usr/local/bin/picker
[OK ] Template path: /usr/local/share/picker/template
[OK ] Support    Cpp (find: '/usr/local/share/picker/include' success)
[OK ] Support   Java (find: '/usr/local/share/picker/java/xspcomm-java.jar' success)
[Err] Support  Scala (find: 'scala/xspcomm-scala.jar' fail)
[OK ] Support Python (find: '/usr/local/share/picker/python' success)
[OK ] Support Golang (find: '/usr/local/share/picker/golang' success)
```

### Functionality Test 


```bash
cd picker # Enter the project root directory, i.e., the directory where git clone was executed
bash example/Adder/release-verilator.sh --lang cpp
```
The program should output **similar**  content, indicating a successful installation:

```bash
...
[cycle 114515] a=0xa9c430d2942bd554, b=0xe26feda874dac8b7, cin=0x0
DUT: sum=0x8c341e7b09069e0b, cout=0x1
REF: sum=0x8c341e7b09069e0b, cout=0x1
Test Passed, destroy UTAdder
...
```

At this point, the Picker tool installation is complete.