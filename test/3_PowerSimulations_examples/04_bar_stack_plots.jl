#! format: off

using SIIPExamples #for path locations
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using PowerSystems #to load results
using PowerSimulations #to load results
using PowerGraphics
using PowerSystemCaseBuilder

include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "03_5_bus_mkt_simulation.jl"),
)

set_system!(uc_results, sys_DA)

gr() # loads the GR backend
timestamps = get_realized_timestamps(uc_results)
variable = read_realized_variable(uc_results, "ActivePowerVariable__ThermalStandard")

plot_dataframe(variable, timestamps)

plotlyjs()

plot_dataframe(variable, timestamps; stack = true)

plot_dataframe(variable, timestamps; bar = true)

plot_dataframe(variable, timestamps; bar = true, stack = true)

generation = get_generation_data(uc_results)
plot_pgdata(generation, stack = true)

reserves = get_service_data(uc_results)
plot_pgdata(reserves)

plot_demand(uc_results)

plot_demand(uc_results.system, aggregation = Area)

plot_fuel(uc_results)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
