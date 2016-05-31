# Gulp keeper.

Deployment system based on gulp, jade, haml, htmlmin, scss, less, postcss, minify-css, coffescript, uglify, imagemin and upload sftp only changed files (or browser-sync if not upload).

## First steps to use gulp keeper as compile and deployment engine

- Clone this repository `git clone https://github.com/soulcreate/gulp-keeper`
- install coffescript global for run `gulpfile.coffee`
- edit `/gulpconfig.json` for your environments
   - set `uglify` object to list of javascript files that need to minify (uglify) and not change during development (eq library jquery, sliders and over). It minify in first run, and not touch in over time. If you change list of this javascript, please re-run `default` gulp task
   - `host` - content host to deployment with sftp
   - `user` - username for sftp
   - `passphrase` - pass gor sftp (or passphrase for key)
   - `noupload` - set true if you not need deployment with sftp. If set true, start localy browser with browser-sync.
   - `htmlMin_removeComments` - if set true, in html (jade, haml) remove `<!--` `-->` comments.

## Gulp coffeescript concat, compile and deployment with sftp

Create files of coffeescript and javascript in folder `/app/scripts/`. It compile and concat and send to folder `/app/scripts/js/` folder, after that, it send to folder `/www/scripts/` folder, after that it upload with sftp or reload browser with browser-sync (if `noupload` in `/gulpconfig.json` set to `true`)

## Gulp jade (haml) compile, htmlmin and deployment with sftp (or browser-sync)

Create files in folder `/app/templates/` with `.jade` extesion and it compile such coffescript.