using Pkg
Pkg.status()

using SIIPExamples
using PowerSystems
using TimeSeries
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;

base_dir = PSY.download(PSY.TestData; branch = "master");

sys = System(PSY.PowerModelsData(joinpath(base_dir, "matpower", "case5_re.m")))
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

