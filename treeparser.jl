module TreeParser

include("functionsdefinitions.jl")

SINGLE_FUNC_REGEX = r"(([^\(\)\s\,]+)\(([^\(\)]*?)\))"
FUNC_NAME_REGEX = r"([^\s\,\(\)]+)\("

# To enable logging change verbosity to something greater than zero
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

mutable struct Functor
    func_name::Union{String, SubString}
    operands::Array{Any}
    func_string::Union{String, SubString}
end

function invoke(functor::Functor)
    fsym = Symbol(functor.func_name)
    f = getfield(Main, fsym)

    return f(functor.operands...)
end

function simple_expression_check(exp::Union{String, SubString})
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

mutable struct ExpressionReader
    expression::String
    current_idx::Int64
end

function read_next_word(reader::ExpressionReader)::Union{SubString, Nothing}

    if reader.current_idx > lastindex(reader.expression)
        return nothing
    end

    start_idx = reader.current_idx
    end_idx = reader.current_idx
    
    while true
        sym = reader.current_idx > lastindex(reader.expression) ? nothing : reader.expression[reader.current_idx]
        end_idx = reader.current_idx
        reader.current_idx = reader.current_idx + 1

        if isnothing(sym) || sym === ',' || sym === '(' || sym === ')'
            break
        end

        if sym === '"'
            # find closing quotes
            end_idx = findnext(x -> x === '"', reader.expression, reader.current_idx)
            if isnothing(end_idx)
                throw(ArgumentError("Cannot find closing quotes for " * string(reader.current_idx - 1)))
            end
            reader.current_idx = end_idx + 1
        end
    end

    return SubString(reader.expression, start_idx, end_idx)
end

function parse_function_expression_inner(func_name_word::Union{String, SubString}, reader::ExpressionReader)::Functor

    function try_parse_operand!(word::Union{String, SubString}, operands::Array{Any})
        op = word[1:end - 1]
        if ! isempty(op)
            append!(operands, [op])
        end
    end

    func_name = func_name_word[1:end - 1]
    str_func_exp = func_name_word
    operands = []

    while (w = read_next_word(reader)) !== nothing
        str_func_exp = str_func_exp * func_name_word

        if endswith(w, '(')         # nested function

            nested_func = parse_function_expression_inner(w, reader)
            str_func_exp = str_func_exp * nested_func.func_string
            append!(operands, [nested_func])

        elseif endswith(w, ')')    # function end

            try_parse_operand!(w, operands)
            result_func = Functor(func_name, operands, str_func_exp)

            return result_func

        elseif endswith(w, ',')    # another operand

            try_parse_operand!(w, operands)
        end
    end

    throw(ArgumentError(
        "Looks like something wrong with expression : '" * reader.expression * "' or this method is buggy."))
end

function parse_function_expression(exp::Union{String, SubString})::Functor

    simple_expression_check(exp)
    exp = replace(exp, ' ' => "")

    reader = ExpressionReader(exp, 1)
    root_func_name_word = read_next_word(reader)

    return parse_function_expression_inner(root_func_name_word, reader)
end

function parse_constraint_operand(op::Union{String, SubString})::Union{Int64, Float64, String}
    
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
        return String(replace(op, '"' => ""))
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

    resolved_operands = []
    for op in func.operands
        if isa(op, Functor)
            val = eval_functor_result(op, calc_cache)
            append!(resolved_operands, [val])
        else
            opval = parse_constraint_operand(op)
            append!(resolved_operands, [opval])
        end
    end

    func.operands = resolved_operands
    log("  resolved operands : ", func.operands)

    result = invoke(func)
    calc_cache[func.func_string] = result

    return result
end

end
