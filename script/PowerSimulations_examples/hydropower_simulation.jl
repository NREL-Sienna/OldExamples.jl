# # Hydropower Simulations with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways.
# This example demonstrates a few of the options for modeling hydropower generation.

# ## Dependencies
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))

# ### Modeling Packages
using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using JuMP
using Cbc # solver
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel = 1, ratioGap = 0.5)

# ### Data
# There is a meaningless test dataset assembled in the
# [make_hydropower_data.jl](../../script/PowerSimulations_examples/make_hydro_data.jl) script.

include(joinpath(pkgpath, "script/PowerSimulations_examples/make_hydro_data.jl"))

# ## Two PowerSimulations features determine hydropower representation.
# There are two prinicpal ways that we can customize hydropower representation in
# PowerSimulations. First, we can play with the formulation applied to hydropower generators
# using the `DeviceModel`. We can also adjust how simulaitons are configured to represent
# different decison making processes and the information flow between those processes.

# ### Hydropower `DeviceModel`s

# First, the assignment of device formulations to particular device types gives us control
# over the representation of devices. This is accomplished by defining `DeviceModel`
# instances. For hydro power representations, we have two available generator types in
# PowerSystems:

TypeTree(PSY.HydroGen)

# And in PowerSimulations, we have several available formulations that can be applied to
# the hydropower generation devices:

TypeTree(PSI.AbstractHydroFormulation)

# Let's see what some of the different combinations create. First, let's apply the
# `HydroDispatchRunOfRiver` formulation to the `HydroDispatch` generators, and the
# `HydroFixed` formulation to `HydroFix` generators.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroFix, HydroFixed),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad)
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# Now we can see the resulting JuMP model:

op_problem.psi_container.JuMPmodel

# Next, let's apply the `HydroDispatchReservoirFlow` formulation to the `HydroDispatch` generators, and the
# `HydroDispatchRunOfRiver` formulation to `HydroFix` generators.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad)
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# And, the resulting JuMP model:

op_problem.psi_container.JuMPmodel

# Next, let's apply the `HydroDispatchReservoirStorage` formulation to the `HydroDispatch` generators, and the
# `HydroDispatchRunOfRiver` formulation to `HydroFix` generators.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad)
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# -

op_problem.psi_container.JuMPmodel

# Finally, let's see the `HydroCommitmentReservoirFlow` formulation applied to the `HydroDispatch` generators, and the
# `HydroDispatchRunOfRiver` formulation to `HydroFix` generators.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroCommitmentReservoirStorage),
    :Hyd2 => DeviceModel(HydroFix, HydroDispatchRunOfRiver),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad)
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# -

op_problem.psi_container.JuMPmodel

# ### Multi-Stage `SimulationSequence`
# The purpsoe of a multi-stage simulaiton is to represent scheduling decisions consistently
# with the time scales that govern different elements of power systems.

# UC model template
devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalBasicUnitCommitment),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
)
template_uc = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

# ED model template

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :ILoads => DeviceModel(InterruptibleLoad, DispatchablePowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_ed = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

# Simulaiton setup

stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template_uc, c_sys5_hy_uc, Cbc_optimizer),
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

# ### Multi-Day to Daily

# In the multi-day model, we'll use a really simple representation of all system devices
# so thatt we can maintain computational tractability while getting an estimate of system
# requirements/capabilities.

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
)
template_md = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

# For the daily model, we can increase the modeling detail since we'll be solving shorter
# problems.

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_da = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

#

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
        ("DA", :devices, :HydroDispatch) =>
                IntegralLimitFF(variable_from_stage = :P, affected_variables = [:P]),
    ),
    # Dont know why this doesn't work, could be fixed in the new update
    # cache = Dict("UC" => [TimeStatusChange(:ON_ThermalStandard)]),
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
