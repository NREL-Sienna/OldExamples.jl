#! format: off

using SIIPExamples

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "02_parse_matpower.jl"))

ybus = Ybus(sys)

ptdf = PTDF(sys)

lodf = LODF(sys)

ptdf["bus3-bus4-i_6", 3]

buses = collect(get_components(Bus, sys))
ybus[buses[1], buses[2]]

busname2num = get_components(Bus, sys) |> (c -> Dict(zip(get_name.(c), get_number.(c))))
ptdf["bus3-bus4-i_6", busname2num["bus3"]]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
