#! format: off

using SIIPExamples
pkgpath = pkgdir(SIIPExamples)
using Dates

using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")
transform_single_time_series!(sys, 24, Dates.Hour(24));

sim_folder = mkpath(joinpath(pkgpath, "TAMU-sim"))
models = SimulationModels(
    decision_models = [
        DecisionModel(template_unit_commitment(), sys, name = "UC", optimizer = solver),
    ],
)

sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    models = models,
    sequence = SimulationSequence(
        models = models,
        ini_cond_chronology = InterProblemChronology(),
    ),
    simulation_folder = sim_folder,
)

build!(sim)

execute!(sim)

sim_results = SimulationResults(sim);
uc_results = get_decision_problem_results(sim_results, "UC")
read_realized_variable(uc_results, "OnVariable__ThermalStandard")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
