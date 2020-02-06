# SIIPExamples.jl [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/Examples/master) [![Build Status](https://travis-ci.org/NREL-SIIP/Examples.svg?branch=master)](https://travis-ci.org/NREL-SIIP/Examples)


This repository contains examples and tutorials for Scalable Integrated Infrastructure Planning (SIIP) packages developed at the [National Renewable Energy Laboratory (NREL)](nrel.gov). This repository uses a template established by [JuMPTutorials.jl](https://github.com/JuliaOpt/JuMPTutorials.jl).

## Run Notebooks in the Browser
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/Examples/master)

To try out any of the tutorials in the browser without downloading Julia, click on the launch binder button above. Note that this functionality only supports open-source solvers which do not have additional requirements (for e.g. BLAS or MATLAB). This is also very slow and can take several minutes to start as it has to first install Julia and all the dependencies. Thus, you should download and run the notebooks on your local machine for the best experience.

## Table of Contents

- Introduction
  - [An Introduction to Julia](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/introduction/an_introduction_to_julia.ipynb)
- [PowerSystems.jl](gihtub.com/NREL/PowerSystems.jl) Examples
  - [PowerSystems.jl Intro](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSystems_examples/PowerSystems_intro.ipynb)
  - Data Parsing:
    - [MATPOWER](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSystems_examples/parse_matpower.ipynb)
    - [PSS/E](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSystems_examples/parse_psse.ipynb)
    - [Tabular Data Parsing](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSystems_examples/parse_tabulardata.ipynb)
  - [Serialize data](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSystems_examples/serialize_data.ipynb)
- [PowerSimulations.jl](github.com/NREL/PowerSimulations.jl) Examples
  - [Single Step UC RTS Example](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSimulationss_examples/operations_problems.ipynb)
  - [Sequential DA-RT RTS Example](https://nbviewer.jupyter.org/github/nrel-siip/examples/blob/master/notebook/PowerSimulationss_examples/sequential_simulations.ipynb)
  - Hydro Modeling *TODO*
