# node-runner: Simple Dockerised Node.js Script Runner
 
Rob Tweed <rtweed@mgateway.com>  
27 March 2025, MGateway Ltd [http://www.mgateway.com](http://www.mgateway.com)  

Twitter: @rtweed

# Background

This repository provides the source Dockerfile and associated script files
for the *rtweed/node-runner* Docker Container which is hosted on Docker Hub.

The container provides a means of executing a Node.js script without Node.js
being physically installed on a Linux server.  Instead, all you need is Docker
to be installed, and you can create and run Node.js scripts that you define
as JavaScript text files on your host server.

# Installing the *node-runner* Container

        docker pull rtweed/node-runner

  Note: for ARM64 systems such as the Raspberry Pi or Mac:

        docker pull rtweed/node-runner-arm64

  and add *-arm64* to all references to the *rtweed/node-runner* Container/Image name in this documentation.

# Getting Started with the *node-runner* Container

First, determine (and if necessary create) the folder on your host server that you want to map
into the *node-runner* Container's */node* directory.

In these instructions, I'll assume you're using a folder named *~/test*

In this folder, create a Node.js script file.  By default, the *node-runner* will look
for a script file named *node-script.js*.

The script file MUST be a Node.js module that defines a function.  The function will
not have any arguments.

So, for example, create a file with the path *~/test/node-script.js* that contains:

        module.exports = function() {
          console.log('*** This is my script! ***');
        };

Now you can run your script by doing the following:

        docker run -it --name node-runner --rm -v ~/test:/node rtweed/node-runner


You should see the following:


        > node-runner@0.0.1 start /src
        > NODE_PATH=/src node node-runner.js
        
        *************** Welcome to Node Runner ***************
        *************** Node Runner will now invoke your script ***************
        
        *** This is my script! ***
        
        *************** Node Runner will now terminate ***************


Congratulations! Your Node.js script has been invoked by *node-runner*.

Notice how the *node-runner* Container automatically terminated when your script was completed.


# Customising the Script Name to be Invoked

If you want the *node-runner* to invoke a different Script file, you can define its name using the
environment variable *node_script* when you start the Container.

For example, rename your script file from *node-script.js* to *myScript.js*.

You can now invoke it with the following:

        docker run -it --name node-runner --rm -v ~/test:/node -e "node_script=myScript" rtweed/node-runner


# What can you do in your Script File?

The answer is anything you like, within the mapped volume!

Anything your script does will be ephemeral **UNLESS** it makes any modifications to
files within the mapped volume.

Your script has full read/write access to the mapped volume, so any changes you make to files or
sub-folders within it will take effect permanently on the host system.

The *node-runner* Container is therefore useful for:

- running ad-hoc Node.js scripts for testing or demonstration purposes
- creating installation or configuration scripts, eg to create files that can be run in
other Containers.


# What Version of Node.js will my Script be Running in?


The *node-runner* Container uses Node.js version 12



# Can your Script load and access other modules from NPM?

Yes.  If your script requires any additional external NPM modules, create a file
named *npm_install.json* within the directory that you will be mapping.

This file must define an array of modules that you wish to install before running
your Script.

For example, create a file with the path *~/test/npm_install.json* containing:

        [
          "moment"
        ]

**NOTE:** This will be loaded as a JSON file, so MUST contain proper JSON syntax only.
eg All array elements must be double-quoted, and the file cannot contain any comments.


Run the *node-runner* container again:


        docker run -it --name node-runner --rm -v ~/test:/node -e "node_script=myScript" rtweed/node-runner


This time you'll see:

        > node-runner@0.0.1 start /src
        > NODE_PATH=/src node node-runner.js
        
        *************** Welcome to Node Runner ***************
        
        Installing module: moment
        ** NODE_PATH updated to: /node:/src
        Installing moment at  --prefix /node
        npm WARN saveError ENOENT: no such file or directory, open '/node/package.json'
        npm notice created a lockfile as package-lock.json. You should commit this file.
        npm WARN enoent ENOENT: no such file or directory, open '/node/package.json'
        npm WARN node No description
        npm WARN node No repository field.
        npm WARN node No README data
        npm WARN node No license field.
        
        + moment@2.24.0
        added 1 package from 6 contributors and audited 1 package in 0.717s
        found 0 vulnerabilities
        
        
        moment installed
        *************** Node Runner will now invoke your script ***************
        
        *** This is my script! ***
        
        *************** Node Runner will now terminate ***************

You can see that it installed the *moment* module from NPM.  The warnings can be ignored.

If you now look at the folder you mapped, you'll see that a sub-directory named *node_modules*
has been created, and it will contain the module(s) you asked it to load.

If you try running your script again, this time it will see that the modules in your *npm_install.json*
file have already been loaded in a previous run, so it will not re-load them, eg:

        docker run -it --name node-runner --rm -v ~/test:/node -e "node_script=myScript" rtweed/node-runner

        > node-runner@0.0.1 start /src
        > NODE_PATH=/src node node-runner.js
        
        *************** Welcome to Node Runner ***************
        
        Installing module: moment
        ** NODE_PATH updated to: /node:/src
        moment already installed
        *************** Node Runner will now invoke your script ***************
        
        *** This is my script! ***
        
        *************** Node Runner will now terminate ***************


So now we have loaded the *moment* module, our script can use it.  Let's change it as
follows:
        
        module.exports = function() {
          var moment = require('moment');
          console.log('*** This is my script! ***');
          console.log('Today is ' + moment().format("YYYY Do MM"));
        };


Now when we run it:

        docker run -it --name node-runner --rm -v ~/test:/node -e "node_script=myScript" rtweed/node-runner

We should see something like:

        *************** Node Runner will now invoke your script ***************
        
        *** This is my script! ***
        Today is 2019 4th 11
        
        *************** Node Runner will now terminate ***************


**Note**: you cannot *require* external modules outside your *module.exports* function.

ie the following will NOT be guaranteed to work and may generate a run-time error:

        var moment = require('moment');
        module.exports = function() {
          console.log('*** This is my script! ***');
          console.log('Today is ' + moment().format("YYYY Do MM"));
        };


# How Many Modules can my Script Load?

As many as you like.  Just add them to the array defined by your *npm_install.json* file.


# Can I specify a Particular Module Version in my *npm_install.json* file?

Yes. Simply add the version number after the module name, using @ as the delimiter, eg:

        [
          "moment@1"
        ]


# Can I Reset the Node Modules that have been Previously Loaded?

Yes, you can simply delete the *node_modules* directory that was created in the folder you mapped.
Next time you run the *node-runner* Container, it will recreate the *node_modules* sub-folder 
and reload into it any modules defined in your
*npm_install.json* file.


# What is the *this* Context within my Script?

The core *node-runner* module sets the *this* context of your script to an object that contains
a number of functions and modules that you may find useful in your script, eg:

- this.fs: provides you with the [*fs-extra*](https://www.npmjs.com/package/fs-extra) module, but also includes several additional functions that you may find useful:
  - this.fs.getDirectories(path): returns an array of the sub-directories within the specified path
  - this.fs.createJSONFile(json, path): creates a file containing the specified JSON at the specified path
  - this.fs.createFile(array, path): creates a file at the specified path, with each line of the file represented by each array element

- this.ask: provides access to the [*readline-sync*](https://www.npmjs.com/package/readline-sync) module which allows you to write interactive command-line scripts
- this.transform: provides access to the [*qewd-transform-json*](https://www.npmjs.com/package/qewd-transform-json) module, which allows you to simply transform one JSON structure into another using declarative specification which is, itself, a JSON document.
- this.uuid: provides access to the [*uuid/v4*](https://www.npmjs.com/package/uuid) module which allows you to create unique UUIDs.
- this.isNumeric(value): a simple function that returns true if the value is numeric
- this.installModule(moduleName, path): a function that will install a module from NPM and save it to the specified path
- this.shell(command): execute a bash shell command


# Using *node-runner* for Other Node.js Work

If you modify the *docker run* command as follows:

        docker run -it --name node-runner --rm -v ~/test:/node --entrypoint=/bin/bash rtweed/node-runner

instead of running a script, it will give you shell access to the *node-runner* container, eg:


        root@ba1c65c9bb92:/src#

Within this shell environment, you have access to Node.js, eg:

        root@ba1c65c9bb92:/src# node -v
        v12.13.0
        root@ba1c65c9bb92:/src# node
        Welcome to Node.js v12.13.0.
        Type ".help" for more information.
        >
        (To exit, press ^C again or ^D or type .exit)
        >
        root@ba1c65c9bb92:/src#

The */node* directory is the host volume you've mapped, so if you create any files on the host, eg
in our example, in the host's *~/test* folder, they will appear in the Container's */node* directory and will
be available for you to use.

        root@ba1c65c9bb92:/src# cd /node
        root@ba1c65c9bb92:/node#

In summary, you can use *node-runner* as a Node.js "scratch pad", to create and run Node.js scripts
on your host system, without having to install Node.js itself on the host system.  As soon as you
stop the *node-runner* container, the Node.js environment disappears, but anything in your mapped
volume persists on the host.


# License

```
 Copyright (c) 2019-25 MGateway Ltd,                           
 Redhill, Surrey UK.                                                      
 All rights reserved.                                                     
                                                                           
  http://www.mgateway.com                                                  
  Email: rtweed@mgateway.com                                               
                                                                           
                                                                           
  Licensed under the Apache License, Version 2.0 (the "License");          
  you may not use this file except in compliance with the License.         
  You may obtain a copy of the License at                                  
                                                                           
      http://www.apache.org/licenses/LICENSE-2.0                           
                                                                           
  Unless required by applicable law or agreed to in writing, software      
  distributed under the License is distributed on an "AS IS" BASIS,        
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
  See the License for the specific language governing permissions and      
   limitations under the License.  

