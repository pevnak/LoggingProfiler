using LoggingProfiler
using Test

@testset "LoggingProfiler.jl" begin
	function foo(x, y)
	  z =  x * y
	  z + sin(y)
	end

	LoggingProfiler.clear!()
	@record foo(1.0, 1.0)
	@test  LoggingProfiler.to.i[] == 364

	@test LoggingProfiler.iscallalist(calls, 1) == false
	@test LoggingProfiler.iscallalist(calls, 2) == true
	@test LoggingProfiler.iscallalist(calls, 3) == false


	LoggingProfiler.clear!()
	@record foo(1.0, 1.0)
	events = LoggingProfiler.tape2structure()
	LoggingProfiler._visualize("/tmp/test.html", events)
end
