#jl #! format: off
# # Selective flow constraints with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# The [Operations Problems example]](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/02_sequential_simulations.ipynb)
# shows the basic building blocks of building optimization problems with PowerSimulations.jl.
# This example shows how to customize the enforcement of branch flow constraints as is common
# when trying to build large scale simulations.

# ## Dependencies
# ### Modeling Packages
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

# ### Optimization packages
# For this simple example, we can use the HiGHS solver with a relatively relaxed tolerance.
using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

# ### Create a `System` from RTS-GMLC data
sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

# ### Selecting flow limited lines
# Since PowerSimulations will apply constraints by component type (e.g. Line), we need to
# change the component type of the lines on which we want to enforce flow limits. So, let's
# change the device type of certain branches from Line to MonitoredLine differentiate
# treatment when we build the model. Here, we can select inter-regional lines, or lines
# above a voltage threshold.

for line in get_components(Line, sys)
    if (get_base_voltage(get_from(get_arc(line))) >= 230.0) &&
       (get_base_voltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

# Let's start with a standard unit commitment template using the `PTDFPowerModel` network
# formulation which only constructs the admittance matrix rows corresponding to "bounded" lines:
template = template_unit_commitment(network = PTDFPowerModel)

# Notice that there is no entry for `MonitoredLine`, so we can add one:
set_device_model!(template, MonitoredLine, StaticBranch)

# We can also relax the formulation applied to the `Line` components to an unbounded flow formulation.
# This formulation still enforces Kirchoff's laws, but does not apply flow constraints.
set_device_model!(template, Line, StaticBranchUnbounded)

# ## Build an `OperationsProblem`
uc_prob = DecisionModel(template, sys, horizon = 24, optimizer = solver)
build!(uc_prob, output_dir = mktempdir())

# Solve the relaxed problem
solve!(uc_prob)
