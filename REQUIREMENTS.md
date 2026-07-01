# Requirements & build

## Software
- Linux or macOS, Python 3.8+, `git`, a C++17 toolchain + CMake/Ninja (to build ESBMC).
- The **ESBMC-PLC+** source/artifact (the verification engine this work uses):
  Zenodo `10.5281/zenodo.20786920` / the ESBMC repository.

## Build the engine with the modeling layer
The contribution is `src/modeling_layer.patch`, applied to the ESBMC-PLC+ LD frontend
(`src/ld-frontend/...`, plus a one-line LLVM-compat fix in
`src/clang-c-frontend/clang_c_lexer.cpp`). The verification backend is **not** changed.

```bash
# in the ESBMC-PLC+ source tree:
git apply /path/to/artifact/src/modeling_layer.patch
# build (existing ESBMC build instructions; e.g. with an existing build dir):
cmake --build build --target esbmc -j8
export ESBMC=$PWD/build/src/esbmc/esbmc
```
The patch adds: `src/ld-frontend/ir_gen/st_fb_translator.{h,cpp}` (new) and edits to
`ld_ast.h`, `plcopen_xml_parser.cpp`, `ld_ir.h`, `ld_ir_builder.cpp`, `ld_converter.{h,cpp}`,
`type_checker.cpp`, `CMakeLists.txt`.

## Datasets (fetched automatically by `scripts/00_fetch_datasets.sh`)
- Iacobelli et al. `PLC-LD-dataset` (Water_tank, 30+30) — GitHub `UniboSecurityResearch`.
- PLC-Defuser datasets (SWaT 150+150, GRFICS, Water_tank) — GitHub
  `UniboSecurityResearch/PLC_Defuser`, Zenodo `10.5281/zenodo.14014820`.

## Verifying the build
After `export ESBMC=...`, the dataset-free PoC should pass without any download:
```bash
bash corpora/poc/families/gen_run_families.sh   # 6 FB bombs: legit SAFE / malicious VIOLATION
```
If `--ld-props` is unrecognised, the ESBMC binary is upstream ESBMC, not the ESBMC-PLC+
build — rebuild from the ESBMC-PLC+ source with the patch.
