using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using Dates

using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")

horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

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

sim = Simulation(
    name = "TAMU-test",
    steps = 3,
    problems = problems,
    sequence = DA_sequence,
    simulation_folder = sim_folder,
)

build!(sim)

execute!(sim)

sim_results = SimulationResults(sim);
uc_results = get_problem_results(sim_results, "UC")
read_realized_variables(uc_results, names = [:On__ThermalStandard])[:On__ThermalStandard]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
