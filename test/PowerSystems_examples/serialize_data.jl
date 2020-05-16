using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSystems_examples", "parse_matpower.jl"))

folder = mktempdir()
path = joinpath(folder, "system.json")
@info "Serializing to $path"
to_json(sys, path)

filesize(path) / 1000000 #MB

sys2 = System(path)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

