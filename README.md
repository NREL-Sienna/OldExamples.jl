# SIIPExamples.jl [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/master) [![Build Status](https://travis-ci.org/NREL-SIIP/SIIPExamples.jl.svg?branch=master)](https://travis-ci.org/NREL-SIIP/SIIPExamples.jl)


This repository contains examples and tutorials for Scalable Integrated Infrastructure Planning (SIIP) packages developed at the [National Renewable Energy Laboratory (NREL)](nrel.gov). This repository uses a template established by [JuMPTutorials.jl](https://github.com/JuliaOpt/JuMPTutorials.jl).

## Run Notebooks in the Browser
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/master)

To try out any of the tutorials in the browser without downloading Julia, click on the launch binder button above. Note that this functionality only supports open-source solvers which do not have additional requirements (for e.g. BLAS or MATLAB). This is also very slow and can take several minutes to start as it has to first install Julia and all the dependencies. Thus, you should download and run the notebooks on your local machine for the best experience.

## Table of Contents

- Introduction
  - [An Introduction to Julia](https://nbviewer.jupyter.org/github/nrel-siip/SIIPExamples.jl/blob/master/notebook/introduction/an_introduction_to_julia.ipynb)
- [PowerSystems.jl](gihtub.com/NREL/PowerSystems.jl) SIIPExamples.jl
  - [PowerSystems.jl Intro](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/PowerSystems_intro.ipynb)
  - Data Parsing:
    - [MATPOWER](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/parse_matpower.ipynb)
    - [PSS/E](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/parse_psse.ipynb)
    - [Tabular Data Parsing](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/parse_tabulardata.ipynb)
  - [Serialize data](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/serialize_data.ipynb)
  - [Network Matrices](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSystems_examples/network_matrices.ipynb)
- [PowerSimulations.jl](github.com/NREL-SIIP/PowerSimulations.jl) Examples
  - [Single Step UC RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/1_operations_problems.ipynb)
  - [Sequential DA-RT RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/2_sequential_simulations.ipynb)
  - [Hydro Modeling](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/5_hydropower_simulation.ipynb)
  - [Sequential DA-RT 5bus Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/3_5_bus_mkt_simulation.ipynb)
  - [ACOPF Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/6_ACOPF.ipynb)
  - Plotting with [PowerGraphics.jl](github.com/NREL-SIIP/PowerGraphics.jl)
    - [Bar and Stack Plots](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/PowerSimulations_examples/4_bar_stack_plots.ipynb)
