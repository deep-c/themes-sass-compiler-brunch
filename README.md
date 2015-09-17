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

Known Issues  
+ ~~Currently file import substition only works with scss not sass due to pattern matching error~~
+ ~~Had to circumvent brunch pipline callback on compile due to being unable to control multiple files being written based on single path passed to compile.~~
