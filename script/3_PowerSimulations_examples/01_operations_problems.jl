#jl #! format: off
# # Operations problems with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports the construction and solution of optimal power system
# scheduling problems (Operations Problems). Operations problems form the fundamental
# building blocks for [sequential simulations](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/02_sequential_simulations.ipynb).
# This example shows how to specify and customize a the mathematics that will be applied to the data with
# an `ProblemTemplate`, build and execute an `DecisionModel`, and access the results.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

# ### Optimization packages
using HiGHS # solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/gridmod/rts-gmlc) dataset. Let's
# use [PowerSystemCaseBuilder.jl](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/10_PowerSystemCaseBuilder.ipynb) to download and build a `System`.

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

# ## Define a problem specification with an `ProblemTemplate`
# You can create an empty template with:
template_uc = ProblemTemplate()

# Now, you can add a `DeviceModel` for each device type to create an assignment between PowerSystems device types
# and the subtypes of `AbstractDeviceFormulation`. PowerSimulations has a variety of different
# `AbstractDeviceFormulation` subtypes that can be applied to different PowerSystems device types,
# each dispatching to different methods for populating optimization problem objectives, variables,
# and constraints.

print_tree(PSI.AbstractDeviceFormulation)

# ### Branch Formulations
# Here is an example of relatively standard branch formulations. Other formulations allow
# for selective enforcement of transmission limits and greater control on transformer settings.
set_device_model!(template_uc, Line, StaticBranch)
set_device_model!(template_uc, Transformer2W, StaticBranch)
set_device_model!(template_uc, TapTransformer, StaticBranch)

# ### Injection Device Formulations
# Here we define template entries for all devices that inject or withdraw power on the
# network. For each device type, we can define a distinct `AbstractDeviceFormulation`. In
# this case, we're defining a basic unit commitment model for thermal generators,
# curtailable renewable generators, and fixed dispatch (net-load reduction) formulations
# for `HydroDispatch` and `RenewableFix` devices.

set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
set_device_model!(template_uc, HydroDispatch, FixedOutput)
set_device_model!(template_uc, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template_uc, RenewableFix, FixedOutput)

# ### Service Formulations
# We have two `VariableReserve` types, parameterized by their direction. So, similar to
# creating `DeviceModel`s, we can create `ServiceModel`s. The primary difference being
# that `DeviceModel` objects define how constraints get created, while `ServiceModel` objects
# define how constraints get modified.
set_service_model!(template_uc, VariableReserve{ReserveUp}, RangeReserve)
set_service_model!(template_uc, VariableReserve{ReserveDown}, RangeReserve)

# ### Network Formulations
# Finally, we can define the transmission network specification that we'd like to model. For simplicity, we'll
# choose a copper plate formulation. But there are dozens of specifications available through
# an integration with [PowerModels.jl](https://github.com/lanl-ansi/powermodels.jl). *Note that
# many formulations will require appropriate data and may be computationally intractable*
set_network_model!(template_uc, NetworkModel(CopperPlatePowerModel))

# ## `DecisionModel`
# Now that we have a `System` and an `ProblemTemplate`, we can put the two together
# to create an `DecisionModel` that we solve.

# ### Optimizer
# It's most convenient to define an optimizer instance upfront and pass it into the
# `DecisionModel` constructor. For this example, we can use the free HiGHS solver with a
# relatively relaxed MIP gap (`ratioGap`) setting to improve speed.

solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

# ### Build an `DecisionModel`
# The construction of an `DecisionModel` essentially applies an `ProblemTemplate`
# to `System` data to create a JuMP model.

problem = DecisionModel(template_uc, sys; optimizer = solver, horizon = 24)

build!(problem, output_dir = mktempdir())

#nb # The principal component of the `DecisionModel` is the JuMP model. For small problems,
#nb # you can inspect it by simply printing it to the screen:
#nb # ```julia
#nb # PSI.get_jump_model(problem)
#nb # ```
#nb #
#nb # For anything of reasonable size, that will be unmanageable. But you can print to a file:
#nb # ```julia
#nb # f = open("testmodel.txt","w"); print(f,PSI.get_jump_model(problem)); close(f)
#nb # ```
#nb #
# In addition to the JuMP model, an `DecisionModel` keeps track of a bunch of metadata
# about the problem and some references to pretty names for constraints and variables.
# All of these details are contained within the `optimization_container` field.

print_struct(typeof(PSI.get_optimization_container(problem)))

# ### Solve an `DecisionModel`

solve!(problem)

# ## Results Inspection
# PowerSimulations collects the `DecisionModel` results into a struct:

print_struct(PSI.ProblemResults)

res = ProblemResults(problem);

# ### Optimizer Stats
# The optimizer summary is included

get_optimizer_stats(res)

# ### Objective Function Value

get_objective_value(res)

# ### Variable, Parameter, Auxillary Variable, Dual, and Expression Values
# The solution value data frames for variables, parameters, auxillary variables, duals and
# expressions can be accessed using the `read_` methods:

read_variables(res)

# Or, you can read a single parameter values for parameters that exist in the results.
list_parameter_names(res)
read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableDispatch")

# ## Plotting
# Take a look at the examples in [the plotting folder.](../../notebook/3_PowerSimulations_examples/Plotting)
