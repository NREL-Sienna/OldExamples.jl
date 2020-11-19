# SIIPExamples.jl [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/master) [![Build Status](https://travis-ci.org/NREL-SIIP/SIIPExamples.jl.svg?branch=master)](https://travis-ci.org/NREL-SIIP/SIIPExamples.jl)
[<img src="https://img.shields.io/badge/slack-@SIIP/Examples-blue.svg?logo=slack">](https://join.slack.com/t/nrel-siip/shared_invite/zt-glam9vdu-o8A9TwZTZqqNTKHa7q3BpQ)

This repository contains examples and tutorials for [Scalable Integrated Infrastructure Planning (SIIP) packages developed at the National Renewable Energy Laboratory (NREL)](https://www.nrel.gov/analysis/siip.html). This repository uses a template established by [JuMPTutorials.jl](https://github.com/JuliaOpt/JuMPTutorials.jl).

The examples in this repository are intended as practical examples of using [SIIP packages](https://github.com/nrel-siip). However,
in many cases users may find the documentation pages for each package more informative:

 - [InfrastructureSystems.jl docs](https://nrel-siip.github.io/InfrastructureSystems.jl/stable/)
 - [PowerSystems.jl docs](https://nrel-siip.github.io/PowerSystems.jl/stable/)
 - [PowerSimulations.jl docs](https://nrel-siip.github.io/PowerSimulations.jl/latest/)
 - [PowerGraphics.jl docs](https://nrel-siip.github.io/PowerGraphics.jl/latest/)

## Run Notebooks in the Browser
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/master)

To try out any of the tutorials in the browser without downloading Julia, click on the launch binder button above. Note that this functionality only supports open-source solvers which do not have additional requirements (for e.g. BLAS or MATLAB). This is also very slow and can take several minutes to start as it has to first install Julia and all the dependencies. Thus, you should download and run the notebooks on your local machine for the best experience.

## Run Notebooks on your local computer

_Prerequisites:_
 - Install [Julia](https://julialang.org)
 - Download and extract or clone (via [git](https://git-scm.com)) the code in this repository

To get started running the Jupyter notebooks included in this repository, you can follow the process in [this video](https://www.youtube.com/watch?v=n1NvcnLczJ8&feature=youtu.be) demonstrating the following steps:

1. Install IJulia: `using Pkg; Pkg.add("IJulia")`
2. Instantiate the SIIPExamples.jl environment (_note:_ this can take 30+ minutes the first time you run): `Pkg.activate("path/to/SIIPExamples.jl/."); Pkg.instantiate()`
3. Launch a notebook server: `using IJulia; notebook(dir = "path/to/SIIPExamples/notebook")`

## Table of Contents

- Introduction
  - [An Introduction to Julia](https://nbviewer.jupyter.org/github/nrel-siip/SIIPExamples.jl/blob/master/notebook/1_introduction/an_introduction_to_julia.ipynb)
- [PowerSystems.jl](gihtub.com/NREL-SIIP/PowerSystems.jl) SIIPExamples.jl
  - [PowerSystems.jl Intro](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/PowerSystems_intro.ipynb)
  - Data Parsing:
    - [MATPOWER](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/parse_matpower.ipynb)
    - [PSS/E](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/parse_psse.ipynb)
    - [Tabular Data Parsing](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/parse_tabulardata.ipynb)
    - [Adding Time Series Data to a System](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/add_forecasts.ipynb)
  - [Serialize data](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/serialize_data.ipynb)
  - [Network Matrices](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/network_matrices.ipynb)
  - [Large-scale U.S. dataset assembly](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/US_system.ipynb)
- [PowerSimulations.jl](github.com/NREL-SIIP/PowerSimulations.jl) Examples
  - [Single Step UC RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
  - [Sequential DA-RT RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/02_sequential_simulations.ipynb)
  - [Hydro Modeling](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/05_hydropower_simulation.ipynb)
  - [Sequential DA-RT 5bus Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/03_PowerSimulations_examples/03_5_bus_mkt_simulation.ipynb)
  - [ACOPF Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/06_ACOPF.ipynb)
  - [Selective Line Enforcement Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/07_selective_network_constraints.ipynb)
  - [Simulations with large-scale U.S. systems](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/08_US-system-simulations.ipynb)
  - [Simulations with TAMU test systems](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/09_TAMU_simulations.ipynb)
  - [Simulating Time Varying Market Bids](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/10_market_bid_cost.ipynb)
  - [PTDF Network and LMP Calculations](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/11.ipynb)
  - Plotting with [PowerGraphics.jl](github.com/NREL-SIIP/PowerGraphics.jl)
    - [Bar and Stack Plots](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/04_bar_stack_plots.ipynb)
