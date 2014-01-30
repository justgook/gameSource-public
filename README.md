#READ this !!!

http://docpad.org/docs/intro


#find some good solution to abstract DB
https://github.com/bevry/query-engine

#run test

As a some kind of workaround (though not very handy), you can do as follows:

Say your package name from package.json is myPackage and you have also

```
"scripts": {
    "start": "node ./script.js server"
}
```
Then add in package.json:

```
"config": {
    "myPort": "8080"
}
```

And in your script.js:

```
// defaulting to 8080 in case if script invoked not via "npm run-script" but directly
var port = process.env.npm_package_config_myPort || 8080
```

That way, by default npm start will use 8080. You can however configure it (the value will be stored by npm in its internal storage):

```
npm config set myPackage:myPort 9090
```

Then, when invoking npm start, 9090 will be used (the default from package.json gets overridden).

---------------

You could put it as a bin:

```
"bin": {
    "start": "./script.js server"
}
```

Then you would run start 8080 to start your server. Although if you do it this way, you probably should give it a better name than start.



###Design
[sidepanels](http://foundation.zurb.com/docs/components/offcanvas.html#)

[loadingScreen](https://teamtreehouse.com/forum/html5-page-loading-screen)


###HTML taging
http://www.w3.org/TR/wai-aria/roles

#SEO!!!
http://www.data-vocabulary.org/
https://support.google.com/webmasters/answer/99170

#gameSource front-end

[![Build Status](https://travis-ci.org/justgook/gameSource-public.png)](https://travis-ci.org/justgook/gameSource-public)
[![dependency Status](https://david-dm.org/justgook/gameSource-public.png)](https://david-dm.org/ModelN/backbone.subroute#info=devDependencies)
[![Coverage Status](https://coveralls.io/repos/justgook/gameSource-public/badge.png)](https://coveralls.io/r/chaijs/chai?branch=master)

for ideas http://www.hongkiat.com/blog/flat-ui-design-showcase/

http://foundation.zurb.com/

####links for jquery deprication
promises - http://www.html5rocks.com/en/tutorials/es6/promises/


###integration testing
http://boycook.wordpress.com/2013/03/30/integration-testing-node-js-web-apps-with-javascript/
http://nodejs.org/api/child_process.html#child_process_event_message