#jl #! format: off
# # Simulations with TAMU data and [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This is a basic simulation example using the [TAMU Cases](https://electricgrids.engr.tamu.edu/).

# ## Dependencies
using SIIPExamples
pkgpath = pkgdir(SIIPExamples)
using Dates

# ### Modeling Packages
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

# ### Optimization packages
# For this simple example, we can use the Cbc solver with a relatively relaxed tolerance.
using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# ### Create a `System` from TAMU data
# We have included some of the TAMU cases (with truncated time series info)
# in the PowerSystemCaseBuilder testing, so we can just use that.
sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")

horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

# ## Run a PCM
# note that the TAMU data doesn't contain startup and shutdown costs, or minimum up/down
# time limits, so a UC problem merely respects minmum generation levels.

sim_folder = mkpath(joinpath(pkgpath, "TAMU-sim"))
problems = SimulationProblems(
    UC = OperationsProblem(
        template_unit_commitment(transmission = CopperPlatePowerModel),
        sys,
        optimizer = solver,
    ),
)
intervals = Dict("UC" => (Hour(24), Consecutive()))
DA_sequence = SimulationSequence(
    problems = problems,
    intervals = intervals,
    ini_cond_chronology = IntraProblemChronology(),
)

# ### Define and build a simulation
sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    problems = problems,
    sequence = DA_sequence,
    simulation_folder = sim_folder,
)

build!(sim)

# ### Execute the simulation
execute!(sim)

# ### Load and analyze results
sim_results = SimulationResults(sim);
uc_results = get_problem_results(sim_results, "UC")
read_realized_variables(uc_results, names = [:On__ThermalStandard])[:On__ThermalStandard]
