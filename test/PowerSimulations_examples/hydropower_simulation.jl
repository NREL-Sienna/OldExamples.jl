using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))

using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

using Dates
using DataFrames

using JuMP
using Cbc # solver
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel = 1, ratioGap = 0.5)

include(joinpath(pkgpath, "script/PowerSimulations_examples/make_hydro_data.jl"))

TypeTree(PSY.HydroGen)

TypeTree(PSI.AbstractHydroFormulation, scopesep="\n", init_expand = 5)

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroDispatch, HydroFixed),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirFlow),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroEnergyReservoir => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirStorage),
)
template_md = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroEnergyReservoir => DeviceModel(HydroEnergyReservoir, HydroDispatchReservoirFlow),
)
template_da = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, Cbc_optimizer),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, Cbc_optimizer),
)

sequence = SimulationSequence(
    order = Dict(1 => "MD", 2 => "DA"),
    intra_stage_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    horizons = Dict("MD" => 2, "DA" => 24),
    intervals = Dict("MD" => Hour(48), "DA" => Hour(24)),
    feed_forward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) =>
                IntegralLimitFF(variable_from_stage = :P, affected_variables = [:P]),
    ),
    ini_cond_chronology = Dict("MD" => Consecutive(), "DA" => Consecutive()),
)

file_path = tempdir()

sim = Simulation(
    name = "hydro",
    steps = 1,
    step_resolution = Hour(48),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

build!(sim)

sim.stages["MD"].internal.psi_container.JuMPmodel

sim.stages["DA"].internal.psi_container.JuMPmodel

#sim_results = execute!(sim)
#```

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, Cbc_optimizer),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, Cbc_optimizer),
    "ED" => Stage(GenericOpProblem, template_da, c_sys5_hy_ed, Cbc_optimizer),
)

sequence = SimulationSequence(
    order = Dict(1 => "MD", 2 => "DA", 3 => "ED"),
    intra_stage_chronologies = Dict(
        ("MD" => "DA") => Synchronize(periods = 2),
        ("DA" => "ED") => Synchronize(periods = 24),
    ),
    horizons = Dict("MD" => 2, "DA" => 24, "ED" => 12),
    intervals = Dict("MD" => Hour(48), "DA" => Hour(24), "ED" => Hour(1)),
    feed_forward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_from_stage = Symbol(PSI.ACTIVE_POWER),
            affected_variables = [Symbol(PSI.ACTIVE_POWER)],
        ),
        ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_from_stage = Symbol(PSI.ACTIVE_POWER),
            affected_variables = [Symbol(PSI.ACTIVE_POWER)],
        ),
    ),
    ini_cond_chronology = Dict(
        "MD" => Consecutive(),
        "DA" => Consecutive(),
        "ED" => Consecutive(),
    ),
)

sim = Simulation(
    name = "hydro",
    steps = 1,
    step_resolution = Hour(48),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

build!(sim)

sim.stages["MD"].internal.psi_container.JuMPmodel

sim.stages["DA"].internal.psi_container.JuMPmodel

sim.stages["ED"].internal.psi_container.JuMPmodel

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

