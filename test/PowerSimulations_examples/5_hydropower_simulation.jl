using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))

using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

using Dates
using DataFrames

using Cbc # solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.05)

include(joinpath(pkgpath, "script", "PowerSimulations_examples", "make_hydro_data.jl"))

PSI.JuMP._wrap_in_math_mode(str) = "\$\$ $(replace(str, "__"=>"")) \$\$"

TypeTree(PSY.HydroGen)

TypeTree(PSI.AbstractHydroFormulation, scopesep = "\n", init_expand = 5)

devices = Dict{Symbol, DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroDispatch, FixedOutput),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol, DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirFlow),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol, DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroEnergyReservoir =>
        DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
)
template_md = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroEnergyReservoir =>
        DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
)
template_da = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, solver),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, solver),
)

sequence = SimulationSequence(
    step_resolution = Hour(48),
    order = Dict(1 => "MD", 2 => "DA"),
    feedforward_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    horizons = Dict("MD" => 2, "DA" => 24),
    intervals = Dict("MD" => (Hour(48), Consecutive()), "DA" => (Hour(24), Consecutive())),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_from_stage = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(PSY.HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraStageChronology(),
);

file_path = tempdir()

sim = Simulation(
    name = "hydro",
    steps = 1,
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
)

build!(sim)

sim.stages["MD"].internal.psi_container.JuMPmodel

sim.stages["DA"].internal.psi_container.JuMPmodel

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, solver),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, solver),
    "ED" => Stage(GenericOpProblem, template_da, c_sys5_hy_ed, solver),
)

sequence = SimulationSequence(
    step_resolution = Hour(48),
    order = Dict(1 => "MD", 2 => "DA", 3 => "ED"),
    feedforward_chronologies = Dict(
        ("MD" => "DA") => Synchronize(periods = 2),
        ("DA" => "ED") => Synchronize(periods = 24),
    ),
    intervals = Dict(
        "MD" => (Hour(48), Consecutive()),
        "DA" => (Hour(24), Consecutive()),
        "ED" => (Hour(1), Consecutive()),
    ),
    horizons = Dict("MD" => 2, "DA" => 24, "ED" => 12),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_from_stage = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
        ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_from_stage = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(PSY.HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraStageChronology(),
);

sim = Simulation(
    name = "hydro",
    steps = 1,
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
)

build!(sim)

sim.stages["MD"].internal.psi_container.JuMPmodel

sim.stages["DA"].internal.psi_container.JuMPmodel

sim.stages["ED"].internal.psi_container.JuMPmodel

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

