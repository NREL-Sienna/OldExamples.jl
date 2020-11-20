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

# ### Optimization packages
# For this simple example, we can use the Cbc solver with a relatively relaxed tolerance.
using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# ### Create a `System` from TAMU data
# We have included some of the TAMU cases (with truncated time series info)
# in the [PowerSystemsTestData](https://github.com/nrel-siip/powersystemstestdata)
# repository for testing, so we can just use that.
PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = dirname(dirname(pathof(PowerSystems)));

# The TAMU data format relies on a folder containing `.m` or `.raw` files and `.csv`
# files for the time series data. We have provided a parser for the TAMU data format with
# the `TamuSystem()` fuction.

TAMU_DIR = joinpath(base_dir, "data", "ACTIVSg2000");
sys = TamuSystem(TAMU_DIR)
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

# ## Run a PCM
# note that the TAMU data doesn't contain startup and shutdown costs, or minimum up/down
# time limits, so a UC problem merely respects minmum generation levels.

sim_folder = mkpath(joinpath(pkgpath, "TAMU-sim"))
stages_definition = Dict(
    "UC" => Stage(
        GenericOpProblem,
        template_unit_commitment(network = CopperPlatePowerModel),
        sys,
        solver,
    ),
)
order = Dict(1 => "UC")
horizons = Dict("UC" => 24)
intervals = Dict("UC" => (Hour(24), Consecutive()))
DA_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = IntraStageChronology(),
)

# ### Define and build a simulation
sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    stages = stages_definition,
    stages_sequence = DA_sequence,
    simulation_folder = sim_folder,
)

build!(sim)

# ### Execute the simulation
#nb sim_results = execute!(sim)

# ### Load and analyze results
#nb uc_results = load_simulation_results(sim_results, "UC");

#nb uc_results.variable_values[:On__ThermalStandard]
