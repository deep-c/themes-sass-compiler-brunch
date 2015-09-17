# themes-compiler-brunch

Adds support for a themes based compiling process whereby a master theme is used to create multiple additional themes that can overrride imported files to provide a completely unique theme.

Example brunch project with themeing

    PROJECT FOLDER  
      app  
          /base (this is the master theme)
              /sass
              /js
          /theme2   
              /sass
              /js
          /theme3
              /sass
              /js
          ...  
      node_modules  
      brunch-config.coffee  
      package.json  
      ...  

If a file of the same name exists in another theme other than 'base' then that file will replace the file in base when compiling the css file for that theme (imports as well).

For example

    PROJECT FOLDER  
      app  
          /base (this is the master theme)
              /sass  
                  /partials
                      _header.scss  
                  base.scss (this file imports _header.scss using import) 
          /theme2 
              /sass  
                  /partials
                      _header.scss (custom _header.scss file)

Then base.scss is rendered for each theme:  

    FOR base 
        {output-folder}/base.css (import uses the header.scss file located in base theme when import is referenced) 
    FOR theme2  
        {output-folder}/base.css (import uses the header.scss file located in theme2 theme when import is referenced)  
Example brunch-config file

    exports.config =
      # See http://brunch.io/#documentation for docs.
      paths:
        public: "../../theme/static-test"
      files:
        stylesheets:
          joinTo:
            "base/css/base.css": /^app\/themes\/base\/sass\/base.*/
        javascripts:
          joinTo:
            "base/js/app.js": /^app\/themes\/base\/js/
            "base/js/vendor.js": /^app\/themes\/base\/vendor/
      overrides:
        theme1:
          files:
            stylesheets:
              joinTo:
                "theme1/css/base.css": /^app\/themes\/base\/sass\/base.*/
            javascripts:
              joinTo:
                "theme1/js/app.js": /^app\/themes\/carbon\/js/
                "theme1/js/vendor.js": /^app\/themes\/carbon\/vendor/
        theme2:
          files:
            stylesheets:
              joinTo:
                "theme2/css/base.css": /^app\/themes\/base\/sass\/base.*/
            javascripts:
              joinTo:
                "theme2/js/app.js": /^app\/themes\/krypton\/js/
                "theme2/js/vendor.js": /^app\/themes\/krypton\/vendor/
      plugins:
        themes:
          options:
            directory: 'themes'
            base: 'base'
            styles: 'sass'

###To build:###
+ base - brunch build  
+ theme1 - brunch build --env theme1  
+ theme2 - brunch build --env theme2  

Known Issues  
+ ~~Currently file import substition only works with scss not sass due to pattern matching error~~
+ ~~Had to circumvent brunch pipline callback on compile due to being unable to control multiple files being written based on single path passed to compile.~~
