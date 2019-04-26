using Test
using Pkg
using Test

obj = Pkg.activate("env")
@test (obj == joinpath(pwd(),"env","Project.toml")) | (obj == nothing)
@test Pkg.instantiate()==nothing
@test Pkg.resolve()==nothing
@test using PowerSystems == nothing
@test using PowerSimulations == nothing
@test using JuMP == nothing
@test using Ipopt == nothing 
