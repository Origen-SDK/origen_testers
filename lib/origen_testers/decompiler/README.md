### lib/origen_testers/decompiler

The decompiler is used to reverse-parse text pattern representations (e.g. .atp for IGXL or .avc for Smartest) and
get an object-oriented representation.

This directory contains:

* base_grammar: the base grammar treetop file and nodes.rb. This includes very basic nodes for newlines. whitespace,
decimal-integers, etc. Most grammars, even if not vector-based, can use these nodes.
* base_parser.rb: This provides a base parser for Treetop objects that can be overridden by the platform to point to
the needed treetop grammars, etc.
* decompiled_pattern.rb: The decompiled pattern base object. This can be grown as needed and to encompass as many features
as possible.
* origen_testers_node.rb: A base node to help with both debugging and error handling. This node will check, symbolize, and
clean upon initialization and provides some methods that can be used if unexpected results occur from parsing. This can
help avoid some dreaded <code>undefined method for NilClass</code> errors and can provide better error reports. This also
include a base node for list rules (e.g. item1,item2,item3,...)
* vector_based_base_grammar: A base grammar for vector-based testers. Both IXGLBased and SmartestBased decompilers use
these nodes. This can help pack an additional platform into a tree structure that resembles other platforms and should
provide a good base case to start. Rules and nodes can be overridden and inherited as needed.

