# # Selective flow constraints with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# The [Operations Problems example]](../../notebook/PowerSimulations_examples/sequential_simulations.ipynb)
# shows the basic building blocks of building optimization problems with PowerSimulations.jl.
# This example shows how to customize the enforcement of branch flow constraints as is common
# when trying to build large scale simulations.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations

# ### Optimization packages
# For this simple example, we can use the Cbc solver with a relatively relaxed tolerance.
using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# ### Create a `System` from RTS-GMLC data
# We can just use the
# [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSystems_examples", "parse_tabulardata.jl"))

# ### Selecting flow limited lines
# Since PowerSimulations will apply constraints by component type (e.g. Line), we need to
# change the component type of the lines on which we want to enforce flow limits. So, let's
# change the device type of certain branches from Line to MonitoredLine differentiate
# treatment when we build the model. Here, we can select inter-regional lines, or lines
# above a voltage threshold.

for line in get_components(Line, sys)
    if (get_basevoltage(get_from(get_arc(line))) >= 230.0) &&
       (get_basevoltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

# ## Build an `OperationsProblem`
uc_prob =
    UnitCommitmentProblem(sys, optimizer = solver, horizon = 24, slack_variables = true)

# The above function defaults to a basic `CopperPlatePowerModel`, ror now, let's just
# choose a standard DCOPF (B-theta) formulation.
set_transmission_model!(uc_prob, DCPPowerModel) #TODO: rm this and add network = DCPPowerModel to above when PSIMA-138 is tagged

# Let's change the formulation of the `Line` components to an unbounded flow formulation.
# This formulation still enforces Kirchoff's laws, but does not apply flow constraints.
set_branch_model!(uc_prob, :L, DeviceModel(Line, StaticLineUnbounded))

# Notice that there is no entry for `MonitoredLine` branches. So, let's add one.
construct_device!(uc_prob, :ML, DeviceModel(MonitoredLine, StaticLine))

# Solve the relaxed problem

solve!(uc_prob)
