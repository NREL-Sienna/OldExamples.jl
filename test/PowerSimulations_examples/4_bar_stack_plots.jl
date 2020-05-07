using SIIPExamples #for path locations
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using PowerSystems #to load results
using PowerSimulations #to load results
using PowerGraphics

simulation_folder = joinpath(pkgpath, "RTS-GMLC-master", "rts-test")
simulation_folder = joinpath(simulation_folder, readdir(simulation_folder)[end])
res = load_simulation_results(simulation_folder, "UC")

gr() # loads the GR backend
bar_plot(res)

plotlyjs()

bar_plot(res)

stack_plot(
    res,
    [
        Symbol("P__PowerSystems.ThermalStandard"),
        Symbol("P__PowerSystems.RenewableDispatch"),
    ],
)

uc_sys =
    System(joinpath(simulation_folder, "models_json", "stage_UC_model", "UC_sys_data.json"))

fuel_plot(res, uc_sys)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

