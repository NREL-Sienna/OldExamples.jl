using SIIPExamples
using PowerSystems
using Logging

using Test

pkgpath = dirname(dirname(pathof(SIIPExamples)))
testpath = joinpath(pkgpath, "test")

exclude = ["US-system-simulations.jl", "08_US_system.jl"]

logger = configure_logging(console_level = Logging.Error)

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
