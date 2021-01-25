module TreeParser

include("functionsdefinitions.jl")

SINGLE_FUNC_REGEX = r"(([^\(\)\s\,]+)\(([^\(\)]*?)\))"
FUNC_NAME_REGEX = r"([^\s\,\(\)]+)\("

log_verbosity = 1
function log(args...)
    if (log_verbosity > 0)
        println(args...)
    end
end

struct Functor
    func_name::AbstractString
    operands::Array{Any}
    func_string::AbstractString
end

function invoke(functor::Functor)
    fsym = Symbol(functor.func_name)
    f = getfield(FunctionsDefinitions, fsym)

    return f(functor.operands...)
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
    fail_check(e) = throw(ArgumentError("Looks like a wrong expression : '" * e * "'"))

    # starts with function name
    root_func_idx = findfirst(FUNC_NAME_REGEX, exp)
    root_func_idx.start === 1 || fail_check(exp)

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
    read(stdin, Char)

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
            # TODO : is it correct approach for SuString type here?
            str_pending_exp = replace(str_pending_exp, str_before_nested_func_name => "")
            str_pending_exp = replace(str_pending_exp, nested_func.func_string => "")
            log("  new pending exp : '" * str_pending_exp * "'")
            append!(arr_arguments, [nested_func])

            read(stdin, Char)
        end
    end

    throw(ArgumentError("Looks like something wrong with expression : '" * exp * "' or this method is buggy."))
end

function resolve_arguments(func::Functor, calc_cache::Dict)
    # TODO
end

function eval_functor_result(exp::Functor)

    calc_cache = Dict()

    # TODO : recursive calculation
end

end
