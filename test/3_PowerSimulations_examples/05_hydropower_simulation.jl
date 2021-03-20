using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

using Dates
using DataFrames

using Cbc # solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.05)
odir = mktempdir() #tmpdir for build steps

c_sys5_hy_wk = build_system(SIIPExampleSystems, "5_bus_hydro_wk_sys")
c_sys5_hy_uc = build_system(SIIPExampleSystems, "5_bus_hydro_uc_sys")
c_sys5_hy_ed = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys")

PSI.JuMP._wrap_in_math_mode(str) = "\$\$ $(replace(str, "__"=>"")) \$\$"

print_tree(HydroGen)

print_tree(PSI.AbstractHydroFormulation)

template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template, HydroDispatch, FixedOutput)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = OperationsProblem(template, c_sys5_hy_uc, horizon = 2)
build!(op_problem, output_dir = odir)

op_problem.internal.optimization_container.JuMPmodel

template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirBudget)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = PSI.OperationsProblem(template, c_sys5_hy_uc, horizon = 2)
build!(op_problem, output_dir = odir)

op_problem.internal.optimization_container.JuMPmodel

template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirStorage)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = PSI.OperationsProblem(template, c_sys5_hy_uc, horizon = 24)
build!(op_problem, output_dir = odir)

op_problem.internal.optimization_container.JuMPmodel

template_md = OperationsProblemTemplate()
set_device_model!(template_md, ThermalStandard, ThermalDispatch)
set_device_model!(template_md, PowerLoad, StaticPowerLoad)
set_device_model!(template_md, HydroEnergyReservoir, HydroDispatchReservoirStorage)

template_da = OperationsProblemTemplate()
set_device_model!(template_da, ThermalStandard, ThermalDispatch)
set_device_model!(template_da, PowerLoad, StaticPowerLoad)
set_device_model!(template_da, HydroEnergyReservoir, HydroDispatchReservoirStorage)

problems = SimulationProblems(
    MD = OperationsProblem(
        template_md,
        c_sys5_hy_wk,
        optimizer = solver,
        system_to_file = false,
    ),
    DA = OperationsProblem(
        template_da,
        c_sys5_hy_uc,
        optimizer = solver,
        system_to_file = false,
    ),
)

sequence = SimulationSequence(
    problems = problems,
    feedforward_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    intervals = Dict("MD" => (Hour(48), Consecutive()), "DA" => (Hour(24), Consecutive())),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraProblemChronology(),
);

sim = Simulation(
    name = "hydro",
    steps = 1,
    problems = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

sim.problems["MD"].internal.optimization_container.JuMPmodel

sim.problems["DA"].internal.optimization_container.JuMPmodel

transform_single_time_series!(c_sys5_hy_wk, 2, Hour(24)) # TODO fix PSI to enable longer intervals of stage 1

problems = SimulationProblems(
    MD = OperationsProblem(
        template_md,
        c_sys5_hy_wk,
        optimizer = solver,
        system_to_file = false,
    ),
    DA = OperationsProblem(
        template_da,
        c_sys5_hy_uc,
        optimizer = solver,
        system_to_file = false,
    ),
    ED = OperationsProblem(
        template_da,
        c_sys5_hy_ed,
        optimizer = solver,
        system_to_file = false,
    ),
)

sequence = SimulationSequence(
    problems = problems,
    feedforward_chronologies = Dict(
        ("MD" => "DA") => Synchronize(periods = 2),
        ("DA" => "ED") => Synchronize(periods = 24),
    ),
    intervals = Dict(
        "MD" => (Hour(24), Consecutive()),
        "DA" => (Hour(24), Consecutive()),
        "ED" => (Hour(1), Consecutive()),
    ),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
        ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraProblemChronology(),
);

sim = Simulation(
    name = "hydro",
    steps = 1,
    problems = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

sim.problems["MD"].internal.optimization_container.JuMPmodel

sim.problems["DA"].internal.optimization_container.JuMPmodel

sim.problems["ED"].internal.optimization_container.JuMPmodel

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
