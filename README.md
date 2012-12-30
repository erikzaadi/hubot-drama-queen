## Hubot Drama Queen [![Build Status](https://secure.travis-ci.org/erikzaadi/jQuery.printElement.png?branch=master)](http://travis-ci.org/erikzaadi/hubot-drama-queen)

![Hubot Drama Queen](http://cdn.memegenerator.net/instances/400x/32646936.jpg "Announce me hubot!!")

###  Make Hubot announce when a user enters or exits a chat room

#### Commands:
Announce *message* when user enters|joins the chat *room*
    
    hubot drama set <join|leave> of <room> to <message>

Cancel the announcement for the chat *room*
    
    hubot drama clear <join|leave> of <room>

List the rooms the user has messages for
    
    hubot drama list all

List all the messages for the chat *room
    
    hubot drama list <room>
    
#### License
**MIT**

#### Installation:
```curl|wget https://github.com/erikzaadi/hubot-drama-queen/raw/master/src/scripts/dramaqueen.coffee```  to your hubot installation's ```scripts``` folder.

or

In your deployed ```hubot``` directory:

    npm i --save hubot-drama-queen
    ln -s node_modules/hubot-drama-queen/src/scripts/dramaqueen.coffee node_modules/hubot-scripts/src/scripts/dramaqueen.coffee

And add ```dramaqueen.coffee``` to your ```hubot-scripts.json``` file.

#### Hacking:
    npm i -d
    make test #single test run
    make test-pretty #single spec style run
    make test-watch #continuous minimal run
    make test-pretty-watch #continuous spec style run
    
