# # Operations problems with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports the construction and solution of relaxed optimal power flow
# problems (Operations Problems). Operations problems form the fundamental
# building blocks for [sequential simulations](../../notebook/PowerSimulations_examples/sequential_simulations.ipynb).
# This example shows how to specify and customize a the mathematics that will be applied to the data with
# an `OperationsProblemTemplate`, build and execute an `OperationsProblem`, and access the results.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations

# ### Data management packages
using Dates

# ### Optimization packages
using Cbc #solver

# ### Create a `System` from RTS-GMLC data just like we did in the [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test", "PowerSystems_examples", "parse_tabulardata.jl"))

# ## Change the device type of 230kv ties from Line to MonitoredLines 
# to enforce flow limits for higher volatage transmission network
for line in get_components(Line, sys)
    if (get_basevoltage(get_from(get_arc(line))) >= 230.0) && (get_basevoltage(get_to(get_arc(line))) >= 230.0)
        convert_component!(MonitoredLine, line, sys)
    end
end


# For now, let's just choose a standard DCOPF formulation.
uc_template = template_unit_commitment(network = DCPPowerModel)

# ## `OperationsProblem`
# Now that we have a `System` and an `OperationsProblemTemplate`, we can put the two together
# to create an `OperationsProblem` that we solve.

# ### Optimizer
# It's most convenient to define an optimizer instance upfront and pass it into the
# `OperationsProblem` constructor. For this example, we can use the free Cbc solver with a
# relatively relaxed MIP gap (`ratioGap`) setting to improve speed.

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# ### Build an `OperationsProblem`
# The construction of an `OperationsProblem` essentially applies an `OperationsProblemTemplate`
# to `System` data to create a JuMP model.

op_problem = OperationsProblem(GenericOpProblem,
                               uc_template,
                               sys;
                               optimizer = solver,
                               horizon = 12,
                               slack_variables=true
)

# And solve it ... (the initial conditions for the RTS in this problem are infeasible)
#nb solve!(op_problem)