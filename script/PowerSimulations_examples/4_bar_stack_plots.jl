
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
# `include(joinpath(pkgpath, "test", "PowerSimulations_examples", "2_sequential_simulations.jl"))`).
# You can load the results into memory with:
simulation_folder = joinpath(pkgpath, "RTS-GMLC-master", "rts-test")
simulation_folder = joinpath(simulation_folder, "$(maximum(parse.(Int64,readdir(simulation_folder))))")
res = load_simulation_results(simulation_folder, "UC")

# ## Plots
# By default, PowerGraphics uses the GR graphics package as the backend for Plots.jl to
# generate figures. This creates static plots and should execute without any extra steps.
# For example, we can create a stacked bar_plot:
gr() # loads the GR backend
bar_plot(res)

# However, interactive plotting can generate much more insightful figures, especially when
# creating somewhat complex stacked figures. So, we can use the PlotlyJS backend for Plots,
# but it requires that PlotlyJS.jl, and ORCA.jl (if in a notebook, WebIO.jl is required too)
# are installed in your Project.toml. To startup the PlotlyJS backend, run:
plotlyjs()

# Now we can create stacked bar plots that can be inspected interactively.
bar_plot(res)

# Similarly, we can create a stack plot for any combination of variable to see the time
# series values. *Note: the `load = true` kwarg populates a line for the total system load.*

stack_plot(
    res,
    [
        Symbol("P__ThermalStandard"),
        Symbol("P__RenewableDispatch"),
    ],
    load = true
)

# Or, we can create a series of stack plots for every variable in the dictionary:
# ```julia
# stack_plot(res)
# ```

# Generator fuel types are not stored in the model, or the associated results files. So,
# to make aggregated fuel plots, we need to load the `System` as well. The simulation routine
# automatically serializes the `System` data into the results directory, so we just need to
# load it.
uc_sys =
    System(joinpath(simulation_folder, "models_json", "stage_UC_model", "Stage1_sys_data.json"))

# Now we can make a set of aggregated plots by fuel type.
fuel_plot(res, uc_sys, load = true)
