# LoggingProfiler

This package has origines in the author learning IRTools.jl. The idea is to recursively walk through called functions and surround iteresting calls by logs of start and its end, which allows to measure the execution time. Since measuring all functions can be overwhelming and can be excessive, you can easily edit functions `recursable` and `timable` to limit when the profiler should dig deeper and which functions should be measured. By default, everything is measured and into everything (except intrinsic and builti-in functions) is digged. 

The use of the profiler should be simple. You prepend the the function call by `@record` macro and thats it. An example follows.
```jullia
function foo(x, y)
  z =  x * y
  z + sin(y)
end

LoggingProfiler.clear!()
@record foo(1.0, 1.0)
LoggingProfiler.to
```
As in the built-in julia profiler, you should clear buffers `LoggingProfiler.reset!()` before profiling. The buffer can by default accomodate `1000` items calls, which is very low number. The above example needs buffer of size 364 items. You might threfore run the profiler with small buffer first, then retrieve the  needed length of buffer by `LoggingProfiler.recorded()`, resize it to the right size as `LoggingProfiler.resizebuffer!`, and clear it. Alternatively, you can do everything by running `adjustbuffer!()`, which sets the size to 2-times the needed size and clear it.

Logs are stored in `LoggingProfiler.to`, which is the linear record. You can convert it to nested structure using `LoggingProfiler.tape2structure()`, which is a vector of events, where event contains start and end time stamp, name of the function, and the list of childrens. There is an experimental visualization that saves the structured events to an html file as
```julia
events = LoggingProfiler.tape2structure()
LoggingProfiler._visualize("/tmp/profile.html", events)
```
or just 
```julia
LoggingProfiler._visualize("/tmp/profile.html")
```

See `runtests.jl` for a full example, but there is not much more to show.
### Problems and known issues
- the first run takes ages, as we need to recompile all profiled functions -> use it wisely
- tun the profiler twice, since in the first run you will measure compilation time
- visualization sucks. If there is someone who can help with please, help me please.
- an interesting aspect is the extension to multi-threaded environment. This will hopefully happen.
