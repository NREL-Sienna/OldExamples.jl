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

include(joinpath(pkgpath,"script/PowerSimulations_examples/make_hydro_data.jl"))

TypeTree(PSY.HydroGen)

TypeTree(PSI.AbstractHydroFormulation)

devices = Dict{Symbol,DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroFix, HydroFixed),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol,DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroCommitmentReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict(:Generators => DeviceModel(ThermalStandard, ThermalBasicUnitCommitment),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
)
template_uc = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

devices = Dict(:Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :ILoads => DeviceModel(InterruptibleLoad, DispatchablePowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_ed = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

stages_definition = Dict("UC" => Stage(GenericOpProblem, template_uc, c_sys5_hy, Cbc_optimizer),
    "ED" => Stage(GenericOpProblem, template_ed, c_sys5_hy_ed, Cbc_optimizer),
)

sequence = SimulationSequence(order = Dict(1 => "UC", 2 => "ED"),
    intra_stage_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24)),
    horizons = Dict("UC" => 24, "ED" => 12),
    intervals = Dict("UC" => Hour(24), "ED" => Hour(1)),
    feed_forward = Dict(("ED", :devices, :Generators) => SemiContinuousFF(binary_from_stage = Symbol(PSI.ON),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
        ("ED", :devices, :HydroDispatch) => IntegralLimitFF(variable_from_stage = Symbol(PSI.REAL_POWER),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
    ),
    cache = Dict("ED" => [TimeStatusChange(Symbol(PSI.ON))]),

    ini_cond_chronology = Dict("UC" => Consecutive(), "ED" => Consecutive()),

)
sim = Simulation(name = "hydro",
    steps = 2,
    step_resolution = Hour(24),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

build!(sim)


sim_results = execute!(sim; verbose = true)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

