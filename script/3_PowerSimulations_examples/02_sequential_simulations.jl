#jl #! format: off
# # Sequential Simulations with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways. This
# example demonstrates some of these capabilities to represent electricity market clearing.

# ## Dependencies
# Since the `OperatiotnsProblem` is the fundamental building block of a sequential
# simulation in PowerSimulations, we will build on the [OperationsProblem example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
# by sourcing it as a dependency.
using SIIPExamples
pkgpath = pkgdir(SIIPExamples)
include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"),
)

# ### 5-Minute system
# We had already created a `sys::System` from hourly RTS data in the OperationsProblem example.
# The RTS data also includes 5-minute resolution time series data. So, we can create another
# `System`:
sys_RT = build_system(PSITestSystems, "modified_RTS_GMLC_RT_sys")

# ## `OperationsProblemTemplate`s define `Stage`s
# Sequential simulations in PowerSimulations are created by defining `OperationsProblems`
# that represent `Stages`, and how information flows between executions of a `Stage` and
# between different `Stage`s.
#
# Let's start by defining a two stage simulation that might look like a typical day-Ahead
# and real-time electricity market clearing process.

# ### We've already defined the reference model for the day-ahead unit commitment
#set_device_model!(template_ed, GenericBattery, BookKeeping)
template_uc

# ### Define the reference model for the real-time economic dispatch
# In addition to the manual specification process demonstrated in the OperationsProblem
# example, PSI also provides pre-specified templates for some standard problems:
template_ed = template_economic_dispatch()

# ### Define the `SimulationProblems`
# `OperationsProblem`s define models. The actual problem will change as the stage gets updated to represent
# different time periods, but the formulations applied to the components is constant within
# a stage. In this case, we want to define two stages with the `OperationsProblemTemplate`s
# and the `System`s that we've already created.
problems = SimulationProblems(
    UC = OperationsProblem(template_uc, sys, optimizer = solver),
    ED = OperationsProblem(
        template_ed,
        sys_RT,
        optimizer = solver,
        balance_slack_variables = true,
    ),
)
# Note that the "ED" problem has a `balance_slack_variables = true` argument. This adds slack
# variables with a default penalty of 1e6 to the nodal energy balance constraint and helps
# ensure feasibility with some performance impacts.

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

# Let's define an inter-stage chronology that synchronizes information from 24 periods of
# the first stage with a set of executions of the second stage:

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

# ### `FeedForward` and `Cache`
# The definition of exactly what information is passed using the defined chronologies is
# accomplished with `FeedForward` and `Cache` objects. Specifically, `FeedForward` is used
# to define what to do with information being passed with an inter-stage chronology. Let's
# define a `FeedForward` that affects the semi-continuous range constraints of thermal generators
# in the economic dispatch problems based on the value of the unit-commitment variables.

feedforward = Dict(
    ("ED", :devices, :ThermalStandard) => SemiContinuousFF(
        binary_source_problem = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

# ### Sequencing
# The stage problem length, look-ahead, and other details surrounding the temporal Sequencing
# of stages are controlled using the `intervals` argument and the structure of the `Forecast`
# data in the `System` of each problem.
#  - intervals::Dict(String, Dates.Period) : defines the interval with which stage problems
# advance after each execution. e.g. day-ahead problems have an interval of 24-hours
#
# So, to define a typical day-ahead - real-time sequence, we can define the following:
#  - Day ahead problems should represent 48 hours, advancing 24 hours after each execution (24-hour look-ahead)
#  - Real time problems should represent 1 hour (12 5-minute periods), advancing 15 min after each execution (15 min look-ahead)

intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Minute(15), Consecutive()))

# Finally, we can put it all together:

DA_RT_sequence = SimulationSequence(
    problems = problems,
    intervals = intervals,
    ini_cond_chronology = InterProblemChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
)

# ## `Simulation`
# Now, we can build and execute a simulation using the `SimulationSequence` and `Stage`s
# that we've defined.
sim = Simulation(
    name = "rts-test",
    steps = 1,
    problems = problems,
    sequence = DA_RT_sequence,
    simulation_folder = pkgdir(SIIPExamples),
)

# ### Build simulation
build!(sim)

# ### Execute simulation
# the following command returns the status of the simulation (0: is proper execution) and
# stores the results in a set of HDF5 files on disk.
execute!(sim, enable_progress_bar = false)

# ## Results
# To access the results, we need to load the simulation result metadata and then make
# requests to the specific data of interest. This allows you to efficiently access the
# results of interest without overloading resources.
results = SimulationResults(sim);
uc_results = get_problem_results(results, "UC"); # UC stage result metadata
ed_results = get_problem_results(results, "ED"); # ED stage result metadata

# Now we can read the specific results of interest for a specific problem, time window (optional),
# and set of variables, duals, or parameters (optional)

read_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

# Or if we want the result of just one variable, parameter, or dual (must be defined in the
# problem definition), we can use:

read_parameter(
    ed_results,
    :P__max_active_power__RenewableFix_max_active_power,
    initial_time = DateTime("2020-01-01T06:00:00"),
    count = 5,
)

# * note that this returns the results of each execution step in a separate dataframe *
# If you want the realized results (without lookahead periods), you can call `read_realized_*`:

read_realized_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

# ## Plotting
# Take a look at the [plotting examples.](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/04_bar_stack_plots.ipynb)
