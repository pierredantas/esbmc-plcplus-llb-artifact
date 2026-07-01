<!--
    Copyright (C) 2024 Antonio Iacobelli, Lorenzo Rinieri

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>. 
-->

# PLC-Defuser

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14014820.svg)](https://doi.org/10.5281/zenodo.14014820)


This repository contains the code and the dataset for the paper "PLC-Defuser: Detecting Hidden Ladder Logic Bombs in PLCs via Control Flow Graph and Model Checking".

### Datasets

Currently, we developed three datasets of PLC logic controlling the following physical processes:

* [Tennessee Eastman Process](https://github.com/Fortiphyd/GRFICSv2) (`GRFICS`)
* [Secure Water Treatment Plant](https://itrust.sutd.edu.sg/testbeds/secure-water-treatment-swat/) (`SWAT`)
* [Water Tank](https://ieeexplore.ieee.org/abstract/document/10639995) (`Water_tank`)

### Code

Our work code is located in the `project` folder, which contains the following folders:

* `malicious`: it contains the formal model of the SWAT program, which includes a logic bomb
* `legitimate`: it contains the formal model of the original SWAT program, which doesn't include a logic bomb
* `intrepyd`: it contains the intrepyd libraries (https://github.com/formalmethods/intrepid)
* `utils`: it contains the scripts that check the model meets our paper's requirements

#### How to verify requirements of the SWAT program

```
git clone https://github.com/UniboSecurityResearch/PLC_Defuser.git
cd PLC_Defuser/project
docker build -t plc-defuser .
docker run plc-defuser
```

N.B. Docker checks the requirements of the malicious program by default. To check the requirements of the legitimate program, change the program to be executed in the Dockerfile: `malicious/check_requirements.py` to `legitimate/check_requirements.py`

### Cite us

If you find this work interesting and use it in your academic research, please cite our paper!

```bibtex
@article{rinieri2026plc,
  title={PLC-Defuser: Detecting hidden Ladder Logic Bombs in PLCs via Control Flow Graph and model checking},
  author={Rinieri, Lorenzo and Iacobelli, Antonio and Melis, Andrea and Prandini, Marco and Callegati, Franco},
  journal={Computers \& Security},
  pages={104983},
  year={2026},
  publisher={Elsevier}
}
```
