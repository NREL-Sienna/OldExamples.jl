using PowerSystems
using TimeSeries

base_dir = PowerSystems.download(PowerSystems.TestData; branch = "master");

sys = System(joinpath(base_dir, "matpower", "case5_re.m"))
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

