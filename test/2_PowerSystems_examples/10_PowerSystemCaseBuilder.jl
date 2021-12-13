#! format: off

using PowerSystemCaseBuilder

show_systems()

show_categories()

show_systems(SIIPExampleSystems)

sys = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
