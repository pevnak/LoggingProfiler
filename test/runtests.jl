using LoggingProfiler
using Test

@testset "LoggingProfiler.jl" begin
	function foo(x, y)
	  z =  x * y
	  z + sin(y)
	end

	@testset "whitelisting" begin
		ci = @code_lowered foo(1.0, 1.0)
		@test map(LoggingProfiler.timable, ci.code) == Bool[0, 0, 1, 1, 0]
		whitelist!(LoggingProfiler.timable_list, :sin)
		@test map(LoggingProfiler.timable, ci.code) == Bool[0, 0, 1, 0, 0]
		whitelist!(LoggingProfiler.timable_list, Core.GlobalRef(Main, :+))
		@test map(LoggingProfiler.timable, ci.code) == Bool[0, 0, 1, 1, 0]
	end

	LoggingProfiler.clear!()
	@record foo(1.0, 1.0)
	calls = LoggingProfiler.to[1];
	@test  calls.i[] == 364

	@test LoggingProfiler.iscallalist(calls, 1) == false
	@test LoggingProfiler.iscallalist(calls, 2) == true
	@test LoggingProfiler.iscallalist(calls, 3) == false


	LoggingProfiler.clear!()
	@record foo(1.0, 1.0)
	events = LoggingProfiler.tape2structure()
	LoggingProfiler._visualize("/tmp/test.html", events[1])
end
