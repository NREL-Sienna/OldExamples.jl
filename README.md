# SIIPExamples.jl
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/master)
[![Master - CI](https://github.com/NREL-SIIP/SIIPExamples.jl/workflows/Master%20-%20CI/badge.svg)](https://github.com/NREL-SIIP/SIIPExamples.jl/actions/workflows/master-tests.yml)
[<img src="https://img.shields.io/badge/slack-@SIIP/Examples-blue.svg?logo=slack">](https://join.slack.com/t/nrel-siip/shared_invite/zt-glam9vdu-o8A9TwZTZqqNTKHa7q3BpQ)

This package contains examples and tutorials for [Scalable Integrated Infrastructure Planning (SIIP) packages developed at the National Renewable Energy Laboratory (NREL)](https://www.nrel.gov/analysis/siip.html). This repository uses a template established by [JuMPTutorials.jl](https://github.com/JuliaOpt/JuMPTutorials.jl).

The examples included here are intended as practical examples of using [SIIP packages](https://github.com/nrel-siip). However,
in many cases users may find the documentation pages for each package more informative:

- [InfrastructureSystems.jl docs](https://nrel-siip.github.io/InfrastructureSystems.jl/stable/)
- [PowerSystems.jl docs](https://nrel-siip.github.io/PowerSystems.jl/stable/)
- [PowerSimulations.jl docs](https://nrel-siip.github.io/PowerSimulations.jl/stable/)
- [PowerGraphics.jl docs](https://nrel-siip.github.io/PowerGraphics.jl/stable/)
- [PowerSimulationsDynamics.jl docs](https://nrel-siip.github.io/PowerSimulationsDynamics.jl/stable/)

## Run Notebooks in the Browser

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL-SIIP/SIIPExamples.jl/notebook)

To try out any of the tutorials in the browser without downloading Julia, click on the launch binder button above. Note that this functionality only supports open-source solvers which do not have additional requirements (for e.g. BLAS or MATLAB). This is also very slow and can take several minutes to start as it has to first install Julia and all the dependencies. Thus, you should download and run the notebooks on your local machine for the best experience.

## Run Notebooks on your local computer

_Prerequisites:_

- Install [Julia](https://julialang.org)

To get started running the Jupyter notebooks included in this package, you can follow the process in [this video](https://www.youtube.com/watch?v=n1NvcnLczJ8&feature=youtu.be) demonstrating the following steps:

1. Install SIIPExamples: `using Pkg; Pkg.add("SIIPExamples")`
2. Launch a notebook server for any of the example categories (`JuliaExamples, PSYExamples, PSIExamples, PSDExamples`): `notebook(PSYExamples)`

## Table of Contents

- Introduction
  - [An Introduction to Julia](https://nbviewer.jupyter.org/github/nrel-siip/SIIPExamples.jl/blob/notebook/1_introduction/an_introduction_to_julia.ipynb)
- [PowerSystems.jl](https://github.com/NREL-SIIP/PowerSystems.jl) Examples
  - [PowerSystems.jl Intro](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/01_PowerSystems_intro.ipynb)
  - Data Parsing:
    - [MATPOWER](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/02_parse_matpower.ipynb)
    - [PSS/E](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/03_parse_psse.ipynb)
    - [Tabular Data Parsing](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/04_parse_tabulardata.ipynb)
    - [Adding Time Series Data to a System](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/05_add_forecasts.ipynb)
  - [Serialize data](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/06_serialize_data.ipynb)
  - [Network Matrices](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/07_network_matrices.ipynb)
  - [Large-scale U.S. dataset assembly](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/08_US_system.ipynb)
  - [Loading Dynamic System Data](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/09_loading_dynamic_systems_data.ipynb)
  - Managing systems with [PowerSystemCaseBuilder.jl](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/2_PowerSystems_examples/10_PowerSystemCaseBuilder.ipynb)
- [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) Examples
  - [Single Step UC RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
  - [Sequential DA-RT RTS Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/02_sequential_simulations.ipynb)
  - [Hydro Modeling](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/05_hydropower_simulation.ipynb)
  - [Sequential DA-RT 5bus Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/03_5_bus_mkt_simulation.ipynb)
  - [ACOPF Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/06_ACOPF.ipynb)
  - [Selective Line Enforcement Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/07_selective_network_constraints.ipynb)
  - [Simulations with large-scale U.S. systems](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/08_US-system-simulations.ipynb)
  - [Simulations with TAMU test systems](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/09_tamu_simulation.ipynb)
  - [Simulating Time Varying Market Bids](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/10_market_bid_cost.ipynb)
  - [PTDF Network and LMP Calculations](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/11_PTDF.ipynb)
  - Plotting with [PowerGraphics.jl](https://github.com/NREL-SIIP/PowerGraphics.jl)
    - [Bar and Stack Plots](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/3_PowerSimulations_examples/04_bar_stack_plots.ipynb)
- [PowerSimulationsDynamics.jl](https://github.com/NREL-SIIP/PowerSimulationsDynamics.jl) Examples
  - [One Machine Infinite Bus](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/4_PowerSimulationsDynamics_examples/01_omib.ipynb)
  - [Line Dynamics](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/4_PowerSimulationsDynamics_examples/02_line_dynamics.ipynb)
  - [Inverter Model](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/4_PowerSimulationsDynamics_examples/03_inverter_model.ipynb)
  - [WECC240 Bus](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/notebook/4_PowerSimulationsDynamics_examples/04_240BusWECC_sim.ipynb)

## Debugging

On occasion, you may have constructed a `System` using PowerSystemsCaseBuilder.jl that needs
to be reconstructed. In this case, you may receive an error such as:

```julia
ERROR: UndefVarError: PowerSystems.ReserveUp not defined
```

To resolve this issue, you can purge the serialized system data from your
PowerSystemsCaseBuilder.jl instance by running:

```julia
using PowerSystemCaseBuilder
PowerSystemCaseBuilder.clear_all_serialized_system()
```
