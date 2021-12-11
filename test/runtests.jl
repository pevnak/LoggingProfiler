using LoggingProfiler
using BenchmarkTools
using Test


@testset "LoggingProfiler.jl" begin

	@testset "logging" begin 
		calls = LoggingProfiler.to[1];
		LoggingProfiler.clear!()
		LoggingProfiler.record_start(:s1)
		LoggingProfiler.record_start(:s2)
		LoggingProfiler.record_end(:s2)
		LoggingProfiler.record_end(:s1)
		# julia> @btime LoggingProfiler.record_start(:s1)
		# 60.232 ns (3 allocations: 48 bytes)
		# @btime LoggingProfiler.record_end(:s1)
		# 91.868 ns (3 allocations: 48 bytes)
	end


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
	LoggingProfiler.initbuffer!(100000)
	@record foo(1.0, 1.0)
	calls = LoggingProfiler.to[1];
	@test calls.i[] == 384

	@test LoggingProfiler.iscallalist(calls, 1) == false
	@test LoggingProfiler.iscallalist(calls, 2) == true
	@test LoggingProfiler.iscallalist(calls, 3) == false


	LoggingProfiler.clear!()
	@record foo(1.0, 1.0)
	events = LoggingProfiler.tape2structure()
	LoggingProfiler._visualize("/tmp/test.html", events[1])
end
