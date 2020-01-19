# # Serializing PowerSystem Data

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSystems.jl supports serializing/deserializing data with JSON. This notebook 
# provides an example of how to write and read a `System` to/from disk.

# ### Dependencies
# Let's use a dataset from one of the parsing examples
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSystems_examples/parse_tabulardata.jl"))

# ### Write data to a temporary directory

path, io = mktemp()
@info "Serializing to $path"
to_json(io, sys)
close(io)

filesize(path)/1000000 #MB

# ### Read the JSON file and create a new `System`
sys2 = System(path)








