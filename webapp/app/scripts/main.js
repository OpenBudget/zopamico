function dataFetcher( node, cb ) {
    if ( node != null ) {
        node = node.target;
    }
    console.log("dataFetcher2 node=",node);
    if ( node == null ) {
        $.get('http://the.open-budget.org.il/api/budget/002038/2014/kids',
        function(data) {
            data = _.filter( data, function(x) { return x.net_allocated > 0; } );
            cb( data,
                function(n) { return n.title; },
                function(n) { return n.net_allocated; },
                function(n) { return { 'תקנות': {'kind': 'budget6', 'prefix': n.code} }; }
            );
        },"jsonp");
    } else
    if ( node.kind == 'budget6' ) {
        $.get('http://the.open-budget.org.il/api/budget/'+node.prefix+'/2014/kids',
        function(data) {
            data = _.filter( data, function(x) { return x.net_allocated > 0; } );
            cb( data,
                function(n) { return n.title; },
                function(n) { return n.net_allocated; },
                function(n) { return { 'תמיכות לפי שנה': {'kind': 'supports-by-year', 'prefix': n.code.substring(2) },
                                       'תמיכות לפי ארגון': {'kind': 'supports-by-org', 'prefix': n.code.substring(2) },
                             }; }
            );
        },"jsonp");
    } else
    if ( node.kind == 'supports-by-year' ) {
        $.get('http://the.open-budget.org.il/api/supports/'+node.prefix,
        function(data) {
            code = node.prefix
            data = _.groupBy( data, function(x) { return x.year; } );
            data = _.pairs( data );
            data = _.map( data, function(x) { return { 'year': x[0], 'value': _.reduce(x[1], function(m,n) { return m+n.amount_allocated; }, 0) }});
            data = _.filter( data, function(x) { return x.value > 0; } );
            cb( data,
                function(n) { return n.year; },
                function(n) { return n.value; },
                function(n) { return { 'פירוט ארגונים': {'kind': 'supports-by-year-detail', 'year': n.year, 'code': code } }; }
            );
        },"jsonp");
    } else
    if ( node.kind == 'supports-by-org' ) {
        $.get('http://the.open-budget.org.il/api/supports/'+node.prefix,
        function(data) {
            code = node.prefix
            data = _.groupBy( data, function(x) { return x.recipient; } );
            data = _.pairs( data );
            data = _.map( data, function(x) { return { 'recipient': x[0], 'value': _.reduce(x[1], function(m,n) { return m+n.amount_allocated; }, 0) }});
            data = _.filter( data, function(x) { return x.value > 0; } );
            cb( data,
                function(n) { return n.recipient; },
                function(n) { return n.value; },
                function(n) { return { 'פירוט שנים': {'kind': 'supports-by-org-detail', 'recipient': n.recipient, 'code': code } }; }
            );
        },"jsonp");
    } else
    if ( node.kind == 'supports-by-year-detail' ) {
        $.get('http://the.open-budget.org.il/api/supports/'+node.code,
        function(data) {
            code = node.code
            data = _.filter( data, function(x) { return x.year == node.year; } );
            cb( data,
                function(n) { return n.recipient; },
                function(n) { return n.amount_allocated; },
                function(n) { return {}; }
            );
        },"jsonp");
    } else
    if ( node.kind == 'supports-by-org-detail' ) {
        $.get('http://the.open-budget.org.il/api/supports/'+node.code,
        function(data) {
            code = node.code
            data = _.filter( data, function(x) { return x.recipient == node.recipient; } );
            cb( data,
                function(n) { return n.year; },
                function(n) { return n.amount_allocated; },
                function(n) { return {}; }
            );
        },"jsonp");
    }
    // } else {
    //     node = node*10;
    // }
    // var ret = [];
    // for ( var i = 1 ; i < 25 ; i++ ) {
    //     ret.push( node*i );
    // }
    // cb( ret,
    //     function(n) { return "node"+n; },
    //     function(n) { return n; },
    //     function(n) { return { 'next1' : n, 'next2' : n+3 }; }
    // );
}

$( function() {
   console.log('Hello World!');
    console.log('window',window);
    console.log('window',window.Zopamico);
    var z = new window.Zopamico("#chart", dataFetcher );
    //console.log(z);
    //console.log(z.tree);
    //z.render();
} );

console.log("Hello!");
