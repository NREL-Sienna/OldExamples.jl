#! format: off

using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

using Dates
using DataFrames

using HiGHS # solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)
odir = mktempdir(".", cleanup = true) #tmpdir for build steps

c_sys5_hy_wk = build_system(SIIPExampleSystems, "5_bus_hydro_wk_sys")
c_sys5_hy_uc = build_system(SIIPExampleSystems, "5_bus_hydro_uc_sys")
c_sys5_hy_ed = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys")

c_sys5_hy_wk_targets = build_system(SIIPExampleSystems, "5_bus_hydro_wk_sys_with_targets")
c_sys5_hy_uc_targets = build_system(SIIPExampleSystems, "5_bus_hydro_uc_sys_with_targets")
c_sys5_hy_ed_targets = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys_with_targets")

PSI.JuMP._wrap_in_math_mode(str) = "\$\$ $(replace(str, "__"=>"")) \$\$"

print_tree(HydroGen)

print_tree(PSI.AbstractHydroFormulation)

template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template, HydroDispatch, FixedOutput)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc, horizon = 2)
build!(prob, output_dir = odir)

PSI.get_jump_model(prob)

template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirBudget)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc, horizon = 2)
build!(prob, output_dir = odir)

PSI.get_jump_model(prob)

template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirStorage)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc_targets, horizon = 24)
build!(prob, output_dir = odir)

PSI.get_jump_model(prob)

template_md = ProblemTemplate()
set_device_model!(template_md, ThermalStandard, ThermalStandardDispatch)
set_device_model!(template_md, PowerLoad, StaticPowerLoad)
set_device_model!(template_md, HydroEnergyReservoir, HydroDispatchReservoirStorage)

template_da = ProblemTemplate()
set_device_model!(template_da, ThermalStandard, ThermalStandardDispatch)
set_device_model!(template_da, PowerLoad, StaticPowerLoad)
set_device_model!(template_da, HydroEnergyReservoir, HydroDispatchReservoirStorage)

problems = SimulationModels(
    decision_models = [
        DecisionModel(
            template_md,
            c_sys5_hy_wk_targets,
            name = "MD",
            optimizer = solver,
            system_to_file = false,
        ),
        DecisionModel(
            template_da,
            c_sys5_hy_uc_targets,
            name = "DA",
            optimizer = solver,
            system_to_file = false,
        ),
    ],
)

sequence = SimulationSequence(
    models = problems,
    feedforwards = Dict(
        "DA" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_uc_targets),
            ),
        ],
    ),
    ini_cond_chronology = IntraProblemChronology(),
);

sim = Simulation(
    name = "hydro",
    steps = 1,
    models = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

PSI.get_jump_model(sim.models.decision_models[1])

PSI.get_jump_model(sim.models.decision_models[2])

transform_single_time_series!(c_sys5_hy_wk, 2, Hour(24)) # TODO fix PSI to enable longer intervals of stage 1

problems = SimulationModels(
    decision_models = [
        DecisionModel(
            template_md,
            c_sys5_hy_wk_targets,
            name = "MD",
            optimizer = solver,
            system_to_file = false,
        ),
        DecisionModel(
            template_da,
            c_sys5_hy_uc_targets,
            name = "DA",
            optimizer = solver,
            system_to_file = false,
        ),
        DecisionModel(
            template_da,
            c_sys5_hy_ed_targets,
            name = "ED",
            optimizer = solver,
            system_to_file = false,
        ),
    ],
)

sequence = SimulationSequence(
    models = problems,
    feedforwards = Dict(
        "DA" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_uc_targets),
            ),
        ],
        "ED" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_ed_targets),
            ),
        ],
    ),
    ini_cond_chronology = IntraProblemChronology(),
);

sim = Simulation(
    name = "hydro",
    steps = 1,
    models = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

PSI.get_jump_model(sim.models.decision_models[1])

PSI.get_jump_model(sim.models.decision_models[2])

PSI.get_jump_model(sim.models.decision_models[3])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
