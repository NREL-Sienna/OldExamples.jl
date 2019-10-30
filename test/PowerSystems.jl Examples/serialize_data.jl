
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"script/PowerSystems.jl Examples/parse_tabulardata.jl"))


path, io = mktemp()
@info "Serializing to $path"
to_json(io, sys)
close(io)

filesize(path)/1000000 #MB


sys2 = System(path)

