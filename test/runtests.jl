using SIIPExamples
using InfrastructureSystems
using Logging

using Test

pkgpath = dirname(dirname(pathof(SIIPExamples)))
testpath = joinpath(pkgpath, "test")

exclude = [
    "4_bar_stack_plots.jl",
    "8_US-system-simulations.jl",
    "US_system.jl",
    ]

logger = InfrastructureSystems.configure_logging(console_level = Logging.Error)

for (root, dirs, files) in walkdir(testpath)
    if root != testpath
        @testset "Testing Files in $root" begin
            for file in files
                if file in exclude
                    @info "skipping $file"
                else
                    fname = joinpath(root, file)
                    @testset "$file" begin
                        @test try
                            include(fname)
                            true
                        finally
                        end
                    end
                end
            end
        end
    end
end
