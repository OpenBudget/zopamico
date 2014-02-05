# Generated on 2014-02-01 using generator-bower 0.0.1
'use strict'

mountFolder = (connect, dir) ->
    connect.static require('path').resolve(dir)

module.exports = (grunt) ->
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  yeomanConfig =
    src: 'src'
    dist : 'dist'
  grunt.initConfig
    yeoman: yeomanConfig
    coffee:
      dist:
        files: [
          expand: true
          cwd: '<%= yeoman.src %>'
          src: '{,*/}*.coffee'
          dest: '<%= yeoman.dist %>'
          ext: '.js'
        ]
    uglify:
      build:
        src: '<%=yeoman.dist %>/zopamico.js'
        dest: '<%=yeoman.dist %>/zopamico.min.js'
    watch:
      coffee:
        files: ['src/*.coffee']
        tasks: ['coffee']
    mochaTest:
      test: 
        options: 
          reporter: 'spec'
          compilers: 'coffee:coffee-script'
        src: ['test/**/*.coffee']

  grunt.registerTask 'default', [
      'mochaTest'
      'coffee'
      'uglify'
    ]

  grunt.registerTask 'serve', [
      'coffee'
      'uglify'
      'watch'
    ]
