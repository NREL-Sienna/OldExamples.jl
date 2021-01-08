# # Parsing MATPOWER Files

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# An example of how to parse MATPOWER files and create a `System` using [PowerSystems.jl](github.com/NREL-SIIP/PowerSystems.jl)

# ### Dependencies
using SIIPExamples
using PowerSystems
using TimeSeries

# ### Fetch Data
# PowerSystems.jl links to some test data that is suitable for this example.
# Let's download the test data
base_dir = PowerSystems.download(PowerSystems.TestData; branch = "master");

# ### Create a `System`
sys = System(joinpath(base_dir, "matpower", "case5_re.m"))
sys
