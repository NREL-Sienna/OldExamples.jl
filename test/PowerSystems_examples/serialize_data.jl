using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSystems_examples", "parse_matpower.jl"))

path, io = mktemp()
path = mv(path, path * ".json")
@info "Serializing to $path"
to_json(io, sys)
close(io)

filesize(path) / 1000000 #MB

sys2 = System(path)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
