a1 = 2

f1(a, b)::Float64 = a / b

f2(a, b::Int64, c) = a + b + c

f2(a) = a ^ 2

f2() = 4

parse_str2int(s::String) = parse(Int64, s)

function some_long_calc()::Real
    sleep(10)
    return 15
end
