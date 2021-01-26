# Nested functions Expression Parser
Simple app written with Julia language to parse expressions of nested functions.  

### Expression:
```
FUNC(ARG-1, ARG-2, ... ARG-N)

where

ARG-i in [ int, float, string, FUNC ]
FUNC  in [ FUNC-1, FUNC-2, ... FUNC-M ]
```

### To explore the code
- Install Julia from https://julialang.org/downloads/
- cd <this repo root>
- run `julia treeparser.test.jl`
