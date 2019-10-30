using SIIPExamples
using Test

pkgpath = dirname(dirname(pathof(SIIPExamples)))
testpath = joinpath(pkgpath,"test")

exclude = []

for (root, dirs, files) in walkdir(testpath)
    if root!=testpath
        @testset "Testing Files in $root" begin
            for file in files
                if file in exclude
                    @info "skipping $file"
                else
                    fname = joinpath(root, file)
                    @info "Testing $file"
                    @test try include(fname); true finally end
                end
            end
        end
    end
end