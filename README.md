# themes-compiler-brunch

Adds support for a themes based compiling process whereby a master theme is used to create multiple additional themes that can overrride imported files to provide a completely unique theme.

Example brunch project with themeing

+ PROJECT FOLDER  
    - app  
        - base (this is the master theme)
            - sass
            - js
        - theme 2   
            - sass
            - js
        - theme 3
            - sass
            - js
        - ...  
    - node_modules  
    - brunch-config.coffee  
    - package.json  
    - ...  

If a file of the same name exists in another theme other than 'base' then that file will replace that file (imports as well).


