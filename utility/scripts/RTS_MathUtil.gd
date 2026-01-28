class_name RTS_MathUtil

#mean: 1/labmda (reasonable: lambda = 0.2 means on avg 5 second wait)
#min_t: minimum time that has to elapse before the exponential part
# lambda | Avg wait time
# 1.0	1.0 s
# 0.5	2.0 s
# 0.333…	3.0 s
# 0.25	4.0 s
# 0.2	5.0 s
# 0.166…	6.0 s
# 0.142…	7.0 s
# 0.125	8.0 s
# 0.111…	9.0 s
# 0.1	10.0 s
static func inverse_exponential(min_t: float, lambda: float) -> float:
	var u = randf()
	return min_t - log(1.0 - u) / lambda
