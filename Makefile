NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

test: deps
	@mocha --compilers coffee:coffee-script  

test-watch: deps
	@mocha --compilers coffee:coffee-script -w -R min 

test-pretty: deps
	@mocha --compilers coffee:coffee-script -R spec

test-pretty-watch: deps
	@mocha --compilers coffee:coffee-script -w -R spec

lint: deps
	@coffeelint -r src test

#atest-coverage: deps
#	@mocha

run: test

deps:

.PHONY: all
