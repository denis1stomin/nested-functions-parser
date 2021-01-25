include("treeparser.jl")
include("functionsdefinitions.jl")

#expression = "2"
#expression = "f1()"
#expression = "f1( a1 )"
#expression = "f1(a1, a2 , a3)"
#expression = "f1(f2())"
#expression = "f1(a1, f2())"
expression = "f1(f2(), a1)"
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = "f1(a1, f2(f3(), b1), a2, f4(c1, c2))"
#expression = """fname1(12, fname2(parse_str2int("2"), fname2(1), 3))"""

fn = Meta.parse(""" include("functionsdefinitions.jl"); """ * expression)
result = eval(fn)
println("Result of simple function: ", result)

parsed_exp = TreeParser.parse_function_expression(expression)
println("=== RESULT :")
println(parsed_exp)
#result = TreeParser.eval_functor_result(parsed_exp)
#println("Result of (may be) smarter function: ", result)
