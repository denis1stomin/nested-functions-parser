module MyParser

import Pkg
Pkg.add("DataStructures")
using DataStructures

import UUIDs.uuid1

include("FunctionsDefinitions.jl")

SINGLE_FUNC_REGEX = r"(([^\(\)\s\,]+)\(([^\(\)]*?)\))"
FUNC_ID_REGEX = r"^id[a-z0-9]{32}$"

struct Functor
    func_name::String
    arguments::Array{Any}
end

function invoke(functor::Functor)
    fsym = Symbol(functor.func_name)
    f = getfield(FunctionsDefinitions, fsym)

    return f(functor.arguments...)
end

f = Functor("fname1", [4, 2])
res = invoke(f)
println(res)
exit()

struct ParsedExpression
    func_map::Dict
    func_queue::Queue{String}
end

function get_unique_id()
    uuid = replace(string(uuid1()), '-' => "")
    return "id" * uuid
end

function parse_functor_arguments(str_args::String)
    str_arr = map(s -> String(
            strip(replace(s, '"' => ""), ' ')), split(str_args, ','))
    #args = map(s -> if isnumber(s) return )
end

function parse_expression(exp::String)::ParsedExpression
    fmap = Dict()
    fqueue = Queue{String}()

    while ! isnothing(exp)
        #read(stdin, Char)
        #println(exp)

        reg = match(SINGLE_FUNC_REGEX, exp)
        if isnothing(reg)
            throw(ArgumentError(exp))
        end

        func_name = reg[2]
        str_args = parse_functor_arguments(reg[3])
        functor = Functor(func_name, str_args)

        replacer = get_unique_id()
        fmap[replacer] = functor
        enqueue!(fqueue, replacer)

        exp = replace(exp, reg[1] => replacer)

        if exp === replacer
            return ParsedExpression(fmap, fqueue)
        end
    end
end

function resolve_arguments(func::Functor, resultMap::Dict)
    println("================")
    println(func)
    for arg_idx in eachindex(func.arguments)
        arg = func.arguments[arg_idx]
        println("   ", arg_idx, " - ", arg)

        if ! isnothing(match(FUNC_ID_REGEX, arg))
            func.arguments[arg_idx] = resultMap[arg]
        end
    end
    println(func)
end

function eval_parsed_expression(exp::ParsedExpression)

    resMap = Dict()

    for func_id in exp.func_queue

        func = exp.func_map[func_id]
        resolve_arguments(func, resMap)

        res = invoke(func)
        resMap[func_id] = res
    end
end

function eval_expression(exp::String)
    fn = Meta.parse(exp)
    return eval(fn)
end


### Expression functions definitions

fname1(a, b)::Float64 = a / b
fname2(a, b::Int64, c) = a + b + c
fname2(a) = a ^ 2
parse_str2int(s::String) = parse(Int64, s)

### Expression evaluation

expression = """fname1(12, fname2(parse_str2int("2"), fname2(1), 3))"""

result = eval_expression(expression)
println("Result of simple function: ", result)

parsed_exp = parse_expression(expression)
result = eval_parsed_expression(parsed_exp)
println("Result of (may be) smarter function: ", result)

end
