# # `System` library management with `PowerSystemCaseBuilder.jl`

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# [PowerSystemCaseBuilder.jl](github.com/NREL-SIIP/PowerSystemCaseBuilder.jl) provides a utility to manage a library of `System`s.
# The package has utilities to list the available system data and to create instances of each system. By keeping track of which systems
# have been constructed locally, it makes the re-instantiation of systems efficient by utilizing the serialization features and avoiding
# the parsing process for systems that have been previously constructed.

# ### Dependencies
using PowerSystemCaseBuilder

# ### List all systems in library
show_systems()

# ### Systems can be listed by category
# the available categories can be displayed with:
show_categories()

# the available systems can be displayed with:
show_systems(SIIPExampleSystems)

# ### Create a `System`
# *The first time this is run, it will parse csv data. Subsequent executions will rely on serialized data and will execute much faster*
sys = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys")
