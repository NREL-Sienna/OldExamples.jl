# # Parsing PSS/e `*.RAW` Files

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# An example of how to parse PSS/e files and create a `System` using [PowerSystems.jl](github.com/NREL/PowerSystems.jl)

# ### Environment
# This notebook depends on the SIIPExamples.jl environment which is loaded by default

using Pkg
Pkg.status()


# ### Dependencies
using SIIPExamples
using PowerSystems
using TimeSeries
#   
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;

# ### Fetch Data
# PowerSystems.jl links to some test data that is suitable for this example. 
# Let's download the test data
PSY.download(PSY.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));

# ### Create a `System`

sys = PSY.parse_standard_files(joinpath(base_dir,"data/psse_raw/RTS-GMLC.RAW"));

sys
