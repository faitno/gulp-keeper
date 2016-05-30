#'use strict'
gulp = require 'gulp'
$ = require('gulp-load-plugins')(
	rename:
		'main-bower-files'  : 'gulp-bowerss'
		'gulp-minify-css'   : 'minifycss'
		'gulp-ruby-haml'    : 'rubyhaml'
		'gulp-strip-css-comments'   : 'stripcsscomments'
		'gulp-batch-replace': 'batchreplace'
		'gulp-ext-replace'	: 'extreplace'
	pattern: [
		'gulp-*'
		'gulp.*'
	]
	replaceString: /\bgulp[\-.]/
	lazy: true
	camelize: true)

fs = require('fs')
gulpconfig = JSON.parse(fs.readFileSync('gulpconfig.json'))
if gulpconfig.htmlMin_removeComments == undefined
	gulpconfig.htmlMin_removeComments = true

del = require('del')
browserSync = require('browser-sync')
reload = browserSync.reload
runsequence = require('run-sequence')

lazypipe = require('lazypipe')
cssMin 		= lazypipe()
	.pipe -> $.plumber()
	.pipe -> $.postcss([ require('autoprefixer')(browsers: [ '> 3%', 'IE 7' ]) ])
	.pipe -> $.plumber()
	.pipe -> $.stripcsscomments({preserve : false})
	.pipe -> $.plumber()
	.pipe -> $.minifycss(compatibility: 'ie7')

htmlMin		= lazypipe()
	.pipe -> $.htmlmin(
		collapseWhitespace: true
		conservativeCollapse: true
		removeComments: gulpconfig.htmlMin_removeComments
		removeCommentsFromCDATA: true
		minifyJS: true
		minifyCSS: false
		customAttrSurround:[
			[/\{\$/
			/\}\=\"\"/]
			[/\{\$/
			/\}/]
			[/\{\{.{1}/
			/\}\}/]
			[/\[\[.{1}/
			/\]\]/]
			[/{[^}]+}/
			/{\/[^}]+}/]
		])
	#"
	.pipe -> $.batchreplace([
		['checkeded','checked']
		['disableded','disabled']
		['ed}=""','ed}']
		['> <time','><time']
		['<h-level--1','<h{$level+1}']
		['</h-level--1','</h{$level+1}']
	])

gulp.task 'uglify', ->
	gulp.start 'uglify-head'
	gulp.src gulpconfig.uglify
	.pipe $.plumber()
	.pipe $.concat('js.js')
	.pipe $.uglify()
	.pipe gulp.dest 'www/scripts'

gulp.task 'uglify-head', ->
	gulp.src [ 'bower_components/modernizr/modernizr.js' ]
	.pipe $.plumber()
	.pipe $.concat 'head.js'
	.pipe $.uglify()
	.pipe gulp.dest 'www/scripts'

gulp.task 'script_engine', ->
	del './app/scripts/js/*.*'
	gulp.src 'app/scripts/*.{coffee,js}'
	.pipe $.plumber()
	.pipe $.if('**/*.coffee', $.coffee())
	.pipe $.uglify()
	.pipe gulp.dest 'app/scripts/js'

gulp.task 'scripts', ->
	gulp.start 'scripts-separate'
	gulp.src [
		'./app/scripts/js/*.js'
		'!./app/scripts/js/*-redactor.js'
		'!./app/scripts/js/*-sep.js'
		'!./app/scripts/js/*-pass.js'
	]
	.pipe $.concat 'scripts.js'
	.pipe gulp.dest './www/scripts'
gulp.task 'scripts-separate', ->
	gulp.src [
		'./app/scripts/js/*-redactor.js'
		#'./app/scripts/js/*-sep.js'
	]
	#.pipe $.batchreplace('-sep.js', '.js')
	.pipe gulp.dest './www/scripts'


gulp.task 'style_engine', ->
	gulp.src './app/styles/*.{scss,less,styl}'
	.pipe $.if('**/*.scss', $.sass({outputStyle: 'compressed',precision: 10}))
	.on 'error', $.sass.logError
	.pipe $.if('**/*.less', $.less())
	.pipe $.if('**/*.styl', $.stylus())
	.pipe cssMin()
	.pipe gulp.dest './app/styles/css'

gulp.task 'styles', ->
	gulp.start 'styles-separate'
	gulp.src [
		'app/styles/css/*.css'
		'!app/styles/css/*-redactor.css'
	]
	.pipe $.concat('main.css')
	.pipe gulp.dest './www/styles'
gulp.task 'styles-separate', ->
	gulp.src 'app/styles/css/*-redactor.css'
	.pipe gulp.dest './www/styles'


gulp.task 'scss-redactor', ->
	gulp.src './app-redactor/styles/*.scss'
	.pipe $.sass
		outputStyle: 'compressed'
		precision: 10
		includePaths: [ '.' ]
	.on 'error', $.sass.logError
	.pipe cssMin()
	.pipe gulp.dest './app-redactor/styles/css'

gulp.task 'styles-redactor', ->
	gulp.src './app-redactor/styles/css/*.css'
	.pipe gulp.dest './www/redactor/templates/custom/css'

gulp.task 'template_engine', ->
	del './app/templates/html/*.*'
	#gulp.src './app/templates/*.{jade,haml}'
	gulp.src [
		'./app/templates/*.jade'
		#'!./app/templates/*-notmin.jade'
	]
	.pipe $.plumber()
	.pipe $.jade(pretty: false)
	#.pipe $.if('**/*.jade', $.jade(pretty: true))
	#.pipe $.if('**/*.haml', $.rubyhaml())
	#.pipe $.if('**/*.jade', $.jade(pretty: true))
	#.pipe $.if('**/*.haml', $.rubyhaml())
	.pipe $.if('!**-notmin**', htmlMin())
	.pipe $.if('**-notmin**', $.batchreplace([['~tab~\n','	']]))
	#.pipe htmlMin()
	.pipe gulp.dest './app/templates/html'

#	gulp.src [
#		'./app/templates/*-notmin.jade'
#	]
#	.pipe $.plumber()
#	.pipe $.jade(pretty: false)
#	.pipe $.batchreplace([
#		['~tab~\n','	']
#	])
#	.pipe gulp.dest './app/templates/html'

gulp.task 'html', ->
	gulp.src 'app/templates/html/*.html'
	.pipe $.if('**/chunk-*.html', gulp.dest('www/core/elements/chunks'), gulp.dest('www/core/elements/templates'))

gulp.task 'images', ->
	gulp.src ['app/images/**/*', '!app/images/**/*.jpg']
	.pipe $.cached 'srcImages'
	.pipe $.imagemin
		progressive: false	#jpg
		interlaced: true	#gif
		multipass: true		#svg
		svgoPlugins: [ { cleanupIDs: false } ]
	.pipe gulp.dest 'www/images'

	gulp.src '!app/images/**/*.jpg'
	.pipe $.cached 'srcImages2'
	.pipe $.copy 'www/images', prefix: 5

gulp.task 'make-cache', ->
	del [
		'./app/templates/html/*.*'
		'./www/core/elements/templates/*.*'
		'./www/core/elements/chunks/*.*'

		'./app/styles/css/*.*'
		'./www/styles/*.*'

		'./app/scripts/js/*.*'
	]
	gulp.src ['www/**/*', '!www/**/*.{JPG,jpg,jpeg,gif,bmp,png,svg}']
	.pipe $.cached 'dstUpload'

gulp.task 'upload2', ->
	if gulpconfig.noupload == undefined or gulpconfig.noupload == false
		gulp.src ['www/**/*', '!www/**/*.{JPG,jpg,jpeg,gif,bmp,png,svg}']
		.pipe $.cached 'dstUpload'
		.pipe $.plumber()
		.pipe $.sftp(
			host: gulpconfig.host
			user: gulpconfig.user
			pass: gulpconfig.passphrase
			remotePath: '/jail/home/'+gulpconfig.user+'/www/'
			key:
				location: './../../keys/private_key_'+gulpconfig.user
				passphrase: gulpconfig.passphrase)
	else
		gulp.src('www/**/*')
		.pipe($.cached('dstUpload'))
		.pipe reload(stream: true)

gulp.task 'watch', ->
	$.watch 'app/scripts/*.{js,coffee}', ->
		runsequence 'script_engine','scripts'
	$.watch 'www/scripts/**/*.js', ->
		runsequence 'upload2'

	$.watch 'app/templates/**/*.{jade,haml}', ->
		runsequence 'template_engine','html'
	$.watch 'www/core/elements/**/*.html', ->
		runsequence 'upload2'

	$.watch 'app/styles/**/*.{scss,less,styl}', ->
		runsequence 'style_engine','styles'
	$.watch 'www/styles/**/*.css', ->
		runsequence 'upload2'

	$.watch './app-redactor/styles/**/*.scss', ->
		runsequence 'scss-redactor', 'styles-redactor'
	$.watch './app-redactor/styles/**/*.css', ->
		runsequence 'upload2'

	#$.watch 'app-redactor/**/*.scss', ->
	#	runsequence 'styles-redactor', 'upload2'

	if gulpconfig.noupload != undefined and gulpconfig.noupload == true
		browserSync server: baseDir: './www'
		#browserSync server: baseDir: './www/core/elements/templates'

gulp.task 'default', ->
	runsequence 'make-cache', [
		#'images'
		'uglify'
		'styles-redactor'
		'template_engine'
		'style_engine'
		'script_engine'
	], [
		'html'
		'styles'
		'scripts'
	],'watch'