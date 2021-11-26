"""
    iscallalist(calls, i)

    true if the call starting at `i` is a simple call without childs. 
    In the example below, `add_float` is a call list, but `+` is not
    becaus it is `+`.
```
+: 8.73396258e8
 add_float: 8.73396817e8
 add_float: 8.73396957e8
+: 8.73396999e8
```
"""
function iscallalist(calls, i)
    calls.startstop[i] == :stop && return(false)
    calls.i[] < i + 1           && return(false)
    calls.startstop[i+1] == :start && return(false)
    calls.event[i] == calls.event[i+1]
end

function parselist(calls, i)
    new_node = Dict(
        :start => calls.stamps[i],
        :stop => calls.stamps[i+1],
        :name => calls.event[i],
        )
    new_node, i+2
end

"""
    function tape2structure(calls)

    convert flat list of logs of calls and convert it to
    structured format
"""
function tape2structure(calls::Events)
    if calls.i[] >= length(calls.stamps)
        @warn "The recording buffer was too small, consider increasing it"
    end
    root = Dict{Symbol,Any}(:children => [])
    stack = Stack{Dict}() 
    node = root;
    i = 1
    while i <= min(calls.i[], length(calls.stamps))
        if iscallalist(calls, i)
            new_node, i = parselist(calls, i)
            push!(node[:children], new_node)
        end
        if calls.startstop[i] == :start 
            push!(stack, node)
            new_node = Dict(
                :start => calls.stamps[i],
                :name => calls.event[i],
                :children => []
                )
            # println(i, " new node ", calls.event[i])
            push!(node[:children], new_node)
            node = new_node
            i += 1
        end

        if calls.startstop[i] == :stop
            # println(i, " end node ", calls.event[i], " expecting: ", node[:name])
            @assert node[:name] == calls.event[i]
            node[:stop] = calls.stamps[i]
            i += 1
            node = pop!(stack)
        end
    end
    root
end

function _visualize(filename::String, root; basetime= root[:children][1][:start], scaling = 1)
    open(filename, "w") do fio
        header(fio) 
        _visualize(fio, root[:children], Dict(); basetime, scaling)
        footer(fio) 
    end
end

function _visualize(io::IO, events, mapping ; basetime, scaling)
    for event in events
        name = event[:name]
        start = scaling * event[:start]
        stop = scaling * event[:stop]
        expandable = haskey(event, :children) ? "expandable" : ""
        duration = round((event[:stop] - event[:start]) / 10^9, digits=2)

        if name ∉ keys(mapping)
            mapping[name] = Dict(:id => rand(Int), :color => random_color(), :counter => 0, :children => Dict())
        end
        m = mapping[name]

        println(io, """
        <div class="event $(expandable)" data-start="$(start)" data-end="$(stop)" data-time="$(duration)" data-method="$(m[:id])" data-nth="$(m[:counter])" style="background: $(m[:color])">
                <span class="title">$(!haskey(event, :children) ? "" : """<i class="fa fa-caret-down"></i> """)$(name)</span>
                <div class="info">
                    <i class="fa fa-clock"></i>$(duration)s)</span>
                </div>

                <div class="subevents">
        """)
        m[:counter] += 1

        if haskey(event, :children)
            _visualize(io, event[:children], m[:children] ; basetime=event[:start], scaling=scaling)
        end

        println(io, """
                </div>
        </div>""")
    end
end

function random_color()
    c = Colors.color_names
    return("#"*hex(RGB((c[rand(keys(c))]./255)...)))
end

function header(io::IO)
    print(io, """<html>
<head>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.2/css/all.min.css" />
  <link rel="stylesheet" href="https://unpkg.com/purecss@2.0.5/build/pure-min.css" integrity="sha384-LTIDeidl25h2dPxrB2Ekgc9c7sEC3CWGM6HeFmuDNUjX76Ert4Z4IY714dhZHPLd" crossorigin="anonymous">
  <style>
    body {
      font-family: Helvetica, sans-serif;
      padding: 0px;
      margin: 0px;
      user-select: none;
    }
  
    .track {
      display: flex;
      background: black;
      overflow: visible;
      min-width: min-content;
    }
    .track-label {
      position: fixed;
      padding: 5px;
      width: 150px;
      vertical-align: center;
      text-align: center;
      color: white;
      font-weight: bold;
      background: black;
    }
    .track-content {
      border-radius: 8px;
      background: white;
      margin: 5px 5px 5px 155px;
      position: relative;
      width: 500px;
      display: flex;
      padding: 2px 10px 2px 10px;
    }
    .event {
      position: relative;
      display: block;
      float: left;
      overflow: hidden;
      box-shadow: inset -1px 0 0 #333, inset 0 -1px 0 #333, inset 1px 0 0 #333, inset 0 1px 0 #333;
    }
    .event > .title {
      display: block;
      text-align: center;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font: 10px monospace;
      font-weight: bold;
      padding: 3px 0px 3px 0px;
    }
    .event > .info {
      display: block;
      max-height: 20px;
      text-align: center;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font: 10px monospace;
      font-weight: bold;
      padding: 3px 0px 3px 0px;
    }
    .event > .subevents {
      position: relative;
      display: none;
    }
    .event.expanded > .subevents {
      display: block;
    }
    .event.expanded > .info {
      display: none;
    }
    
    #legend {
      display: none;
      border: 2px solid white;
      background: #cccccc;
    }
    #legend .title {
      display: block;
      background: black;
      color: white;
      text-align: center;
      padding: 5px;
    }
    #legend table {
      font-size: 11px;
    }
  </style>
</head>
<body>
""")
end

function footer(io::IO)
    print(io, """
  <div id="legend">
    <span class="title"></span>
    <table class="pure-table">
      <thead>
        <tr>
          <th></th>
          <th colspan="4">This call</th>
          <th colspan="4">Overall</th>
        </tr>
        <tr>
          <th></th>
          <th>Time</th>
          <th>Memory</th>
          <th>GC Time</th>
          <th>CPU util</th>
          <th>Time</th>
          <th>Memory</th>
          <th>GC Time</th>
          <th>CPU util</th>
        </tr>
      </thead>
      <tbody></tbody>
    </table>
  </div>
  
  <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
  <script>
    \$(".event.expandable").click(function(e) {
        \$("[data-method=" + \$(this).data("method") + "]").toggleClass("expanded");
    })
    \$(".event").click(function(e) {
        e.stopPropagation();
    })
    
    \$(".event").hover(function(e) {
        e.stopPropagation();
      var \$this = \$(this);
      var method = \$this.data("method")
      var nth = \$this.data("nth")
      var \$el = \$("#legend");
      \$el.find(".title").html(\$this.find(".title").html())
      
      var \$tbody = \$el.find("tbody");
      \$tbody.html("");
      \$(".track").each(function() {
        var \$track = \$(this);
        var \$tr = \$("<tr/>")
        \$tr.append("<th>" + \$track.find(".track-label").html() + "</th>");
        \$tr.append("<td>" + statistics(\$([\$track.find("[data-method=" + method + "]")[nth]]), "time", format_time) + "</td>")
        \$tr.append("<td>" + statistics(\$([\$track.find("[data-method=" + method + "]")[nth]]), "memory", format_memory) + "</td>")
        \$tr.append("<td>" + statistics(\$([\$track.find("[data-method=" + method + "]")[nth]]), "gctime", format_time) + "</td>")
        \$tr.append("<td>" + statistics(\$([\$track.find("[data-method=" + method + "]")[nth]]), "cpuutil", format_cpuutil) + "</td>")
        \$tr.append("<td>" + statistics(\$(\$track.find("[data-method=" + method + "]")), "time", format_time) + "</td>")
        \$tr.append("<td>" + statistics(\$(\$track.find("[data-method=" + method + "]")), "memory", format_memory) + "</td>")
        \$tr.append("<td>" + statistics(\$(\$track.find("[data-method=" + method + "]")), "gctime", format_time) + "</td>")
        \$tr.append("<td>" + statistics(\$(\$track.find("[data-method=" + method + "]")), "cpuutil", format_cpuutil) + "</td>")
        \$tbody.append(\$tr);
      })
      
      \$el.show();
      \$el.css({position:"absolute", left:e.pageX,top:e.pageY});
    }, function(e) {
        \$("#legend").hide();
    })
    
    function statistics(\$els, field, formatter) {
        var values = [];
      \$els.each(function() {
        values.push(\$(this).data(field));
      })
      var mean = values.reduce((a,b) => a+b) / values.length
      var std = Math.sqrt(values.map(a => (a-mean)*(a-mean)).reduce((a,b) => a+b) / values.length)
      
      if(values.length == 1) {
        return formatter(mean);
      } else {
        return formatter(mean) + " &plusmn; " + formatter(std);
      }
    }
    
    function format_time(val) {
        return (val / 1000000000).toFixed(2) + "s";
    }
    function format_memory(val) {
        return (val / (1024*1024)).toFixed(1) + "MB";
    }
    function format_cpuutil(val) {
        return Math.round(val) + "%";
    }
    
    function adjustpositions(scale) {
        var \$els = \$(".event");
      
      var mintime = Infinity;
      var maxtime = -Infinity;
      \$els.each(function() {
        mintime = Math.min(mintime, \$(this).data("start"));
        maxtime = Math.max(maxtime, \$(this).data("end"));
      })
      
      \$(".track-content").each(function() {
        adjustpositions_helper(\$(this).children(".event"), scale, mintime);
      })
      \$(".track-content").css("width", Math.round((maxtime-mintime) / scale) + "px");
    }
    
    function adjustpositions_helper(\$els, scale, mintime) {
        var currx = 0;
        \$els.each(function() {
        var \$el = \$(this);;
        var left   = Math.round((\$el.data("start") - mintime) / scale);
        var right  = Math.round((\$el.data("end") - mintime) / scale);
        var width  = right - left;
        var leftx  = left - currx;
        \$el.css("left", leftx + "px");
        \$el.css("width", width + "px");
        currx += width;
        
        adjustpositions_helper(\$el.children(".subevents").children(".event"), scale, \$el.data("start"));
      })
    }
    
    adjustpositions(100000000)
  </script>
</body>
</html>
""")
end