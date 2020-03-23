using SIIPExamples #for path locations
using PowerSimulations #to load results
using PowerGraphics

pkgpath = dirname(dirname(pathof(SIIPExamples)))
simulation_folder = joinpath(pkgpath, "RTS-GMLC-master", "rts-test")
simulation_folder = joinpath(simulation_folder, readdir(simulation_folder)[end])
res = load_simulation_results(simulation_folder, "UC")

# Plots

gr() # loads the GR backend
bar_plot(res)

plotlyjs()

bar_plot(res)

stack_plot(res, [Symbol("P__PowerSystems.ThermalStandard"),
                Symbol("P__PowerSystems.RenewableDispatch")])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

