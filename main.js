'use strict';

var fs = require('fs');
var ohm = require('ohm-js');

//Read in the grammar & create the parser etc.

var flGrammar = ohm.grammar(fs.readFileSync('flujo.ohm'));

//Read in the source file and attempt to parse
//The first two args are node itself and the js script being run - 
//so should be ignored
var args = process.argv.slice(2)
var src  = args[0];
console.log("\nParsing", src);
console.log("\n");
var userInput = fs.readFileSync('examples/helloworld.flujo'); //'Hello';
var m = flGrammar.match(userInput);
if (m.succeeded()) {
  console.log('Parsed successfully');
  process.exit(0);
} else {
  console.log("*** Parse failed ***");
  process.exit(-1);
}

