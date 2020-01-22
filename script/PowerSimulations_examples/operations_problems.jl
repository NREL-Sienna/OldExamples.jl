# # Operations problems with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports the construction and solution of optimal power system 
# scheduling problems (Operations Problems). Opeartions problems form the fundamental
# building blocks for [sequential simulations](../../notebook/PowerSimulations_examples/sequential_simulations.ipynb.)
# This example shows how to specify a the mathematics that will be applied to the data with
# an `OperationsProblemTemplate`, build and execute an `OperationsProblem`, and access the results.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using JuMP
using Cbc #solver

# ### Logging
# Using InfrastructureSystems, we can configure the console and file logging verbosity.
using Logging
logger = IS.configure_logging(console_level = Logging.Info,
                              file_level = Logging.Info,
                              filename = "op_problem_log.txt")

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/grid-mod/rts-gmlc) dataset. Let's 
# download and extract the data.

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP")


# ### Create a `System` from RTS-GMLC data just like we did in the [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
rawsys = PSY.PowerSystemTableData(rts_src_dir,
                                  100.0,
                                  joinpath(rts_siip_dir,"user_descriptors.yaml"),
                                  timeseries_metadata_file = joinpath(rts_siip_dir,"timeseries_pointers.json"),
                                  generator_mapping_file = joinpath(rts_siip_dir,"generator_mapping.yaml"));

sys = System(rawsys; forecast_resolution = Dates.Hour(1));

# ## Define a problem specification with an `OpModelTemplate`
# The `DeviceModel` constructor is to create an assignment between PowerSystems device types
# and the subtypes of `AbstractDeviceFormulation`. PowerSimulations has a variety of different 
# `AbstractDeviceFormulation` subtypes that can be applied to different PowerSystems device types, 
# each dispatching to different methods for populating optimization problem objectives, variables,
# and constraints.

DisplayTypeTree(PSI.AbstractDeviceFormulation, scopesep="\n")

# ### Branch Formulations
# 
branches = Dict{Symbol, DeviceModel}(:L => DeviceModel(Line, StaticLine),
                                     :T => DeviceModel(Transformer2W, StaticTransformer),
                                     :TT => DeviceModel(TapTransformer , StaticTransformer))
# ### Injection Device Formulations
# 
devices = Dict(:Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
                                    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
                                    :Loads =>  DeviceModel(PowerLoad, StaticPowerLoad),
                                    :HydroROR => DeviceModel(HydroFix, HydroFixed),
                                    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
                                    #:ILoads =>  DeviceModel(InterruptibleLoad, StaticPowerLoad),
                                    )

# ### Service Formulations
services = Dict(:ReserveUp => ServiceModel(VariableReserve{ReserveUp}, RangeReserve),
                :ReserveDown => ServiceModel(VariableReserve{ReserveDown}, RangeReserve))

# ### Wrap it up into an `OperationsProblemTemplate`
template_uc= OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services);

# ## `OperationsProblem`
# Now that we have a `System` and an `OperationsProblemTemplate`, we can put the two together
# to create an `OperationsProblem` that we solve. 

# ### Optimizer
# It's most convienent to define an optimizer instance upfront and pass it into the 
# `OperationsProblem` constructor. For this example, we can use the free Cbc solver with a
# relatively relaxed MIP gap (`ratioGap`) setting to improve speed.

Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=1, ratioGap=0.5)

# ### Build an `OperationsProblem`
# The construction of an `OperationsProblem` essentially applies an `OperationsProblemTemplate`
# to `System` data to create a JuMP model.

op_problem = OperationsProblem(GenericOpProblem, 
                               template_uc, 
                               sys; 
                               optimizer = Cbc_optimizer, 
                               horizon = 12)

# The principal component of the `OperationsProblem` is the JuMP model. For small problems, 
# you can inspect it by simply printing it to the screen:
# ```julia
# op_problem.psi_container.JuMPmodel
# ```
# 
# For anything of reasonable size, that will be unmanagable. But you can print to a file:
# ```julia
# f = open("testmodel.txt","w"); print(f,op_problem.psi_container.JuMPmodel); close(f)
# ```
# 
# In additon to the JuMP model, an `OperationsProblem` keeps track of a bunch of metadata 
# about the problem and some references to pretty nammes for constraints and variables. 
# All of these details are contained within the `psi_container` field.

print_struct(typeof(op_problem.psi_container))

# ### Solve an `OperationsProblem`

res = solve_op_problem!(op_problem);

# ## Results Inspection
# PowerSimulations collects the `OperationsProblem` results into a struct:

print_struct(PSI.SimulationResults)

# ### Optimizer Log
# The optimizer summary is included

res.optimizer_log

# ### Total Cost (objective function value)

res.total_cost

# ### Variable Values
# The solution value data frames for variable in the `op_problem.psi_container.variables` 
# dictionary is stored:

res.variables

# For example, we can look at the values for the `:P_ThermalStandard`

res.variables[:P_ThermalStandard]

# Note that the time stamps are missing...
# 
# The time stamps for each value in the time series used in the `OperationsProblem` is 
# included seperately from the variable value results.

res.time_stamp

# ## Plotting
# PowerSimulaitons also provides some basic specifications for plotting `SimulationResults`.
# 
# The plotting capabilities depend on the Julia Plots package.
using Plots
plotly();

# ### Bar Plots
# We can create a stacked bar plot for any combination of variables to summarize values over 
# all time periods.

bar_plot(res, [:P_ThermalStandard,:P_RenewableDispatch])

# ### Stack Plots
# Similarly, we can create a stack plot for any combination of variable to see the time 
# series values.

# ```stack_plot(res, [:P_ThermalStandard,:P_RenewableDispatch])```

# Or, we can create a series of stack plots for every variable in the dictionary:
# ```julia
# stack_plot(res)
# ```


# ### Log file
# Remember the logger that we defined in [the logging section](#Logging). You can look at
# the [log file](./op_problem_log.txt) that we created. *Sometimes you need to flush the
# logger to get the latest output to populate to the log file. You can do so by running:*

flush(logger)
