class Zopamico

  TIP_WIDTH = 400
  STACK_WIDTH = 30
  TIP_HEIGHT = 50

  constructor: (element, dataFetcher) ->
    console.log 'ctor'
    @el = element
    @vis = d3.select(@el)
            .append("svg:svg")
            .attr("width", "100%")
            .attr("height", "100%")
    @w = $(@el).width()
    @h = $(@el).height()

    @slider = @vis.append('svg:g')
                  .attr('class','slider')
    @slider.append('line')
           .attr('x1',0)
           .attr('y1',0)
           .attr('x2',0)
           .attr('y2',@h)
           .style('stroke-width',1)
           .style('stroke','#888')
    handle = @slider.append('rect')
                    .attr('class','slider-handle')
                    .attr('x',-5)
                    .attr('y',0)
                    .attr('width',10)
                    .attr('height',25)
                    .style('fill',"#400")

    @drag = d3.behavior.drag()
            .on("drag",
                (d) =>
                  y = d3.event.y
                  lastNodes = @nodeList[@nodeList.length - 1]
                  max_height = @h - 25
                  if y < 0
                    y = 0
                  if y > max_height
                    y = max_height
                  lastNodes.offset = y / max_height
                  @render()
    )
    @vis.on 'mousewheel',
            =>
              lastNodes = @nodeList[@nodeList.length - 1]
              lastNodes.offset += 0.001 * d3.event.wheelDelta
              if lastNodes.offset > 1
                  lastNodes.offset = 1
              if lastNodes.offset < 0
                  lastNodes.offset = 0
              #console.log 'wheel',lastNodes.offset, d3.event
              @render()
    handle.call(@drag)

    @x = d3.scale.linear().domain([0,@w]).range([0,@w])
    @y = d3.scale.linear().domain([0,1]).range([0,@h])
    @dataFetcher = dataFetcher
    @nodeList = []
    @fetch(null)

  fetch: (next) ->
    console.log 'fetch'
    # if @nodeList.length > 0
    #   selectedNode = @nodeList[@nodeList.length - 1].selectedNode.src
    # else
    #   selectedNode = null

    @dataFetcher(next,
                 (nodes,getTitle,getValue,getNexts) =>
                   @onData(nodes,getTitle,getValue,getNexts)
                )

  processData: (nodes,getTitle,getValue,getNexts) ->
    console.log getValue, getNexts
    nodes = _.map( nodes,
                   (node) =>
                     title: getTitle(node)
                     value: getValue(node)
                     nexts: _.map( _.pairs(getNexts(node)),
                                   (d) -> {name:d[0], target:d[1]} )
                     level: @nodeList.length
                     src: node
                  )
    nodes = _.sortBy(nodes, (x) -> -x.value )
    sum = _.reduce( nodes,
                    (m,n) ->
                      m + n.value
                    ,0 )
    _.reduce( nodes,
              (m,n) ->
                n.index = m
                m + 1
              ,0 )
    _.reduce( nodes,
              (m,n) ->
                n.y = m / sum
                n.dy = n.value / sum
                m + n.value
              ,0 )
    _.each( nodes,
               (n) ->
                 _.each( n.nexts,
                         (x) -> x.src = n
                        )
              )
    console.log "processData: nodes=",nodes
    return nodes

  onData: (nodes,getTitle,getValue,getNexts) =>
    console.log 'onData',nodes
    nodes = @processData( nodes, getTitle, getValue, getNexts )
    pack =
        nodes: nodes
        selectedNode: nodes[0]
        offset: 0

    @nodeList.push( pack )
    @render()

  selectNodes: ->
    @nodes = []
    for i in [0..@nodeList.length - 2]
      if i < 0
        continue
      #console.log "selectNodes: nodes", i, @nodeList[i]
      @nodes.push( @nodeList[i].selectedNode )
    pack = @nodeList[@nodeList.length - 1]
    for i in [0..pack.nodes.length - 1]
      @nodes.push( pack.nodes[i] )

  pathGenerator: (y,dy,cy,dcy,x,dx) ->
    MID_POINT = 0.25
    BEZ_POINT = 0.7
    mid1 = x + dx * MID_POINT
    mid2 = x + dx * (1 - MID_POINT)
    bez_1_1 = x * (1 - BEZ_POINT) + mid1 * BEZ_POINT
    bez_1_2 = x * BEZ_POINT + mid1 * (1 - BEZ_POINT)
    bez_2_1 = mid2 * (1 - BEZ_POINT) + (x + dx) * BEZ_POINT
    bez_2_2 = mid2 * BEZ_POINT + (x + dx) * (1 - BEZ_POINT)

    [ "M#{x},#{y}"
      "M#{x},#{y+dy}"
      "C#{bez_1_1},#{y+dy},#{bez_1_2},#{cy+dcy},#{mid1},#{cy+dcy}"
      "L#{mid2},#{cy+dcy}"
      "C#{bez_2_1},#{cy+dcy},#{bez_2_2},#{y+dy},#{x+dx},#{y+dy}"
      "M#{x+dx},#{y}"
      "C#{bez_2_2},#{y},#{bez_2_1},#{cy},#{mid2},#{cy}"
      "L#{mid1},#{cy}"
      "C#{bez_1_2},#{cy},#{bez_1_1},#{y},#{x},#{y}"
    ].join(" ")

  render: ->
    @selectNodes()
    _stackNodes = _.filter( @nodes, (x) => x.level < @nodeList.length - 1 )
    _tipNodes = _.filter( @nodes, (x) => x.level == @nodeList.length - 1 )
    lastNodes = @nodeList[@nodeList.length - 1]
    selected = lastNodes.selectedNode
    nexts = if selected? then selected.nexts else []
    offset = lastNodes.offset

    max_offset = lastNodes.nodes.length * TIP_HEIGHT - @h
    if max_offset < 0
      max_offset = 0
    rectsOffset = -offset * max_offset
    sliderOffset = offset * (@h - 25)

    # TIP nodes
    tipNodes = @vis.selectAll(".tip-node")
                   .data(_tipNodes, (d) -> "#{d.level}/#{d.title}")
    newTipNodes = tipNodes.enter()
                          .append('svg:g')
                          .attr("class","tip-node")

    ## Partition view
    newTipNodes
        .append('svg:path')
          .attr('class','partition-view')
          .style("stroke-width",1)
          .style("fill","none")
    tipNodes.selectAll('.partition-view')
          .attr("d", (d) => @pathGenerator(@y(d.y),
                                           @y(d.dy),
                                           rectsOffset + (d.index * TIP_HEIGHT),
                                           TIP_HEIGHT,
                                           @x(d.level * STACK_WIDTH),TIP_WIDTH))
          .style("stroke",(d) -> if d == selected then "#444" else "#ccc")
          .style("opacity",(d) -> if d == selected then 1 else 0.2)

    ## Miller rect
    newTipNodes
        .append('svg:rect')
          .attr('class','miller-rect')
          .attr("x", (d) => @x((d.level * STACK_WIDTH)))
          .attr("width",TIP_WIDTH)
          .attr("height", TIP_HEIGHT)
          .style("stroke","#800")
          .style("stroke-width",1)
          .style("fill","#000")
          .style("opacity","0")
          .on("mouseenter",
              (d) =>
                #console.log "hover",d
                @nodeList[@nodeList.length - 1].selectedNode = d
                @render()
           )
    tipNodes.selectAll('.miller-rect')
          .attr("y", (d) -> rectsOffset + (d.index * TIP_HEIGHT))

    ## Miller text
    newTipNodes
        .append('svg:text')
        .attr('class','miller-text')
        .attr("x", (d) => @x((d.level * STACK_WIDTH) + TIP_WIDTH / 2))
        .attr("dx", 20)
        .attr("dy", 20)
        .style('text-anchor','middle')
        .text((d) -> d.title)
    tipNodes.selectAll('.miller-text')
        .attr("y", (d) -> rectsOffset + (d.index * TIP_HEIGHT))
    tipNodes.exit().remove()

    # NEXTS
    nextLinks = @vis.selectAll(".nexts")
                    .data(nexts, (d) -> "#{d.name}/#{d.src.value}/#{d.src.title}")
    nextLinks.enter()
             .append("svg:text")
             .attr("class","nexts")
             .attr("x", (d,i) => @x((d.src.level * STACK_WIDTH) + TIP_WIDTH * 0.7 - 100 * i))
             .attr("dx", 20)
             .attr("dy", 40)
             .style('text-anchor','end')
             .style('cursor','hand')
             .text((d) -> d.name)
             .on("click",
                 (d) =>
                   console.log "click",d
                   @fetch(d)
                )
    nextLinks.exit().remove()
    nextLinks
        .attr("y", (d) -> rectsOffset + (d.src.index * TIP_HEIGHT))


    # STACK nodes
    stackNodes = @vis.selectAll(".stack-node")
                    .data(_stackNodes)
    newStackNodes = stackNodes.enter()
                              .append('svg:g')
                              .attr("class",'stack-node')
    newStackNodes
        .append('svg:rect')
        .attr("x", (d) => @x(d.level * STACK_WIDTH))
        .attr("y", 0)
        .attr("width", STACK_WIDTH)
        .attr("height", @h)
        .style("stroke","#000")
        .style("stroke-width",1)
        .style("fill","#fff")
        .on("click",
            (d) =>
              console.log "stack click",d
              @nodeList = @nodeList[0..d.level]
              @render()
           )
    newStackNodes
        .append('svg:text')
        .attr("x", 0)
        .attr("y", (d) => -@x((d.level * STACK_WIDTH)))
        .attr("dx", 20)
        .attr("dy", -STACK_WIDTH / 2)
        .attr("transform","rotate(90)")
        .text((d) -> d.title)
    stackNodes.exit().remove()

    # SLIDER
    d3.select('.slider')
      .attr('transform',
            "translate(#{_stackNodes.length * STACK_WIDTH + TIP_WIDTH+10},0)")
    d3.select('.slider-handle')
      .attr('transform',
            "translate(0,#{sliderOffset})")
    #console.log 'slider',_stackNodes.length * STACK_WIDTH + TIP_WIDTH


root = exports ? window
root.Zopamico = Zopamico
