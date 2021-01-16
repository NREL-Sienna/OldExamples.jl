# # Parsing PSS/e `*.RAW` Files

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# An example of how to parse PSS/e files and create a `System` using [PowerSystems.jl](github.com/NREL-SIIP/PowerSystems.jl)

# ### Dependencies
using SIIPExamples
using PowerSystems
using TimeSeries
using Logging

logger = configure_logging(console_level = Error, file_level = Info, filename = "ex.log")

# ### Fetch Data
# PowerSystems.jl links to some test data that is suitable for this example.
# Let's download the test data
PowerSystems.download(PowerSystems.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));

# ### Create a `System`

sys = System(joinpath(base_dir, "data", "psse_raw", "RTS-GMLC.RAW"));

sys
