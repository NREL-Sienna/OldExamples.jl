
#jl #! format: off
# # Bar and stack plots with [PowerGraphics.jl](github.com/nrel-siip/PowerGraphics.jl)
# PowerGraphics also provides some basic specifications for plotting `SimulationResults`.
# This example demonstrates some simple plotting capabilities using different Plots.julia
# backends.
#
# The plotting capabilities use the Julia Plots package which can generate plots using
# several different graphics packages. We'll use GR.jl and PlotlyJS.jl.
#
# ## Dependencies
using SIIPExamples #for path locations
pkgpath = dirname(dirname(pathof(SIIPExamples)))
using PowerSystems #to load results
using PowerSimulations #to load results
using PowerGraphics

# ### Results file
# If you have already run some of the other examples, you should have generated some results
# (If you haven't run some of the other simulaitons, you can run
# `include(joinpath(pkgpath, "test", "3_PowerSimulations_examples", "2_sequential_simulations.jl"))`).
# You can load the results into memory with:
simulation_folder = joinpath(dirname(dirname(pathof(SIIPExamples))), "rts-test")
simulation_folder =
    joinpath(simulation_folder, "$(maximum(parse.(Int64,readdir(simulation_folder))))")

results = SimulationResults(simulation_folder);
res = get_problem_results(results, "UC")

# ## Plots
# By default, PowerGraphics uses the GR graphics package as the backend for Plots.jl to
# generate figures. This creates static plots and should execute without any extra steps.
# For example, we can create a plot of a particular variable in the `res` object:
gr() # loads the GR backend
timestamps = get_realized_timestamps(res)
variables = read_realized_variables(res)

plot_dataframe(variables[:P__HydroEnergyReservoir], timestamps)

# However, interactive plotting can generate much more insightful figures, especially when
# creating somewhat complex stacked figures. So, we can use the PlotlyJS backend for Plots,
# but it requires that PlotlyJS.jl is installed in your Project.toml (if in a notebook,
# WebIO.jl is required too). To startup the PlotlyJS backend, run:
plotlyjs()

# PowerGraphics creates an un-stacked line plot by default, but supports kwargs to
# create a variety of different figure styles. For example, a stacked area figure can be
# created with the `stack = true` kwarg:

plot_dataframe(variables[:P__HydroEnergyReservoir], timestamps; stack = true)

# Or a bar chart can be created with `bar = true`:
plot_dataframe(variables[:P__HydroEnergyReservoir], timestamps; bar = true)

# Or a stacked bar chart...
plot_dataframe(variables[:P__HydroEnergyReservoir], timestamps; bar = true, stack = true)

# PowerGraphics also supports some basic aggregation to create cleaner plots. For example,
# we can create a plot of the different variables:
generation = get_generation_data(res)
plot_pgdata(generation, stack = true)

reserves = get_service_data(res)
plot_pgdata(reserves)

# Another standard aggregation is available to plot demand values:
plot_demand(res)

# The `plot_demand` function can also be called with the `System` rather than the `StageResults`
# to inspect the input data. This method can also display demands aggregated by a specified
# `<:Topology`:
plot_demand(res.system, aggregation = Area)

# Another standard aggregation exists based on the fuel categories of the generators in the
# `System`
plot_fuel(res, stack = true)
