include("treeparser.jl")
include("functionsdefinitions.jl")


test_cases = [
    # "2"       # TODO : expected exception test
    "f2() "
    "f2( 6   )"
    "f2(4.8, 2 , 8)"
    "f1(f2())"
    "f1(5, f2())"
    "f1(f2(), 2)"
    "f1(1, f2(f3(), 3), 28, f2(5, 8))"
    "f1(1000, f2(f3(), 9), 1, f4(20, 50))"
    """f1(12, f2(parse_str2int("2"), f2(1), 3))"""
    "f1(some_long_calc(), some_long_calc())"
]

println("Starting " * string(length(test_cases)) * "tests.")
println("Output format:  '<expression>'\t <result of built-in parsing>  <result of TreeParser>")

for expression in test_cases
    print("'" * expression * "'\t\t\t\t")

    fn = Meta.parse(expression)
    expected_result = eval(fn)
    print(expected_result, "\t")

    parsed_exp = TreeParser.parse_function_expression(expression)
    #println("=== PARSED FUNCTOR TREE :")
    #println(parsed_exp)
    result = TreeParser.eval_functor_result(parsed_exp, Dict())
    println(result, "\t")

    if (result !== expected_result)
        println("Test failed! See the line above ^")
    end
end
