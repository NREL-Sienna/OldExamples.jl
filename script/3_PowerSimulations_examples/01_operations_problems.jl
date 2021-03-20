# # Operations problems with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports the construction and solution of optimal power system
# scheduling problems (Operations Problems). Operations problems form the fundamental
# building blocks for [sequential simulations](../../notebook/3_PowerSimulations_examples/sequential_simulations.ipynb).
# This example shows how to specify and customize a the mathematics that will be applied to the data with
# an `OperationsProblemTemplate`, build and execute an `OperationsProblem`, and access the results.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using Cbc #solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/gridmod/rts-gmlc) dataset. Let's
# use [PowerSystemCaseBuilder.jl](../../notebook/2_PowerSystems_examples/10_PowerSystemCaseBuilder.ipynb) to download and build a `System`.

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

# ## Define a problem specification with an `OperationsProblemTemplate`
# You can create an empty template with:
template_uc = OperationsProblemTemplate()

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
set_transmission_model!(template_uc, CopperPlatePowerModel)

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

op_problem = OperationsProblem(template_uc, sys; optimizer = solver, horizon = 24)

build!(op_problem, output_dir = mktempdir())

#nb # The principal component of the `OperationsProblem` is the JuMP model. For small problems,
#nb # you can inspect it by simply printing it to the screen:
#nb # ```julia
#nb # op_problem.internal.optimization_container.JuMPmodel
#nb # ```
#nb #
#nb # For anything of reasonable size, that will be unmanageable. But you can print to a file:
#nb # ```julia
#nb # f = open("testmodel.txt","w"); print(f,op_problem.internal.optimization_container.JuMPmodel); close(f)
#nb # ```
#nb #
#nb # In addition to the JuMP model, an `OperationsProblem` keeps track of a bunch of metadata
#nb # about the problem and some references to pretty names for constraints and variables.
#nb # All of these details are contained within the `optimization_container` field.
#
#nb print_struct(typeof(op_problem.internal.optimization_container))
#
#nb # ### Solve an `OperationsProblem`
#
#nb solve!(op_problem)
#
#nb # ## Results Inspection
#nb # PowerSimulations collects the `OperationsProblem` results into a struct:
#
#nb print_struct(PSI.ProblemResults)
#
#nb res = ProblemResults(op_problem);
#
#nb # ### Optimizer Stats
#nb # The optimizer summary is included
#
#nb get_optimizer_stats(res)
#
#nb # ### Objective Function Value
#
#nb get_objective_value(res)
#
#nb # ### Variable Values
#nb # The solution value data frames for variables can be accessed by:
#
#nb variable_values = get_variables(res)
#
# ## Plotting
# Take a look at the examples in [the plotting folder.](../../notebook/3_PowerSimulations_examples/Plotting)
