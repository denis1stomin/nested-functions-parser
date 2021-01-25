include("treeparser.jl")
include("functionsdefinitions.jl")

# TODO : automatically iterate through test data

expression = "2"
#expression = "f2() "
#expression = "f2( 6   )"
#expression = "f2(4.8, 2 , 8)"
#expression = "f1(f2())"
#expression = "f1(5, f2())"
#expression = "f1(f2(), 2)"
#
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = """fname1(12, fname2(parse_str2int("2"), fname2(1), 3))"""

fn = Meta.parse(expression)
result = eval(fn)
println("Result of built-in parser: ", result)

parsed_exp = TreeParser.parse_function_expression(expression)
#println("=== PARSED FUNCTOR TREE :")
#println(parsed_exp)

result = TreeParser.eval_functor_result(parsed_exp, Dict())
println("Result of tree parser: ", result)
