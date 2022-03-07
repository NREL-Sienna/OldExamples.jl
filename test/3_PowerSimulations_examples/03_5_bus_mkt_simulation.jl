#! format: off

using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

using Dates
using DataFrames

using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

sys_DA = build_system(SIIPExampleSystems, "5_bus_matpower_DA")
sys_RT = build_system(SIIPExampleSystems, "5_bus_matpower_RT")

template_uc = template_unit_commitment(use_slacks = true)
template_ed = template_economic_dispatch(
    network = NetworkModel(CopperPlatePowerModel, duals = [CopperPlateBalanceConstraint]),
)

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

file_path = mktempdir(".", cleanup = true)
sim = Simulation(
    name = "5bus-test",
    steps = 1,
    models = models,
    sequence = DA_RT_sequence,
    simulation_folder = file_path,
)

build!(sim)

execute!(sim, enable_progress_bar = false)

# Results

results = SimulationResults(sim);
uc_results = get_problem_results(results, "UC")
ed_results = get_problem_results(results, "ED");

list_dual_names(ed_results)

prices = read_dual(ed_results, "CopperPlateBalanceConstraint__System")

read_realized_dual(ed_results, "CopperPlateBalanceConstraint__System")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
