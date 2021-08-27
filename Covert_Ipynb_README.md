# Creating Ipynb Reports:
There is a CreateNotebook.yml, located at ~/GitHub/SIIPExamples.jl/.github/workflows/. It performs on Git Actions that convert Julia scripts into Jupyter Notebooks. The script executes these steps. 

- Start the virtual machine that you may select to run on Linux, Windows, or MacOS. It will start with files from GitHub's `master` branch.  

```
name: CreateNotebook
on:
  push:
    branches:
      - master
    tags: '*'
  pull_request:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@latest
        with:
          version: '1.6'
```

- Create gen_notebook.jl
```
      - name: Create a gen_notebook.jl
        run: |
          echo "import Pkg"                    > gen_notebook.jl
          echo "Pkg.activate(@__DIR__)"       >> gen_notebook.jl
          echo "Pkg.instantiate()"            >> gen_notebook.jl
          echo "using SIIPExamples"           >> gen_notebook.jl
          echo "using Literate"               >> gen_notebook.jl
          echo "SIIPExamples.literate_all()"  >> gen_notebook.jl
```

- Run Julia command on gen_notebook.jl that coverts each *.jl file to *.ipynb in the ~/GitHub/SIIPExamples.jl/script/
```
      - name: Call Julia to create Notebook
        shell: bash
        run: |
          julia --project=.
          julia 'gen_notebook.jl'  
```

- Commit and push those files into GitHub's `notebook` branch (nothing on `master`)
```
      - name: Commit Files to 
        run: |
          git config --global user.name "ptn111"
          git config --global user.email "32492807+ptn111@users.noreply.github.com"

          git add -A
          git commit -a -m "Push *.ipynb to notebook branch"
          git branch notebook
          git push --force origin master:notebook
```

