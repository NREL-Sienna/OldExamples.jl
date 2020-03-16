
# #Bar and stack plots with [PowerGraphics.jl](github.com/nrel-siip/PowerGraphics.jl)
# PowerGraphics also provides some basic specifications for plotting `SimulationResults`.
# This example demonstrates some simple plotting capabilities using different Plots.julia
# backends.
#
# The plotting capabilities use the Julia Plots package which can generate plots using
# several different graphics packages. We'll use GR.jl and PlotluJS.jl.
#
# ## Dependencies
using SIIPExamples #for path locations
using PowerSimulations #to load results
using PowerGraphics

# ### Results file
# If you have already run some of the other examples, you should have generated some results.
# You can load the results into memory with:
pkgpath = dirname(dirname(pathof(SIIPExamples)))
simulation_folder = joinpath(pkgpath, "RTS-GMLC-master", "rts-test")
simulation_folder = joinpath(simulation_folder, readdir(simulation_folder)[end])
res = load_simulation_results(simulation_folder, "UC")

## Plots
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
# series values.

stack_plot(res, [:P__ThermalStandard,:P__RenewableDispatch])

# Or, we can create a series of stack plots for every variable in the dictionary:
# ```julia
# stack_plot(res)
# ```