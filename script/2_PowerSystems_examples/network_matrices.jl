# # Using PowerSystems to calculate network matrices

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSystems.jl supports the calculation of several different matrix representations of
# power system networks. This example demonstrates how to use PowerSystems.jl to calculate:
#  - Y bus
#  - Power transfer distribution factor (PTDF)
#  - Line outage distribution  factor (LODF)

# ### Dependencies
# Let's use a dataset from the [tabular data parsing example](../../notebook/2_PowerSystems_examples/parse_matpower.ipynb)
using SIIPExamples
using Logging
logger = configure_logging(console_level = Error, file_level = Info, filename = "ex.log")
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "parse_matpower.jl"))

# ### Ybus
ybus = Ybus(sys)

# ### PTDF
ptdf = PTDF(sys)

# ### LODF
lodf = LODF(sys)

# ### Indexing
# Note that the axes of these matrices that correspond to buses are indexed by bus number
# (::Int64) while the branch axes are indexed by branch name (::String). You can access
# specific elements of the matrices as follows:

ptdf["bus3-bus4-i_6", 3]

# Additionally, PowerSystems provides accessors to the network matrices that take `Componets`
# as arguments so that you can pass references to the components themselves rather than the
# name or number. For example:
buses = collect(get_components(Bus, sys))
ybus[buses[1], buses[2]]

# If you would instead like to index by bus name, something like the following should work:
busname2num = get_components(Bus, sys) |> (c -> Dict(zip(get_name.(c), get_number.(c))))
ptdf["bus3-bus4-i_6", busname2num["bus3"]]
