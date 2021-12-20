
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
                r"\"outputs\":\ \[\]\,\n\ \ \ \"cell_type\":\ \"markdown\"" => "\"cell_type\": \"markdown\"",
            ),
        )
    end
end

"""
`literate_file(folder::AbstractString, file::AbstractString)`

Checks if the file has been modified since the last Weave and updates the notebook and tests accordingly.

# Arguments
* `folder`: Name of the folder the tutorial is in
* `file`: Name of the tutorial file
# Key word arguments
* `force`: force literate irrespective of file changes
* `notebook_target_dir`: folder to write notebook
* `test::Bool`: build test file
"""
function literate_file(folder, file; force = false, kwargs...)
    filename = splitext(file)[1]
    srcpath = joinpath(SCRIPT_DIR, folder, file)
    testpath = joinpath(TEST_DIR, folder)
    notebook_path = get(kwargs, :notebook_target_dir, NB_DIR)
    notebookpath = joinpath(notebook_path, folder)
    notebookfilepath = joinpath(notebookpath, join([filename, ".ipynb"]))
    configpath = joinpath(SCRIPT_DIR, folder, filename * "_config.json")

    config = get(kwargs, :config, Dict())
    if isfile(configpath)
        @info "found config file for $filename"
        config = read_json(configpath)
    end

    literate = get(config, "literate", true)

    if literate
        make_test = get(kwargs, :test, get(config, "test", true))
        make_notebook = get(config, "notebook", true)

        if make_test &&
           (mtime(srcpath) > mtime(testpath) || mtime(testpath) == 0.0 || force)
            @warn "Updating tests for $filename."
            fn = Literate.script(srcpath, testpath; config = config, kwargs...)
            rm_if_empty(fn)
        else
            @warn "Skipping tests for $filename."
        end
        if make_notebook && (
            mtime(srcpath) > mtime(notebookfilepath) ||
            mtime(notebookfilepath) == 0.0 ||
            force
        )
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
    for file in readdir(joinpath(SCRIPT_DIR, folder))
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

function literate_folder(example::Type{<:Examples}; kwargs...)
    folder = get_dir(example)
    literate_folder(folder; kwargs...)
end

"""
`literate_all()`

Checks every tutorial for modifications and updates the notebook accordingly.
"""
function literate_all(; force = false, kwargs...)
    for folder in readdir(SCRIPT_DIR)
        literate_folder(folder; force = force, kwargs...)
    end
end

"""
`notebook(example::Type{<:Examples}; kwargs...)`

Launches a notebook server for the specified `Examples` folder.

# Arguments
- `example::Type{<:Examples}`: The example category `JuliaExamples`, `PSYExamples`, `PSIExamples`, or `PSDExamples`
- `notebook_target_dir = mktempdir()`: directory to create notebooks and launch server

# Example
`notebook(PSYExamples,  ".")`
"""
function notebook(example::Type{<:Examples}, notebook_target_dir = nothing)
    pkg_path = dirname(dirname(pathof(SIIPExamples)))
    if isnothing(notebook_target_dir)
        in_pkg_path = startswith(pkg_path, pwd())
        notebook_target_dir = in_pkg_path ? NB_DIR : mktempdir()
    else
        in_pkg_path = startswith(pkg_path, notebook_target_dir)
    end

    literate_folder(
        example;
        execute = false,
        test = false,
        notebook_target_dir = notebook_target_dir,
        preprocess = in_pkg_path ? nothing : set_env,
    )
    IJulia.notebook(dir = joinpath(notebook_target_dir, get_dir(example)))
end

"""
Prepend each notebook with an environment path
"""
function set_env(str)
    env_path = dirname(dirname(pathof(SIIPExamples)))
    env_str = "] activate $(env_path)\n\n"
    return env_str * str
end
