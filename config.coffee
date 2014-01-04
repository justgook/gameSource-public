pjson = require('./package.json');
exports.config =
    # See http://brunch.io/#documentation for docs.
    paths:
        public: 'public'
    files:
        javascripts:
            joinTo:
              "app.js": /^app/
              "vendor.js": /^bower_components/
            order:
              after: ['app/initialize.coffee']
        stylesheets:
            joinTo:
              "app.css": /^app/
              "vendor.css": /^bower_components/
        templates:
            joinTo: 'templates.js'
    plugins:
        uglify:
            mangle: yes
            compress:
                global_defs:
                    DEBUG: yes
        jade:
            # pretty: yes # Adds pretty-indentation whitespaces to output (false by default)
            compileDebug: no
            locals:
                VERSION: pjson.version
                NAME: pjson.name
                AUTHOR: pjson.author
                HOMEPAGE: pjson.homepage
                LICENSE: pjson.license
            # debug: yes
        static_jade:                       # all optionals
            extension:  ".static.jade"              # static-compile each file with this extension in `assets`
            path:       [ /app/ ] # static-compile each file in this directories
            asset:      "public"
