#! format: off

using SIIPExamples #for path locations
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using PowerSystems #to load results
using PowerSimulations #to load results
using PowerGraphics
using PowerSystemCaseBuilder

simulation_folder = joinpath(dirname(dirname(pathof(SIIPExamples))), "rts-test")
simulation_folder =
    joinpath(simulation_folder, "$(maximum(parse.(Int64,readdir(simulation_folder))))")

results = SimulationResults(simulation_folder);
res = get_problem_results(results, "UC")

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")
res.system_uuid = sys.internal.uuid
set_system!(res, sys)

gr() # loads the GR backend
timestamps = get_realized_timestamps(res)
variables = read_realized_variables(res)

plot_dataframe(variables[:P__ThermalStandard], timestamps)

plotlyjs()

plot_dataframe(variables[:P__ThermalStandard], timestamps; stack = true)

plot_dataframe(variables[:P__ThermalStandard], timestamps; bar = true)

plot_dataframe(variables[:P__ThermalStandard], timestamps; bar = true, stack = true)

generation = get_generation_data(res)
plot_pgdata(generation, stack = true)

reserves = get_service_data(res)
plot_pgdata(reserves)

plot_demand(res)

plot_demand(res.system, aggregation = Area)

plot_fuel(res, stack = true)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
