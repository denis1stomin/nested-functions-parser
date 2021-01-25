module TreeParser

include("functionsdefinitions.jl")

SINGLE_FUNC_REGEX = r"(([^\(\)\s\,]+)\(([^\(\)]*?)\))"
FUNC_NAME_REGEX = r"([^\s\,\(\)]+)\("

log_verbosity = 0
function log(args...)
    if (log_verbosity > 0)
        println(args...)
    end
end
function debug_pause()
    if (log_verbosity > 0)
        read(stdin, Char)
    end
end

struct Functor
    func_name::AbstractString
    operands::Array{Any}
    func_string::AbstractString
end

function invoke(functor::Functor, operands::Array{Any})
    fsym = Symbol(functor.func_name)
    f = getfield(Main, fsym)

    ops = operands
    if isnothing(ops)
        ops = functor.operands
    end

    return f(ops...)
end

function parse_function_arguments(str_args::AbstractString)::Array{Any}
    if isnothing(str_args)
        return []
    end

    str_arr = map(x -> strip(x, ' '), 
        split(String(str_args), ',', keepempty=false))

    return str_arr
end

function simple_expression_check(exp::AbstractString)
    exp = strip(exp, ' ')
    fail_check(e) = throw(ArgumentError("Expression '" * e * "' does not look like valid nested functions."))

    # starts with function name
    root_func_idx = findfirst(FUNC_NAME_REGEX, exp)
    ! isnothing(root_func_idx) && root_func_idx.start === 1 || fail_check(exp)

    # ends with closing parenthesis
    exp[end] === ')' || fail_check(exp)

    # have equal number of opening and closing parenthesis'
    openers_cnt = length(findall("(", exp))
    closers_cnt = length(findall(")", exp))
    openers_cnt === openers_cnt || fail_check(exp)
end

function parse_function_expression(exp::AbstractString)::Functor
    simple_expression_check(exp)

    log("====================")
    log("input exp : " * exp)

    idx = findfirst('(', exp)
    if isnothing(idx)
        throw(ArgumentError("Expression is not a function: '" * exp * "'"))
    end

    name = SubString(exp, 1, idx - 1)
    str_pending_exp = SubString(exp, idx + 1, lastindex(exp))
    log("func name : " * name * ";          pending exp after func name : " * str_pending_exp)
    debug_pause()

    arr_arguments = []
    
    # one or more nested functions
    while ! isnothing(str_pending_exp)
        log("  --------------------")
        log("  pending exp : '" * str_pending_exp * "'")
        log("  --------------------")

        first_nested_opener_idx = findfirst('(', str_pending_exp)
        first_closer_idx = findfirst(')', str_pending_exp)
        if isnothing(first_closer_idx)
            throw(ArgumentError("Something wrong with expression? : '" * exp * "'"))
        end

        if isnothing(first_nested_opener_idx) || first_closer_idx < first_nested_opener_idx
            log("  --- found a closer symbol at idx :", first_closer_idx)
            if (first_closer_idx > 1)
                str_arguments = SubString(str_pending_exp, 1, first_closer_idx - 1)
                log("  str arguments : '" * str_arguments * "'")
                arg_part = parse_function_arguments(str_arguments)
                log("  parsed arguments part : ", arg_part)
                append!(arr_arguments, arg_part)
            end
            log("  all parsed arguments : ", arr_arguments)
                
            func =  Functor(
                name, arr_arguments, name * "(" * SubString(str_pending_exp, 1, first_closer_idx))
            log("  returning functor : ", func)
            return func
        else
            nested_func_name_idx = findfirst(FUNC_NAME_REGEX, str_pending_exp)
            str_before_nested_func_name = SubString(str_pending_exp, 1, nested_func_name_idx.start - 1)

            log("  str before nested func: '" * str_before_nested_func_name * "'")

            if ! isnothing(str_before_nested_func_name)
                args_part = parse_function_arguments(strip(str_before_nested_func_name, ' '))
                arr_arguments = vcat(arr_arguments, args_part)
            end
            log("  currently parsed arguments : ", arr_arguments)

            str_nested_exp = SubString(str_pending_exp, nested_func_name_idx.start, lastindex(str_pending_exp))
            log("  nested func str : '" * str_nested_exp * "'")
            nested_func = parse_function_expression(str_nested_exp)
            log("  nested func : ", nested_func)

            # remove handled part
            # TODO : bug here in the case we have arguments after nested function
            str_pending_exp = replace(str_pending_exp, str_before_nested_func_name => "")
            str_pending_exp = replace(str_pending_exp, nested_func.func_string => "")
            log("  new pending exp : '" * str_pending_exp * "'")
            append!(arr_arguments, [nested_func])

            debug_pause()
        end
    end

    throw(ArgumentError("Looks like something wrong with expression : '" * exp * "' or this method is buggy."))
end

function parse_possible_constraint_operand(op::AbstractString)  # :: int, float, string
    
    # int
    ival = tryparse(Int64, op)
    if ! isnothing(ival)
        return ival
    end

    # float
    fval = tryparse(Float64, op)
    if ! isnothing(fval)
        return fval
    end

    # string
    quotesIdx = findfirst('"', op)
    if ! isnothing(quotesIdx)
        return String(replace('"' => "", op))
    end

    throw(ArgumentError("Some unknown operand here : '" * op * "'"))
end

function eval_functor_result(func::Functor, calc_cache::Dict)
    log("====================")
    log("input functor : ", func)

    cached = get(calc_cache, func.func_string, nothing)
    if ! isnothing(cached)
        log("  have value in cache : ", cached)
        return cached
    end

    # TODO : I saw some clear method for that Type{Functor}
    func_type = typeof(TreeParser.Functor("TODO", [], ""))
    resolved_operands = []
    for op in func.operands
        if typeof(op) === func_type
            val = eval_functor_result(op, calc_cache)
            append!(resolved_operands, val)
        else
            opval = parse_possible_constraint_operand(op)
            append!(resolved_operands, opval)
        end
    end
    # TODO : use mutable struct?
    #func.operands = resolved_operands
    log("  resolved operands : ", resolved_operands)

    result = invoke(func, resolved_operands)
    calc_cache[func.func_string] = result

    return result
end

end
