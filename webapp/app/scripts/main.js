$( function() {
   console.log('Hello World!');
    console.log('window',window);
    console.log('window',window.Zopamico);
    var z = new window.Zopamico("#chart", window.data, ['l1','l2','l3','l4'],'value');
    console.log(z.tree);
    z.render();
} );
