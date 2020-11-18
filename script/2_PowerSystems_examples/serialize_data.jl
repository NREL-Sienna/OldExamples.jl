# # Serializing PowerSystem Data

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSystems.jl supports serializing/deserializing data with JSON. This notebook
# provides an example of how to write and read a `System` to/from disk.

# ### Dependencies
# Let's use a dataset from the [tabular data parsing example](../../notebook/2_PowerSystems_examples/parse_matpower.ipynb)
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "parse_matpower.jl"))

# ### Write data to a temporary directory

folder = mktempdir()
path = joinpath(folder, "system.json")
@info "Serializing to $path"
to_json(sys, path)

filesize(path) / 1000000 #MB

# ### Read the JSON file and create a new `System`
sys2 = System(path)
