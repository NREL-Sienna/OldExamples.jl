# # Using PowerSystems to calculate network matrices

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSystems.jl supports the calculation of several different matrix representations of
# power system networks. This example demonstrates how to use PowerSystems.jl to calculate:
#  - Y bus
#  - Power transfer distribution factor (PTDF)
#  - Line outage distribution  factor (LODF)

# ### Dependencies
# Let's use a dataset from the [tabular data parsing example](../../notebook/PowerSystems_examples/parse_matpower.ipynb)
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSystems_examples/parse_matpower.jl"))

# ### Ybus
ybus = Ybus(sys)

# ### PTDF
ptdf = PTDF(sys)

# ### LODF
lodf = LODF(sys)

# ### Indexing
# Note that the axes of these matrices that correspond to buses are indexed by bus number
# (::Int64) while the branch axes are indexed by branch name (::String). You can access
# specific elements of the matrices as follows.

ptdf["5",3]

# If you would instead like to index by bus name, something like the following should work:
busname2num = get_components(Bus,sys) |> (c -> Dict(zip(get_name.(c), get_number.(c))))
ptdf["5", busname2num["bus3"]]
