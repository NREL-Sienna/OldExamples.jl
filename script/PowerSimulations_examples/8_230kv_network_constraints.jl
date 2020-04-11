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
using Cbc #solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/grid-mod/rts-gmlc) dataset. Let's
# download and extract the data.

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP");


# ### Create a `System` from RTS-GMLC data just like we did in the [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
rawsys = PSY.PowerSystemTableData(rts_src_dir,
                                  100.0,
                                  joinpath(rts_siip_dir,"user_descriptors.yaml"),
                                  timeseries_metadata_file = joinpath(rts_siip_dir,"timeseries_pointers.json"),
                                  generator_mapping_file = joinpath(rts_siip_dir,"generator_mapping.yaml"));

sys = System(rawsys; forecast_resolution = Dates.Hour(1));

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