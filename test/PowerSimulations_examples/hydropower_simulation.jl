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

TypeTree(PSI.AbstractHydroFormulation)

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroFix, HydroFixed),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroCommitmentReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalBasicUnitCommitment),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
)
template_uc = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :ILoads => DeviceModel(InterruptibleLoad, DispatchablePowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_ed = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template_uc, c_sys5_hy, Cbc_optimizer),
    "ED" => Stage(GenericOpProblem, template_ed, c_sys5_hy_ed, Cbc_optimizer),
)

sequence = SimulationSequence(
    order = Dict(1 => "UC", 2 => "ED"),
    intra_stage_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24)),
    horizons = Dict("UC" => 24, "ED" => 12),
    intervals = Dict("UC" => Hour(24), "ED" => Hour(1)),
    feed_forward = Dict(
        ("ED", :devices, :Generators) => SemiContinuousFF(
            binary_from_stage = Symbol(PSI.ON),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
        ("ED", :devices, :HydroDispatch) => IntegralLimitFF(
            variable_from_stage = Symbol(PSI.REAL_POWER),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
    ),
    cache = Dict("ED" => [TimeStatusChange(PSI.ON, PSY.ThermalStandard)]),

    ini_cond_chronology = Dict("UC" => Consecutive(), "ED" => Consecutive()),

)

file_path = tempdir()
sim = Simulation(
    name = "hydro",
    steps = 2,
    step_resolution = Hour(24),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

build!(sim)


sim_results = execute!(sim; verbose = true)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
)
template_md = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_da = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, Cbc_optimizer),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy, Cbc_optimizer),
)

sequence = SimulationSequence(
    order = Dict(1 => "MD", 2 => "DA"),
    intra_stage_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    horizons = Dict("MD" => 2, "DA" => 24),
    intervals = Dict("MD" => Hour(48), "DA" => Hour(24)),
    feed_forward = Dict(
        ("DA", :devices, :HydroDispatch) =>
                IntegralLimitFF(variable_from_stage = :P, affected_variables = [:P]),
    ),

    ini_cond_chronology = Dict("MD" => Consecutive(), "DA" => Consecutive()),
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

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

