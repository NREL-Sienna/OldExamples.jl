#jl #! format: off
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
using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

# ### 5-bus Data
# The five bus system data here includes hourly day-ahead data, 5-minute real-time market
# data, and 6-second actual data. We'll only use the hourly and 5-minute data for the
# example simulations below, but the 6-second data is included for future development.
sys_DA = build_system(SIIPExampleSystems, "5_bus_matpower_DA")
sys_RT = build_system(SIIPExampleSystems, "5_bus_matpower_RT")

# ## `ProblemTemplate`s

template_uc = template_unit_commitment(use_slacks = true)
template_ed = template_economic_dispatch(
    network = NetworkModel(CopperPlatePowerModel, duals = [CopperPlateBalanceConstraint]),
)

# ### Define the Simulation Sequence

models = SimulationModels(
    decision_models = [
        DecisionModel(template_uc, sys_DA, name = "UC", optimizer = solver),
        DecisionModel(template_ed, sys_RT, name = "ED", optimizer = solver),
    ],
)

feedforward = Dict(
    "ED" => [
        SemiContinuousFeedforward(
            component_type = ThermalStandard,
            source = OnVariable,
            affected_values = [ActivePowerVariable],
        ),
    ],
)

DA_RT_sequence = SimulationSequence(
    models = models,
    ini_cond_chronology = InterProblemChronology(),
    feedforwards = feedforward,
)

# ## `Simulation`
file_path = mktempdir(".", cleanup = true)
sim = Simulation(
    name = "5bus-test",
    steps = 1,
    models = models,
    sequence = DA_RT_sequence,
    simulation_folder = file_path,
)

# ### Build simulation

build!(sim)

# ### Execute simulation

execute!(sim, enable_progress_bar = false)

## Results
# First we can load the result metadata
results = SimulationResults(sim);
uc_results = get_problem_results(results, "UC")
ed_results = get_problem_results(results, "ED");

# Then we can read and examine the results of interest. For example, if we want to read
# marginal prices of the balance constraint, we can see what dual values are available:
list_dual_names(ed_results)

# Then, we can read the results of the dual
prices = read_dual(ed_results, "CopperPlateBalanceConstraint__System")

# or if we want to look at the realized values
read_realized_dual(ed_results, "CopperPlateBalanceConstraint__System")

# *note that in this simulation the prices are all equal to the balance slack
# penalty value of $100000/MWh because there is unserved energy in the result*
