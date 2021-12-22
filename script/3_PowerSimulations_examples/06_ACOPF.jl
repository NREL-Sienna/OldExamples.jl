#jl #! format: off
# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow.

# ## Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder
using Dates

# We can use the a [TAMU synthetic ERCOT dataset](https://electricgrids.engr.tamu.edu/electric-grid-test-cases/).
# The TAMU data format relies on a folder containing `.m` or `.raw` files and `.csv`
# files for the time series data. We have provided a parser for the TAMU data format with
# the `TamuSystem()` function. A version of the system with only one week of time series
# is included in PowerSystemCaseBuilder.jl, we can use that version here:
sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")
transform_single_time_series!(sys, 1, Hour(1))

# Since we'll be doing non-linear optimization, we need a solver that supports non-linear
# problems. Ipopt is quite good. And, we'll also need a solver that can handle integer variables.
# So, we'll use Cbc for the UC problem.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)
using Cbc # solver
uc_solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.05)

# In the [OperationsProblem example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define an economic dispatch (linear generation decisions) with an ACOPF
# network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
print_tree(PowerSimulations.PM.AbstractPowerModel)

# For now, let's just choose a standard ACOPF formulation.
ed_template = ProblemTemplate(QCLSPowerModel)#, use_slacks = true)
set_device_model!(ed_template, ThermalStandard, ThermalStandardDispatch)
set_device_model!(ed_template, PowerLoad, StaticPowerLoad)
#set_device_model!(ed_template, FixedAdmittance, StaticPowerLoad) #TODO add constructor for shunts in PSI

# uc template
uc_template = template_unit_commitment()

# Now we can build a 4-hour economic dispatch / ACOPF problem with the TAMU data.
models = SimulationModels(
    decision_models = [
        DecisionModel(
            uc_template,
            sys,
            name = "UC",
            optimizer = uc_solver,
            #initialize_model = false
        ),
        DecisionModel(
            ed_template,
            sys,
            name = "ACOPF",
            #horizon = 1,
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

sim_folder = mktempdir(".", cleanup = true)
sim = Simulation(
    name = "UC-ACOPF",
    steps = 1,
    models = models,
    sequence = sequence,
    simulation_folder = sim_folder,
)

build!(sim, file_level = Logging.Debug)
# And solve it ... (it's infeasible)
execute!(sim, enable_progress_bar = false)
