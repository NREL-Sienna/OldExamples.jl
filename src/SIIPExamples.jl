module SIIPExamples

export print_struct

# using Weave
using Literate
using JSON2

repo_directory = dirname(joinpath(@__DIR__))

"""
`print_struct()`

Prints the definition of a struct.
"""
function print_struct(type)
    mutable = type.mutable ? "mutable" : ""
    println("$mutable struct $type")
    for (fn, ft) in zip(fieldnames(type), fieldtypes(type))
        println("    $fn::$ft")
    end
    println("end")
end

function read_json(filename)
    return open(filename) do io
        JSON2.read(io, Dict)
    end
end

abstract type AbstractOS end
abstract type Unix <: AbstractOS end
abstract type BSD <: Unix end

abstract type Windows <: AbstractOS end
abstract type MacOS <: BSD end
abstract type Linux <: BSD end

if Sys.iswindows()
    const os = Windows
elseif Sys.isapple()
    const os = MacOS
else
    const os = Linux
end

abstract type TestData end

"""
Download Data from `branch="master"` name into a "data" folder in given argument path.
Skip the actual download if the folder already exists and force=false.
Defaults to the root of the PowerSystems package.

Returns the downloaded folder name.
"""
function download(
    repo::AbstractString,
    folder::AbstractString = abspath(joinpath(@__DIR__, "..")),
    branch::String = "master",
    force::Bool = false,
)

    if Sys.iswindows()
        DATA_URL = "$repo/archive/$branch.zip"
    else
        DATA_URL = "$repo/archive/$branch.tar.gz"
    end
    directory = abspath(normpath(folder))
    reponame = splitpath(repo)[end]
    data = joinpath(directory, "$reponame-$branch")
    if !isdir(data) || force
        @info "Downloading $DATA_URL"
        tempfilename = Base.download(DATA_URL)
        mkpath(directory)
        @info "Extracting data to $data"
        unzip(os, tempfilename, directory)
        # mv(joinpath(directory, "$reponame-$branch"), data, force = true)
    end

    return data
end

function unzip(::Type{<:BSD}, filename, directory)
    @assert success(`tar -xvf $filename -C $directory`) "Unable to extract $filename to $directory"
end

function unzip(::Type{Windows}, filename, directory)
    path_7z = if Base.VERSION < v"0.7-"
        "$JULIA_HOME/7z"
    else
        sep = Sys.iswindows() ? ";" : ":"
        withenv(
            "PATH" => string(
                joinpath(Sys.BINDIR, "..", "libexec"),
                sep,
                Sys.BINDIR,
                sep,
                ENV["PATH"],
            ),
        ) do
            Sys.which("7z")
        end
    end
    @assert success(`$path_7z x $filename -y -o$directory`) "Unable to extract $filename to $directory"
end

const empty_nb = "{\n \"cells\": [\n  {\n   \"outputs\": [],\n   \"cell_type\": \"markdown\",\n   \"source\": [\n    \"---\\n\",\n    \"\\n\",\n    \"*This notebook was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*\"\n   ],\n   \"metadata\": {}\n  }\n ],\n \"nbformat_minor\": 3,\n \"metadata\": {\n  \"language_info\": {\n   \"file_extension\": \".jl\",\n   \"mimetype\": \"application/julia\",\n   \"name\": \"julia\",\n   \"version\": \"1.3.1\"\n  },\n  \"kernelspec\": {\n   \"name\": \"julia-1.3\",\n   \"display_name\": \"Julia 1.3.1\",\n   \"language\": \"julia\"\n  }\n },\n \"nbformat\": 4\n}\n"
const empty_script = "# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl\n\n"

function rm_if_empty(filepath::String)
    s = open(filepath) do file
        read(file, String)
    end
    if s == empty_nb || s == empty_script
        @info "Removing empty file: $filepath"
        rm(filepath)
    end
end

function postprocess_notebook(nb)
    txt = read(nb, String)
    open(nb, "w") do f
        write(
            f,
            replace(
                txt,
                r"\"outputs\":\ \[\]\,\n\ \ \ \"cell_type\":\ \"markdown\"" =>
                    "\"cell_type\": \"markdown\"",
            ),
        )
    end
end

"""
`literate_file(folder::AbstractString, file::AbstractString)`

Checks if the file has been modified since the last Weave and updates the notebook and tests accordingly.
* `folder` = Name of the folder the tutorial is in
* `file` = Name of the tutorial file
* `force` = foce weave irrespective of file changes
"""
function literate_file(folder, file; force = false, kwargs...)

    filename = splitext(file)[1]
    srcpath = joinpath(repo_directory, "script", folder, file)
    testpath = joinpath(repo_directory, "test", folder)
    notebookpath = joinpath(repo_directory, "notebook", folder)
    notebookfilepath = joinpath(notebookpath, join([filename, ".ipynb"]))
    configpath = joinpath(repo_directory, "script", folder, filename * "_config.json")

    config = get(kwargs, :config, Dict())
    if isfile(configpath)
        @info "found config file for $filename"
        config = read_json(configpath)
    end

    literate = get(config, "literate", true)

    if literate
        make_test = get(config, "test", true)
        make_notebook = get(config, "notebook", true)

        if make_test && mtime(srcpath) > mtime(testpath) || mtime(testpath) == 0.0 || force
            @warn "Updating tests for $filename."
            fn = Literate.script(srcpath, testpath; config = config, kwargs...)
            rm_if_empty(fn)
        else
            @warn "Skipping tests for $filename."
        end
        if make_notebook && mtime(srcpath) > mtime(notebookfilepath) ||
           mtime(notebookfilepath) == 0.0 ||
           force
            @warn "Converting $filename to Jupyter Notebook."
            fn = Literate.notebook(srcpath, notebookpath; config = config, kwargs...)
            postprocess_notebook(fn)
            rm_if_empty(fn)
        else
            @warn "Skipping Jupyter Notebook for $filename."
        end
    else
        @warn "Skipping literate for $filename per config"
    end
end

"""
`literate_folder(folder::AbstractString)`

Checks the files present in the specified folder for modifications and updates the notebook and tests accordingly.

* `folder` = Name of the folder to check
"""
function literate_folder(folder; force = false, kwargs...)
    for file in readdir(joinpath(repo_directory, "script", folder))
        if splitext(file)[end] == ".jl"
            println("")
            println("Building $(joinpath(folder, file))")
            try
                literate_file(folder, file, force = force; kwargs...)
            catch
                @error "failed to build $(joinpath(folder, file))"
            end
            println("")
        end
    end
end

"""
`literate_all()`

Checks every tutorial for modifications and updates the notebook accordingly.
"""
function literate_all(; force = false, kwargs...)
    for folder in readdir(joinpath(repo_directory, "script"))
        literate_folder(folder; force = force, kwargs...)
    end
end

end # module
