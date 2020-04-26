using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSystems_examples", "parse_matpower.jl"))

ybus = Ybus(sys)

ptdf = PTDF(sys)

lodf = LODF(sys)

ptdf["5", 3]

buses = collect(get_components(Bus, sys))
ybus[buses[1], buses[2]]

busname2num = get_components(Bus, sys) |> (c -> Dict(zip(get_name.(c), get_number.(c))))
ptdf["5", busname2num["bus3"]]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
