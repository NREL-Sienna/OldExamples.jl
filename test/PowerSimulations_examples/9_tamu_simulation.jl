using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using Dates

using PowerSystems
using PowerSimulations

using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = dirname(dirname(pathof(PowerSystems)));

TAMU_DIR = joinpath(base_dir, "data", "ACTIVSg2000");
sys = TamuSystem(TAMU_DIR)
horizon = 24;  interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

sim_folder = mkpath(joinpath(pkgpath, "TAMU-sim"))
stages_definition = Dict(
    "UC" =>
        Stage(
            GenericOpProblem,
            template_unit_commitment(network = CopperPlatePowerModel),
            sys,
            solver;),
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

sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    stages = stages_definition,
    stages_sequence = DA_sequence,
    simulation_folder = sim_folder,
)

build!(sim)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

