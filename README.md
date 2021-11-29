# LoggingProfiler

This package has origines in the author learning IRTools.jl. The idea is to recursively walk through called functions and surround iteresting calls by logs of start and its end, which allows to measure the execution time. Since measuring and descending int all functions can be overwhelming, you can black and white list what should be logged and into shat should be recursed. The logic behind is 
```julia
iswhite(timable_list, ex) && return(true)
isblack(timable_list, ex) && return(false)
return(isempty(timable_list) ? true : false)
```
where `timable_list` and `recursable_list` are list of names of functions (`Symbol`), `Core.GlobalRef` and `Modules`. An example from `test/juliaset.jl` contains
```julia
blacklist!(LoggingProfiler.timable_list, Core)
blacklist!(LoggingProfiler.timable_list, Base)
whitelist!(LoggingProfiler.recursable_list, :juliaset_column!)
whitelist!(LoggingProfiler.recursable_list, :juliaset_single!)
```
which says that we should not measure time of anything from `Core` and `Base`, and we should recursively insert time statements only in `:juliaset_column!` and into  `:juliaset_single!`. By default, everything is measured and into everything (except intrinsic and builti-in functions) is digged. 

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

Logs are stored in `LoggingProfiler.to`, where there is one linear record for each thread. **If you are performing multi-threaded computations, run `LoggingProfiler.initbuffer!(1000)` to initialize buffers from every thread.***  You can convert it to nested structure using `LoggingProfiler.tape2structure()`, which is a vector of events, where event contains start and end time stamp, name of the function, and the list of childrens. 


At the moment, there are two: one based on html and other implemented using Luxor
## Luxor
just hit
```
LoggingProfiler.export2luxor("/tmp/profile.png")
```
or use your favourite suffix supported by `Luxor`. The output might looks like this (from `test/juliaset.jl`).
![multi_threadded_luxor](https://github.com/pevnak/LoggingProfiler.jl/blob/main/docs/src/multi_threadded_luxor.png)
where there is one "band" for each thread. The example is taken from [Eric Aubanel](http://www.cs.unb.ca/~aubanel/JuliaMultithreadingNotes.html) and its purpose is to show that one thread is taking significantly longer time then others due to defficiencies of static thread allocation.

## HTML
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
