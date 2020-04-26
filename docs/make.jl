using Documenter, SIIPExamples

makedocs(
    modules = [SIIPExamples],
    format = Documenter.HTML(),
    sitename = "SIIPExamples.jl",
    authors = "Clayton Barrows",
    pages = [
        "Home" => "index.md",
        "Adding a New Tutorial" => "new.md",
        "Notes" => "notes.md",
        "Function Index" => "api.md",
    ],
)

Documenter.deploydocs(repo = "github.com/NREL-SIIP/SIIPExamples.jl.git", target = "build")
