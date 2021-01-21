module MyParser

struct Functor
    func_name::String
    arguments::Tuple

    function invoke()
        println("not implemented")
    end
end

struct ParsedExpression
    todo
end

function parse_expression(exp::String)::ParsedExpression
    println("not implemented")
    return ParsedExpression(5)
end

function eval_parsed_expression(exp::ParsedExpression)
    #fn = Expr(:call, :fname, 1, 2)
    fn = Meta.parse("fname1(1, 2)")
    
    eval(fn)
end

function tryparsenumber(str::String)
    intVal = tryparse(Int64, str)
    if (! isnothing(intVal))
        return intVal
    end
    
    return tryparse(Float64, str)
end

function eval_raw_expression(exp::String)
    single_function_regex = r"([^\(\)\s\,]+\([^\(\)]*?\))"
    while true
        println(exp)

        reg = match(single_function_regex, exp)
        if isnothing(reg)
            break
        end

        fn = Meta.parse(reg[1])
        value = eval(fn)
        exp = replace(exp, reg[1] => value)

        if (exp === string(value))
            return value
        end
    end
end


### Expression functions definitions

fname1(a, b)::Float64 = a / b
fname2(a, b, c) = a + b + c
fname2(a) = a ^ 2
parse_str2int(s::String) = parse(Int64, s)

### Expression evaluation

expression = """fname1(12, fname2(parse_str2int("2"), fname2(1), 3))"""

result = eval_raw_expression(expression)
println("Result of simple function: ", result)

parsed_exp = parse_expression(expression)
result = eval_parsed_expression(parsed_exp)
println("Result of (may be) smarter function: ", result)

end
