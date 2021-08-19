#! format: off

using SIIPExamples

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "02_parse_matpower.jl"))

folder = mktempdir()
path = joinpath(folder, "system.json")
println("Serializing to $path")
to_json(sys, path)

filesize(path) / (1024 * 1024) #MiB

sys2 = System(path)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
