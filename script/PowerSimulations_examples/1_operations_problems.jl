# # Operations problems with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports the construction and solution of optimal power system
# scheduling problems (Operations Problems). Operations problems form the fundamental
# building blocks for [sequential simulations](../../notebook/PowerSimulations_examples/sequential_simulations.ipynb).
# This example shows how to specify and customize a the mathematics that will be applied to the data with
# an `OperationsProblemTemplate`, build and execute an `OperationsProblem`, and access the results.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using JuMP
using Cbc #solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/grid-mod/rts-gmlc) dataset. Let's
# download and extract the data.

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP");

# ### Create a `System` from RTS-GMLC data just like we did in the [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
rawsys = PowerSystems.PowerSystemTableData(
    rts_src_dir,
    100.0,
    joinpath(rts_siip_dir, "user_descriptors.yaml"),
    timeseries_metadata_file = joinpath(rts_siip_dir, "timeseries_pointers.json"),
    generator_mapping_file = joinpath(rts_siip_dir, "generator_mapping.yaml"),
);

sys = System(rawsys; forecast_resolution = Dates.Hour(1));

# ## Define a problem specification with an `OpModelTemplate`
# The `DeviceModel` constructor is to create an assignment between PowerSystems device types
# and the subtypes of `AbstractDeviceFormulation`. PowerSimulations has a variety of different
# `AbstractDeviceFormulation` subtypes that can be applied to different PowerSystems device types,
# each dispatching to different methods for populating optimization problem objectives, variables,
# and constraints.

#nb TypeTree(PSI.AbstractDeviceFormulation, scopesep="\n")

# ### Branch Formulations
# Here is an example of relatively standard branch formulations. Other formulations allow
# for selective enforcement of transmission limits and greater control on transformer settings.

branches = Dict{Symbol, DeviceModel}(
    :L => DeviceModel(Line, StaticLine),
    :T => DeviceModel(Transformer2W, StaticTransformer),
    :TT => DeviceModel(TapTransformer, StaticTransformer),
)

# ### Injection Device Formulations
# Here we define dictionary entries for all devices that inject or withdraw power on the
# network. For each device type, we can define a distinct `AbstractDeviceFormulation`. In
# this case, we're defining a basic unit commitment model for thermal generators,
# curtailable renewable generators, and fixed dispatch (net-load reduction) formulations
# for `HydroFix` and `RenewableFix` devices. Additionally, we've enabled a simple load
# shedding demand response formulation for `InterruptableLoad` devices.

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
    :ILoads => DeviceModel(InterruptibleLoad, InterruptiblePowerLoad),
)

# ### Service Formulations
# We have two `VariableReserve` types, parameterized by their direction. So, similar to
# creating `DeviceModel`s, we can create `ServiceModel`s. The primary difference being
# that `DeviceModel` objects define how constraints get created, while `ServiceModel` objects
# define how constraints get modified.

services = Dict(
    :ReserveUp => ServiceModel(VariableReserve{ReserveUp}, RangeReserve),
    :ReserveDown => ServiceModel(VariableReserve{ReserveDown}, RangeReserve),
)

# ### Wrap it up into an `OperationsProblemTemplate`
template_uc = OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services);

# ## `OperationsProblem`
# Now that we have a `System` and an `OperationsProblemTemplate`, we can put the two together
# to create an `OperationsProblem` that we solve.

# ### Optimizer
# It's most convenient to define an optimizer instance upfront and pass it into the
# `OperationsProblem` constructor. For this example, we can use the free Cbc solver with a
# relatively relaxed MIP gap (`ratioGap`) setting to improve speed.

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# ### Build an `OperationsProblem`
# The construction of an `OperationsProblem` essentially applies an `OperationsProblemTemplate`
# to `System` data to create a JuMP model.

op_problem =
    OperationsProblem(GenericOpProblem, template_uc, sys; optimizer = solver, horizon = 12)

#nb # The principal component of the `OperationsProblem` is the JuMP model. For small problems,
#nb # you can inspect it by simply printing it to the screen:
#nb # ```julia
#nb # op_problem.psi_container.JuMPmodel
#nb # ```
#nb #
#nb # For anything of reasonable size, that will be unmanageable. But you can print to a file:
#nb # ```julia
#nb # f = open("testmodel.txt","w"); print(f,op_problem.psi_container.JuMPmodel); close(f)
#nb # ```
#nb #
#nb # In addition to the JuMP model, an `OperationsProblem` keeps track of a bunch of metadata
#nb # about the problem and some references to pretty names for constraints and variables.
#nb # All of these details are contained within the `psi_container` field.
#
#nb print_struct(typeof(op_problem.psi_container))
#
#nb # ### Solve an `OperationsProblem`
#
#nb res = solve!(op_problem);
#
#nb # ## Results Inspection
#nb # PowerSimulations collects the `OperationsProblem` results into a struct:
#
#nb print_struct(PSI.SimulationResults)
#
#nb # ### Optimizer Log
#nb # The optimizer summary is included
#
#nb get_optimizer_log(res)
#
#nb # ### Total Cost (objective function value)
#
#nb get_total_cost(res)
#
#nb # ### Variable Values
#nb # The solution value data frames for variable in the `op_problem.psi_container.variables`
#nb # dictionary is stored:
#
#nb variable_values = get_variables(res)
#
#nb # Note that the time stamps are missing from the dataframes in `variable_values`...
#nb #
#nb # The time stamps for each value in the time series used in the `OperationsProblem` is
#nb # included separately from the variable value results.
#
#nb get_time_stamp(res)
#
# ## Plotting
# Take a look at the examples in [the plotting folder.](../../notebook/PowerSimulations_examples/Plotting)
