class Zopamico

        # Text sizes
        MAX_FONT_SIZE = 30
        MIN_FONT_SIZE = 20
        MARGIN = 0.1

        # Column Types
        COLUMN_TYPE_BREADCRUMB = 0
        COLUMN_TYPE_TIP        = 1
        COLUMN_TYPE_PARTITION  = 2
        COLUMN_TYPE_INVISIBLE  = 3

        # Column widths
        BREADCRUMB_COLUMN_WIDTH = 24
        TIP_COLUMN_WIDTH = 300

        constructor: (element, records, fields, value) ->
                @el = element
                @tree = { children: @buildTree(records, fields, value)  }
                @partition = d3.layout.partition()
                @partition.comparator = null
                @nodes = @partition.nodes(@tree)
                @links = @partition.links(@nodes)
                @tree.prefix = []
                @id = 0
                @enumerateDescendants(@tree)
                @colorizeTree(@tree)
                @numColumns = 2
                @vis = d3.select(@el)
                        .append("svg:svg")
                        .attr("width", "100%")
                        .attr("height", "100%")
                d3.select('body')
                        .on("keydown", () => @keyPress())
                @colorScale = d3.scale.linear()
                        .domain([-0.5, -0.25, -0.05, -0.001, 0, 0.001, 0.05, 0.25, 0.5])
                        .range(["#9F7E01", "#dbae00", "#eac865","#f5dd9c","#AAA","#bfc3dc", "#9ea5c8", "#7b82c2", "#464FA1"]).clamp(true)
                @selectedNode = @tree
                @selectedChild = -1
                @applyState(@tree)


        columnType: (d) ->
                if d.depth == @selectedNode.depth + 1
                        COLUMN_TYPE_TIP
                else if d.depth <= @selectedNode.depth
                        COLUMN_TYPE_BREADCRUMB
                else if d.depth > @selectedNode.depth + @numColumns
                        COLUMN_TYPE_INVISIBLE
                else
                        COLUMN_TYPE_PARTITION

        isSelected: (d) ->
                ((d.parent == @selectedNode) && (d.index == @selectedChild)) || (d == @selectedNode) || (d.parent?.parent == @selectedNode && d.parent?.index == @selectedChild)
                        
        buildTree: (records, fields, value) ->
                field = fields[0]
                if fields.length > 1
                        _fields = fields.slice(1)
                        _.map(_.sortBy(_.pairs(_.groupBy(records,field)),(x)->x[0]), (x) => { name: x[0], children: @buildTree(x[1],_fields,value) })
                else
                        _.map(records, (x) -> { name: x[field], value: x[value], src: x } )

        traverseTree: (root,cb,depth, parentFirst) ->
                if parentFirst
                        cb(root)
                if root.children? and depth > 0
                        _.each( root.children, (child) => @traverseTree(child,cb,depth-1) )
                if not parentFirst
                        cb(root)

        enumerateDescendants: (node) ->
                if node.children?
                        for tuple in @enumerate(node.children)
                                [i,child] = tuple[0..1]
                                child.id = @id
                                @id += 1
                                child.index = i
                                child.prefix = node.prefix.slice(0)
                                child.prefix.push(i)
                                child.numSiblings = node.children.length
                                child.eq_dx = node.dx / node.children.length
                                child.eq_x = node.x + node.dx * i / node.children.length
                                @enumerateDescendants child

        colorizeTree: (node) ->
                cb = (node) ->
                        if node.children?
                                sumvalues = 0
                                sumrefs = 0
                                for child in node.children
                                        sumvalues += child.value
                                        sumrefs += child.ref
                                node.value = sumvalues
                                node.ref = sumrefs
                                node.color = sumvalues / sumrefs - 1.0
                        else
                                node.color = node.src.value / node.src.ref - 1.0
                                node.ref = node.src.ref
                @traverseTree(node,cb,100,false)
                console.log 'colorize',node

        enumerate: (list) ->
                _.zip([0..list.length-1],list)

        pathGenerator: (d) ->
                if @columnType(d) == COLUMN_TYPE_PARTITION
                        ry = ly = @y2
                else
                        ry = @y
                        ly = @y2
                
                [ "M#{@x(d.y)},#{ly(d.x)}"
                  "M#{@x(d.y)},#{ly(d.x+d.dx)}"
                  "L#{@x(d.y+d.dy/10)},#{ry(d.r_x+d.r_dx)}"
                  "L#{@x(d.y+d.dy*9/10)},#{ry(d.r_x+d.r_dx)}"
                  "L#{@x(d.y+d.dy)},#{ly(d.x+d.dx)}"
                  "L#{@x(d.y+d.dy)},#{ly(d.x)}"
                  "L#{@x(d.y+d.dy*9/10)},#{ry(d.r_x)}"
                  "L#{@x(d.y+d.dy/10)},#{ry(d.r_x)}"
                  "L#{@x(d.y)},#{ly(d.x)}"
                ].join(" ")
                # [ "M#{@x(d.y)},#{ry(d.r_x)}"
                #   "L#{@x(d.y)},#{ry(d.r_x+d.r_dx)}"
                #   "L#{@x(d.y+d.dy/6)},#{ry(d.r_x+d.r_dx)}"
                #   "C#{@x(d.y+7*d.dy/9)},#{ry(d.r_x+d.r_dx)},#{@x(d.y+5*d.dy/9)},#{(ly(d.x+d.dx)+ry(d.r_x+d.r_dx))/2},#{@x(d.y+d.dy)},#{ly(d.x+d.dx)}"
                #   "L#{@x(d.y+d.dy)},#{ly(d.x)}"
                #   "C#{@x(d.y+5*d.dy/9)},#{(ly(d.x)+ry(d.r_x))/2},#{@x(d.y+7*d.dy/9)},#{ry(d.r_x)},#{@x(d.y+d.dy/6)},#{ry(d.r_x)}"
                #   "L#{@x(d.y)},#{ry(d.r_x)}"
                # ].join(" ")
                #[ "M#{@x(d.y)},#{ry(d.r_x)}"
                #  "L#{@x(d.y)},#{ry(d.r_x+d.r_dx)}"
                #  "L#{@x(d.y+d.dy/2)},#{ry(d.r_x+d.r_dx)}"
                #  "C#{@x(d.y+5*d.dy/6)},#{ry(d.r_x+d.r_dx)},#{@x(d.y+2*d.dy/3)},#{ly(d.x+d.dx)},#{@x(d.y+d.dy)},#{ly(d.x+d.dx)}"
                #  "L#{@x(d.y+d.dy)},#{ly(d.x)}"
                #  "C#{@x(d.y+2*d.dy/3)},#{ly(d.x)},#{@x(d.y+5*d.dy/6)},#{ry(d.r_x)},#{@x(d.y+d.dy/2)},#{ry(d.r_x)}"
                #].join(" ")

        setScales: ->
                @x = d3.scale.linear().domain([0,1]).range([@w, 0])
                ## Calculate zoom for right side
                childrenInView = (@h / MIN_FONT_SIZE)
                offset = 0
                zoom = 1
                if childrenInView < @selectedNode.children.length
                        zoom = childrenInView / @selectedNode.children.length
                        if @selectedChild >= childrenInView / 2
                                if @selectedChild <= @selectedNode.children.length - childrenInView/2
                                        offset = (@selectedChild - childrenInView/2) / @selectedNode.children.length
                                else
                                        offset = 1 - childrenInView / @selectedNode.children.length                      
                @y = d3.scale.linear().domain([@selectedNode.x+@selectedNode.dx*offset,@selectedNode.x+@selectedNode.dx*(offset+zoom)]).range([0, @h])
                
                ## Calculate zoom for left side
                if @selectedChild >= 0 and @selectedNode.children[@selectedChild].children?
                        ## A child is selected
                        @y2 = d3.scale.linear().domain([@selectedNode.x,@selectedNode.x+@selectedNode.dx]).range([0, @h]).clamp(false)

                        child = @selectedNode.children[@selectedChild]
                        lastGrandchild = child.children[child.children.length-1]

                        currentPixels = Math.abs(@y2(child.x) - @y2(child.x + child.dx))
                        neededPixels = child.dx / lastGrandchild.dx * MIN_FONT_SIZE

                        if neededPixels > currentPixels
                                if neededPixels > @h*(1-2*MARGIN)
                                        neededPixels = @h*(1-2*MARGIN)
                        else
                                neededPixels = currentPixels
                        zoom = neededPixels / currentPixels
                        zoomFocal = child.x + child.dx / 2

                        # domain
                        margin = (1+(MARGIN/(1-2*MARGIN)))
                        d_top = zoomFocal-child.dx/2*margin
                        d_bottom = zoomFocal+child.dx/2*margin
                        if d_top < 0.0
                                d_bottom -= (d_top - 0.0)
                                d_top = 0.0
                        if d_bottom > 1.0
                                d_top -= d_bottom - 1.0
                                d_bottom = 1.0

                        # range
                        r_top = zoomFocal-child.dx/2*zoom*margin
                        r_bottom = zoomFocal+child.dx/2*zoom*margin
                        if r_top < 0.0
                                r_bottom -= (r_top - 0.0)
                                r_top = 0.0
                        if r_bottom > 1.0
                                r_top -= r_bottom - 1.0
                                r_bottom = 1.0
                        r_top = @y2(r_top)
                        r_bottom = @y2(r_bottom)
                        @y2 = d3.scale.linear().domain([d_top,d_bottom]).range([r_top, r_bottom]).clamp(false)
                else
                        #pass
                ## No child is selected - zoom to the entire range of children
                @y2 = d3.scale.linear().domain([@selectedNode.x,@selectedNode.x+@selectedNode.dx]).range([0, @h])
              
        render: ->
                console.log 'visibleNodes',@visibleNodes.length              
                g = @vis.selectAll("g")
                        .data(@visibleNodes, (d) -> d.id)

                @w = $(@el).width()
                @h = $(@el).height()
                if not @x?
                        @setScales()

                oldNodes = g.exit()
                console.log 'oldNodes',oldNodes
                oldNodes.transition()
                        .duration(1000)
                        .remove()

                newNodes = g.enter().append("svg:g")

                newNodes.append("svg:path")
                        .attr("class", "item-path")
                        .style("fill", "none")
                        .style("stroke","#888888")
                        .style("stroke-width","0.5")
                        .on("click",(d) => @click(d))
                        .call(@pathStyles)
                        .style("opacity",0)

                newNodes.append("svg:text")
                        .attr("class", "item-text")
                        .attr("dy", ".35em")
                        .style('text-anchor','middle')
                        .on("click",(d) => @click(d))
                        .call(@textStyles)
                        .style("opacity",0)

                @setScales()

                @vis.selectAll(".item-path")
                        .style("fill", (d) => if @isSelected(d) then "#0074D9" else d3.hsl(@colorScale(d.color)).brighter(0.5))
                        .style("stroke-width", (d) => if @isSelected(d) then 2 else 0.5)
                        .style("stroke", (d) => if @isSelected(d) then "#0074D9" else @colorScale(d.color))
                        .transition()
                        .duration(1000)
                        .call(@pathStyles)
                @vis.selectAll(".item-text")
                        .style("fill", (d) => if @isSelected(d) then "white" else "black")#@colorScale(d.color))
                        .transition()
                        .duration(1000)
                        .call(@textStyles)


        scaleFor: (d) ->
                if @columnType(d) == COLUMN_TYPE_PARTITION
                        @y2
                else
                        @y

        pathStyles: (s) =>
                s.attr("d", (d) => @pathGenerator(d))
                 .style("opacity",1)
                
        textStyles: (s) =>
                s.attr("x", (d) => @x(d.y+d.dy/2))
                 .attr("y", (d) => @scaleFor(d)(d.r_x + d.r_dx*0.5))
                 .style("opacity", 1)#(d) => if Math.abs(@scaleFor(d)(d.r_dx) - @scaleFor(d)(0)) > MAX_FONT_SIZE then 1 else Math.abs(@scaleFor(d)(d.r_dx) - @scaleFor(d)(0))/MAX_FONT_SIZE)
                 .style("font-size",(d) => if Math.abs(@scaleFor(d)(d.r_dx) - @scaleFor(d)(0)) > MAX_FONT_SIZE then MAX_FONT_SIZE else Math.abs(@scaleFor(d)(d.r_dx) - @scaleFor(d)(0)))
                 .attr("transform",(d) => if @columnType(d) == COLUMN_TYPE_BREADCRUMB then "rotate(90,#{@x(d.y+d.dy/2)},#{@scaleFor(d)(d.r_x + d.r_dx*0.5)})" else "")
                 .text((d) -> d.name)

        click: (clickedNode) =>
                if clickedNode.parent != @selectedNode
                        @selectedNode = clickedNode.parent
                        @selectedChild = clickedNode.index
                else if clickedNode.index != @selectedChild
                        @selectedChild=clickedNode.index
                else
                        @selectedNode=clickedNode
                        @selectedChild=-1
                @applyState()

        keyPress: () =>
                keyCode = d3.event.keyCode
                console.log 'keyCode', keyCode
                if keyCode == 38 #up
                        if @selectedChild==-1 or @selectedChild==0
                                @selectedChild=@selectedNode.children.length-1
                        else
                                @selectedChild-=1
                if keyCode == 40 #down
                        if @selectedChild==-1 or @selectedChild==@selectedNode.children.length-1
                                @selectedChild=0
                        else
                                @selectedChild+=1
                if keyCode == 37 #left
                        if @selectedChild==-1
                                @selectedChild=0
                        else
                                if @selectedNode.children?
                                        @selectedNode=@selectedNode.children[@selectedChild]
                                        @selectedChild=-1
                if keyCode == 39 #right
                        if @selectedChild==-1
                                if @selectedNode.parent?
                                        @selectedChild=@selectedNode.index
                                        @selectedNode=@selectedNode.parent
                        else
                                @selectedChild=-1
                @applyState()
                
        applyState: () =>
                @w = $(@el).width()
                @h = $(@el).height()
                breadcrumbColumnWidth = BREADCRUMB_COLUMN_WIDTH / @w
                tipColumnWidth = TIP_COLUMN_WIDTH / @w
                currentDepth = @selectedNode.depth
                restWidth = 1.0 - tipColumnWidth - breadcrumbColumnWidth * currentDepth
                console.log "widths:",@w,breadcrumbColumnWidth,tipColumnWidth,restWidth,currentDepth
                _.each(@nodes, (d) =>
                        d.columnType = @columnType(d)
                        if d.depth <= currentDepth
                                d.y = breadcrumbColumnWidth*d.depth
                                d.dy = breadcrumbColumnWidth
                        else if d.depth == currentDepth + 1
                                d.y = breadcrumbColumnWidth*d.depth
                                d.dy = tipColumnWidth
                        else
                                d.y = breadcrumbColumnWidth*(currentDepth+1) + tipColumnWidth
                                d.dy = restWidth
                        if @columnType(d) == COLUMN_TYPE_PARTITION
                                d.r_x = d.x
                                d.r_dx = d.dx
                        else
                                d.r_x = d.eq_x
                                d.r_dx = d.eq_dx
                        )
                @visibleNodes = []
                @traverseTree( @selectedNode, ((d) => @visibleNodes.push(d)), @numColumns, true )
                parent = @selectedNode.parent
                while parent?
                        @visibleNodes.push parent
                        parent = parent.parent
                @render()


root = exports ? window
root.Zopamico = Zopamico