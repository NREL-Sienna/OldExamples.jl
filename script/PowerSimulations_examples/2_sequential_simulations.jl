# # Sequential Simulations with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways. This
# example demonstrates some of these capabilities to represent electricity market clearing.

# ## Dependencies
# Since the `OperatiotnsProblem` is the fundamental building block of a sequential
# simulation in PowerSimulations, we will build on the [OperationsProblem example](../../notebook/PowerSimulations_examples/1_operations_problems.ipynb)
# by sourcing it as a dependency.
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSimulations_examples", "1_operations_problems.jl"))

# ### 5-Minute system
# We had already created a `sys::System` from hourly RTS data in the OperationsProblem example.
# The RTS data also includes 5-minute resolution time series data. So, we can create another
# `System`:

sys_RT = System(rawsys; forecast_resolution = Dates.Minute(5))

# The RTS dataset has some large RE and load forecast errors that create infeasible
# simulations. Until we enable formulations with slack variables, we need to increase the
# amount of reserve held to handle the forecast error.
get_component(VariableReserve{ReserveUp}, sys, "Flex_Up").requirement = 5.0

# ## `OperationsProblemTemplate`s define `Stage`s
# Sequential simulations in PowerSimulations are created by defining `OperationsProblems`
# that represent `Stages`, and how information flows between executions of a `Stage` and
# between different `Stage`s.
#
# Let's start by defining a two stage simulation that might look like a typical day-Ahead
# and real-time electricity market clearing process.

# ### Define the reference model for the day-ahead unit commitment
devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
)
template_uc = template_unit_commitment(devices = devices)

# ### Define the reference model for the real-time economic dispatch
devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
)
template_ed = template_economic_dispatch(devices = devices)

# ### Define the `Stage`s
# Stages define models. The actual problem will change as the stage gets updated to represent
# different time periods, but the formulations applied to the components is constant within
# a stage. In this case, we want to define two stages with the `OperationsProblemTemplate`s
# and the `System`s that we've already created.

stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template_uc, sys, solver),
    "ED" => Stage(GenericOpProblem, template_ed, sys_RT, solver),
)

# ### `SimulationSequence`
# Similar to an `OperationsProblemTemplate`, the `SimulationSequence` provides a template of
# how to execute a sequential set of operations problems.

#nb # print_struct(SimulationSequence)

# Let's review some of the `SimulationSequence` arguments.

# ### Chronologies
# In PowerSimulations, chronologies define where information is flowing. There are two types
# of chronologies.
#  - inter-stage chronologies: Define how information flows between stages. e.g. day-ahead
# solutions are used to inform economic dispatch problems
#  - intra-stage chronologies: Define how information flows between multiple executions of a
# single stage. e.g. the dispatch setpoints of the first period of an economic dispatch problem
# are constrained by the ramping limits from setpoints in the final period of the previous problem.
#

# Let's define an inter-stage chronolgy that synchronizes information from 24 periods of
# the first stage with a set of executions of the second stage:

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

# ### `FeedForward` and `Cache`
# The definition of exactly what information is passed using the defined chronologies is
# accomplished with `FeedForward` and `Cache` objects. Specifically, `FeedForward` is used
# to define what to do with information being passed with an inter-stage chronology. Let's
# define a `FeedForward` that affects the semi-continuous range constraints of thermal generators
# in the economic dispatch problems based on the value of the unit-commitment variables.

feedforward = Dict(
    ("ED", :devices, :Generators) => SemiContinuousFF(
        binary_from_stage = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

# The `Cache` is simply a way to preserve needed information for later use. In the case of
# a typical day-ahead - real-time market simulation, there are many economic dispatch executions
# in between each unit-commitment execution. Rather than keeping the full set of results from
# previous unit-commitment simulations in memory to be used in later executions, we can define
# exactly which results will be needed and carry them through a cache in the economic dispatch
# problems for later use.

cache = Dict(("UC",) => TimeStatusChange(PSY.ThermalStandard, PSI.ON))

# ### Sequencing
# The stage problem length, look-ahead, and other details surrounding the temporal Sequencing
# of stages are controlled using the `order`, `horizons`, and `intervals` arguments.
#  - order::Dict(Int, String) : the hierarchical order of stages in the simulation
#  - horizons::Dict(String, Int) : defines the number of time periods in each stage (problem length)
#  - intervals::Dict(String, Dates.Period) : defines the interval with which stage problems
# advance after each execution. e.g. day-ahead problems have an interval of 24-hours
#
# So, to define a typical day-ahead - real-time sequence, we can define the following:
#  - Day ahead problems should represent 48 hours, advancing 24 hours after each execution (24-hour look-ahead)
#  - Real time problems should represent 1 hour (12 5-minute periods), advancing 1 hour after each execution (no look-ahead)

order = Dict(1 => "UC", 2 => "ED")
horizons = Dict("UC" => 24, "ED" => 12)
intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Hour(1), Consecutive()))

# Finally, we can put it all together:

DA_RT_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = InterStageChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
    cache = cache,
)

# ## `Simulation`
# Now, we can build and execute a simulation using the `SimulationSequence` and `Stage`s
# that we've defined.

sim = Simulation(
    name = "rts-test",
    steps = 1,
    stages = stages_definition,
    stages_sequence = DA_RT_sequence,
    simulation_folder = rts_dir,
)

# ### Build simulation

build!(sim)

# ### Execute simulation

sim_results = execute!(sim)

# ## Results
uc_results = load_simulation_results(sim_results, "UC");
ed_results = load_simulation_results(sim_results, "ED");

# ## Plotting
# Take a look at the examples in [the plotting folder.](../../notebook/PowerSimulations_examples/Plotting)
