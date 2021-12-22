#jl #! format: off
# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow. However, since we use a case where generators are subject to
# minimum operating points, we need to also execute a unit commitment problem to provide the
# ACOPF with a valid commitment pattern. This example uses a `Simulation` with two
# `DecisionModels` to execute the UC-ACOPF workflow for a single period.

# ## Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder
using Dates
sim_folder = mktempdir(".", cleanup = true)

# We'll just use a suitable `System` that contains valid AC power flow parameters
sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")
transform_single_time_series!(sys, 1, Hour(1))

# Since we'll be doing non-linear optimization, we need a solver that supports non-linear
# problems. Ipopt is quite good. And, we'll need a separate solver that can handle integer variables.
# So, we'll use Cbc for the UC problem.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)
using Cbc # solver
uc_solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.05)

# Here, we want do define an economic dispatch (linear generation decisions) with an ACOPF
# network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
print_tree(PowerSimulations.PM.AbstractPowerModel)

# First, we can setup a template with a suitable ACOPF network formulation, and formulations
# that represent each of the relevant device categories
ed_template = ProblemTemplate(QCLSPowerModel)
set_device_model!(ed_template, ThermalStandard, ThermalStandardDispatch)
set_device_model!(ed_template, PowerLoad, StaticPowerLoad)
set_device_model!(ed_template, Line, StaticBranch)
set_device_model!(ed_template, TapTransformer, StaticBranch)
set_device_model!(ed_template, Transformer2W, StaticBranch)
set_device_model!(ed_template, HVDCLine, HVDCDispatch)

# We also need to setup a UC template with a simplified network representation
uc_template = ProblemTemplate(DCPPowerModel)
set_device_model!(uc_template, ThermalStandard, ThermalBasicUnitCommitment)
set_device_model!(uc_template, PowerLoad, StaticPowerLoad)
set_device_model!(uc_template, Line, StaticBranch)
set_device_model!(uc_template, TapTransformer, StaticBranch)
set_device_model!(uc_template, Transformer2W, StaticBranch)
set_device_model!(uc_template, HVDCLine, HVDCDispatch)
set_service_model!(uc_template, VariableReserve{ReserveUp}, RangeReserve)

# Now we can build a simulation to solve the UC, pass the commitment pattern to the ACOPF
# and then solve the ACOPF.
models = SimulationModels(
    decision_models = [
        DecisionModel(
            uc_template,
            sys,
            name = "UC",
            optimizer = uc_solver,
        ),
        DecisionModel(
            ed_template,
            sys,
            name = "ACOPF",
            optimizer = solver,
            initialize_model = false,
        )
    ]
)
sequence = SimulationSequence(
    models = models,
    feedforwards = Dict(
        "ACOPF" => [
            SemiContinuousFeedforward(
                component_type = ThermalStandard,
                source = OnVariable,
                affected_values = [ActivePowerVariable, ReactivePowerVariable],
            ),
        ],
    ),
    ini_cond_chronology = InterProblemChronology(),
)

# Note that in the above feedforward definition, the `OnVariable` for the `ThermalStandard`
# components is affecting both the `ActivePowerVariable` and the `ReactivePowerVariable`.
# This is the connection that restricts the ACOPF to only represent active and reactive
# power injections from the units that are committed in the UC problem.
sim = Simulation(
    name = "UC-ACOPF",
    steps = 1,
    models = models,
    sequence = sequence,
    simulation_folder = sim_folder,
)

build!(sim)

# And solve it ...
execute!(sim, enable_progress_bar = false)

