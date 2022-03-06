#jl #! format: off
# # Simulations with TAMU data and [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This is a basic simulation example using the [TAMU Cases](https://electricgrids.engr.tamu.edu/).

# ## Dependencies
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using Dates

# ### Modeling Packages
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

# ### Optimization packages
# For this simple example, we can use the HiGHS solver with a relatively relaxed tolerance.
using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

# ### Create a `System` from TAMU data
# We have included some of the TAMU cases (with truncated time series info)
# in the PowerSystemCaseBuilder testing, so we can just use that.
sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")
transform_single_time_series!(sys, 24, Dates.Hour(24));

# ## Run a PCM
# note that the TAMU data doesn't contain startup and shutdown costs, or minimum up/down
# time limits, so a UC problem merely respects minmum generation levels.

sim_folder = mkpath(joinpath(pkgpath, "TAMU-sim"))
models = SimulationModels(
    decision_models = [DecisionModel(
        template_unit_commitment(),
        sys,
        name = "UC",
        optimizer = solver,
    ),]
)
# ### Define and build a simulation
sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    models = models,
    sequence = SimulationSequence(models = models, ini_cond_chronology = InterProblemChronology()),
    simulation_folder = sim_folder,
)

build!(sim)

# ### Execute the simulation
execute!(sim)

# ### Load and analyze results
sim_results = SimulationResults(sim);
uc_results = get_problem_results(sim_results, "UC")
read_realized_variable(uc_results, "OnVariable__ThermalStandard")
