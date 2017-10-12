/******************************************************************** 
 * Graamar testing - literals
 * This file only tests for failures.  Successes are tested for
 * using the "example" files, which provide a much better - and
 * more readable - set of examples.
 * 
 * As a consequence, the logic below is reversed: the test passes
 * if none of the example literals are deemed valid on parsing
*/

'use strict';

var fs = require('fs');
var ohm = require('ohm-js');

console.log("***************************************************")
console.log("Testing Literals")
console.log("***************************************************")

//Read in the grammar & create the parser etc.
var flGrammar = ohm.grammar(fs.readFileSync('../../flujo.ohm'));

//The test cases: all invalid as literals
var expectedInvalidLiterals = [".12e12G", "0xZFG", ".12e12G", "Q1w"]

//arrays to hold the results of testing
var actualInvalidLiterals = []
var actualValidLiterals = []

//run the tests
expectedInvalidLiterals.map(function(testCase){
    var m = flGrammar.match(testCase, "literal")
    if(m.succeeded()) {
       actualValidLiterals.push(testCase)
       //console.log(flGrammar.trace(test, "literal").toString())
    }
    else {
        actualInvalidLiterals.push(testCase)
    }    
})

var totalTestsRun = actualValidLiterals.length + actualInvalidLiterals.length
if(totalTestsRun != expectedInvalidLiterals.length) {
    console.log("\n")
    console.log("*** ERROR: not all cases accounted for")
    console.log("*** Test run aborted")
    return(-1)
}
if(actualValidLiterals.length != 0) {
    console.log("***", actualPasses.length, "test cases passed unexpectedly")
    return(-1)
} else {
    console.log("All", actualInvalidLiterals.length, "tests passed")
    return(0)
}

