# # 5-bus Market simulation with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways. This
# example demonstrates some of these capabilities to represent electricity market clearing.

# ## Dependencies and Data
# First, let's create `System`s to represent the Day-Ahead and Real-Time market clearing
# process with hourly, and 5-minute time series data, respectively.

# ### Modeling Packages
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using Cbc # mip solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)
using Ipopt # solver that supports duals
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)

# ### 5-bus Data
# The five bus system data here includes hourly day-ahead data, 5-minute real-time market
# data, and 6-second actual data. We'll only use the hourly and 5-minute data for the
# example simulations below, but the 6-second data is included for future development.
sys_DA = build_system(SIIPExampleSystems, "5_bus_matpower_DA")
sys_RT = build_system(SIIPExampleSystems, "5_bus_matpower_RT")

# ## `OperationsProblemTemplate`s

template_uc = template_unit_commitment()
template_ed = template_economic_dispatch()

# ### Define the Simulation Sequence

problems = SimulationProblems(
    UC = OperationsProblem(
        template_uc,
        sys_DA,
        optimizer = solver,
        balance_slack_variables = true,
    ),
    ED = OperationsProblem(
        template_ed,
        sys_RT,
        optimizer = ipopt_solver,
        constraint_duals = [:CopperPlateBalance],
    ),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :ThermalStandard) => SemiContinuousFF(
        binary_source_problem = ON,
        affected_variables = [ACTIVE_POWER],
    ),
)

#cache = Dict("UC" => [TimeStatusChange(ThermalStandard, PSI.ON)])
intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Hour(1), Consecutive()))

DA_RT_sequence = SimulationSequence(
    problems = problems,
    intervals = intervals,
    ini_cond_chronology = InterProblemChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
)

# ## `Simulation`
file_path = mkpath(joinpath(".", "5-bus-simulation"))
sim = Simulation(
    name = "5bus-test",
    steps = 1,
    problems = problems,
    sequence = DA_RT_sequence,
    simulation_folder = file_path,
)

# ### Build simulation

build!(sim)

# ### Execute simulation
# ```julia
execute!(sim, enable_progress_bar = false)
# ```

## Results
# First we can load the result metadata
# ```julia
# results = SimulationResults(sim);
# uc_results = get_problem_results(results, "UC")
# ed_results = get_problem_results(results, "ED");
# ```

# Then we can read and examine the results of interest
# ```julia
# prices = read_dual(ed_results, :CopperPlateBalance)
# ```

# or if we want to look at the realized values
# ```julia
# read_realized_duals(ed_results)[:CopperPlateBalance]
# ```

# *note that in this simulation the prices are all equal to the balance slack
# penalty value of $100000/MWh because there is unserved energy in the result*
