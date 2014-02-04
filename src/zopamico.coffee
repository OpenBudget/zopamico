class Zopamico
        constructor: (records, fields, value) ->
                @tree = { children: @buildTree(records, fields, value)  }
                @partition = d3.layout.partition()
                @partition.comparator = null
                @nodes = @partition.nodes(@tree)
                @links = @partition.links(@nodes)
                @enumerateDescendants(@tree)
        
        buildTree: (records, fields, value) ->
                field = fields[0]
                if fields.length > 1
                        _fields = fields.slice(1)
                        _.map(_.sortBy(_.pairs(_.groupBy(records,field)),(x)->x[0]), (x) => { name: x[0], children: @buildTree(x[1],_fields,value) })
                else
                        _.map(records, (x) -> { name: x[field], value: x[value], src: x } )

        enumerateDescendants: (node) ->
                if node.children?
                        for tuple in @enumerate(node.children)
                                [i,child] = tuple[0..1]
                                child.index = i
                                child.numSiblings = node.children.length
                                child.eq_dx = node.dx / node.children.length
                                child.eq_x = node.x + node.dx * i / node.children.length
                                @enumerateDescendants child

        enumerate: (list) ->
                _.zip([0..list.length-1],list)

        pathGenerator: (d) ->
                [ "M#{@x(d.y)},#{@y(d.eq_x)}"
                  "L#{@x(d.y)},#{@y(d.eq_x+d.eq_dx)}"
                  "L#{@x(d.y+d.dy/2)},#{@y(d.eq_x+d.eq_dx)}"
                  "C#{@x(d.y+5*d.dy/6)},#{@y(d.eq_x+d.eq_dx)},#{@x(d.y+2*d.dy/3)},#{@y(d.x+d.dx)},#{@x(d.y+d.dy)},#{@y(d.x+d.dx)}"
                  "L#{@x(d.y+d.dy)},#{@y(d.x)}"
                  "C#{@x(d.y+2*d.dy/3)},#{@y(d.x)},#{@x(d.y+5*d.dy/6)},#{@y(d.eq_x)},#{@x(d.y+d.dy/2)},#{@y(d.eq_x)}"
                ].join(" ")

        render: ->
                @w = 1000
                @h = 600
                @x = d3.scale.linear().range([@w, 0])
                @y = d3.scale.linear().range([0, @h])

                @vis = d3.select("body")
                             .append("div")
                                .attr("class", "chart")
                                .style("width", @w + "px")
                                .style("height", @h + "px")
                             .append("svg:svg")
                                .attr("width", @w)
                                .attr("height", @h)

                @g = @vis.selectAll("g")
                        .data(@nodes)
                        .enter().append("svg:g")
                
                @kx = Math.abs(@x(@tree.dx)-@x(0))
                @ky = @y(1)-@y(0)
                console.log "Ks",@kx,@ky

                @g.append("svg:path")
                        .attr("d", (d) => @pathGenerator(d))
                        .style("fill", "none")
                        .style("stroke","#888888")
                        .style("stroke-width","0.5")

                @g.append("svg:text")
                        .attr("x", (d) => @x(d.y))
                        .attr("y", (d) => @y(d.eq_x + d.eq_dx*0.5) ) 
                        .attr("dy", ".35em")
                        .style("opacity", (d) => if Math.abs(@y(d.eq_dx) - @y(0)) > 9 then 1 else Math.abs(@y(d.eq_dx) - @y(0))/9)
                        .style("font-size",(d) => if Math.abs(@y(d.eq_dx) - @y(0)) > 9 then 9 else Math.abs(@y(d.eq_dx) - @y(0)))
                        .text((d) -> d.name)
                        .style('text-anchor','end')


#   d3.select(window)
#       .on("click", function() { click(root); })

#   function click(d) {
#     if (!d.children) return;

#     kx = (d.y ? w - 40 : w) / (1 - d.y);
#     ky = h / d.dx;
#     x.domain([d.y, 1]).range([d.y ? 40 : 0, w]);
#     y.domain([d.x, d.x + d.dx]);

#     var t = g.transition()
#         .duration(d3.event.altKey ? 7500 : 750)
#         .attr("transform", function(d) { return "translate(" + x(d.y) + "," + y(d.x) + ")"; });

#     t.select("rect")
#         .attr("width", d.dy * kx)
#         .attr("height", function(d) { return d.dx * ky; });

#     t.select("text")
#         .attr("transform", transform)
#         .style("opacity", function(d) { return d.dx * ky > 12 ? 1 : 0; });

#     d3.event.stopPropagation();
#   }

# });


root = exports ? window
root.Zopamico = Zopamico