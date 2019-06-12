### OrigenTesters::Decompiler

The `decompiler` is responsible for taking a pattern's text source, such as
`.atp` or `.avc` and constructing an object Origen can work with.

For the user guides,
[see the docs on the website.](https://origen-sdk.org/origen/guides/decompilation/overview)

### Adding New Decompilers

Adding new decompilers was purposely left out of the user guides. If you're wanting
to add support for a new decompiler, the notes here should help kickstart the
process.

When going through the setup, See the 
[IGXLBasedTester::Decompiler](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/igxl_based_tester/decompiler.rb)
or the [SmartestBasedTester::Decompiler](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/smartest_based_tester/decompiler.rb)
decompiler implementations for examples.

The goal of the decompiler's structure is to provide a 'static' view of the
platform. Adding a new platform, or updating an existing one, is closer to providing
a 'setup', or 'rules and actions' and re-using the existing flow than it is
writing an entire source-to-object flow from the ground up. This also helps
maintain some consistency between the platform decompilers.

#### Directory & File Structure

Current decompiler implementations have followed a _decompiler module_ and
_pattern class_ structure. For example, the top setup resembles:

~~~ruby
module OrigenTesters
  module MyPlatform
    class Pattern < OrigenTesters::Decompiler::Pattern
    end
  end
end
~~~

__Notice the `Pattern` class inheriting from `OrigenTesters::Decompiler::Pattern`.__

This puts the pattern decompiler at the same level as the rest of the platform setup.
This structure is placed in `decompiler.rb` in the platform's directory:

~~~
origen_testers
  |
   -> igxl_based_tester
  |
   -> smartest_based_tester
  |
   -> < my_platform >
      |
       -> base.rb
      |
       -> < platform.rb >
      |
       -> decompiler.rb
~~~

Underneath the platform directory is a `decompiler` directory containing the
decompiler collateral:

~~~
origen_testers
  |
   -> igxl_based_tester
  |
   -> smartest_based_tester
  |
   -> < my_platform >
      |
       -> base.rb
      |
       -> < platform.rb >
      |
       -> decompiler.rb
      |
       -> decompiler
          |
           -> nodes.rb
          |
           -> processors.rb
          |
           -> < ext name >.treetop
~~~

Nothing will stop you from implementing the decompiler directory structure in
other ways, but this is the structure for existing decompilers.

#### Extending the Base

Extending `OrigenTesters::Decompiler::Pattern` provides the entire `universal API`,
but it also provides the shell to run the _grammars_, match them to _nodes_, 
_process_ the elements, then finally return a `decompiled pattern` object.

`Decompilation` is split into a few parts:

1. Split the pattern source into `sections`, returning the start and stop lines for the
`frontmatter`, `pinlist`, and the `vector body`.
2. Parse the `frontmatter`, storing the `AST` in memory.
3. Parse the `pinlist`, storing the `AST` in memory.

The `vector body` itself it not actually parsed until required, and then its
parsed and run line-by-line, only storing a single vector in memory at a time
(unless the given `block` by the user saves them off manually...).

For `1.`, the `Pattern` class must provide a singleton-class instance variable `splitter_config`.
The sections are assumed to be sequential, where the end of one section denotes
the start of the next. The `splitter_config` is a Hash with the following
required keys:

* `:pinlist_start`
* `:vectors_start`
* `:vectors_end`

Each key can be either a `String` or a `Regex` which will be searched for in the
lines of the pattern, starting from the top and continuing until either `EoF` (error case)
or until the `String` or `Regex` is matched. That index becomes the start/stop index
for that section.

* This is assuming the `frontmatter` starts at line 0.
* The `vector_end` is used to end the `vector body` in the event that there's extra stuff at the bottom.
If there never will be, `-1` will indicate that the `vector body end` is at `EoF`.

Two other optional keys are available:

* `:vectors_include_start_line` A boolean that indicates if the `first vector` starts __on__ the
same line as the start token (`true`) or if the `first vector` is actually __on the next__ line
after the start token is encountered (`false`).
* `:vectors_include_end_line` Boolean similar to the above, but reversed. If `true`,
whatever token denotes the end of the vector appears __on the same line__ as the last vector.
If `false`, the token that denotes the end of the `vector body` does __not__ also contain a vector.

After splitting, the `frontmatter` and `pinlist` are parsed. Another singleton-class instance variable,
`parser_config` is defined to provide the grammar setup. Within this Hash are
various keys, but the only one that's required is:

* `:grammar` An `Array` of grammar files. These will be included by the parser.

The others are all related to the `base grammars`, which are covered in the next section.

So far, grammars have only been implemented using [Treetop](https://github.com/cjheath/treetop),
and that's what the current parsers will be expecting. The decompiler
can provide its own `nodes` for integration with `treetop`, though that's
not required.

When a node is parsed, it will be converted to an [AST](http://whitequark.github.io/ast/index.html).
Origen extends the `AST` a bit to provide the `platform nodes` and some
other boiler-plate setup. `AST` will be expecting various `processors` for
each `node` that may be encountered. These can either by implemented by the
decompiler, or borrowed from the base.

In summary, the decompilation goes:

~~~
pattern source (singleton) -> splitter (singleton) -> section parsers (per section) -> Treetop nodes (per node/token) -> AST nodes (per node/token)
~~~

The AST nodes are what is finally provided to the decompiled pattern and what the
`universal API` expects and operates on.

#### Vector Delimiter

Individual `vector body elements` may span more than one line, the prime example
begin `comment blocks`, since sequential blocks are combined into a single element.
The `vector delimiter` is what _actually_ chops up lines of the `vector body` into
a single element.

So far, this has really only been used for comments, but could be expanded further.
To handle comments though, the `vector delimiter` requires knowledge of the
platform's `comment character`. This is set using the `platform_tokens` hash,
containing a key `comment_start`.

The `platform_tokens` has some other uses as well, covered in the _platform tokens_
section further below. An example of setting this:

~~~ruby
module OrigenTesters
  module MyPlatform
    class Pattern < OrigenTesters::Decompiler::Pattern
      @platform_tokens = {
        comment_start: '#'
      }
    end
  end
end
~~~

#### Base Grammars, Nodes, & Processors

It turns out that platforms aren't actually that different from each other.
Most follow a similar structure and provide comparable functionality; its really
just different formating of the same thing. 
This opens the door from some `shared`, or `base` setups which can be applied
as the platform allows.

The generic decompiler provides base `grammars`, `nodes`, and `processors`. Some
setup in the `parser_config` indicates which aspects, if any, you'll want to use.

* `:include_base_tokens_grammar` Boolean indicating whether the _base tokens_ grammar should be included.
* `:include_vector_based_grammar` Boolean indicating wither the _base vector-based_ grammar should be included.

These still need to be included in your grammars, but the settings here indicate
that the parsers should include them as well.

Note that the `base nodes` and `base processsors` are always available, but
won't actually do anything if not used. If the `base grammars` are not included,
the `base nodes` will never be instantiated unless explicitly used elsewhere, and if the platform overrides
all of the base processors, or never returns expected `types`, then the base
processors will never be used. They are always available if needed though.

Note too that not returning the common `types` (especially `:vector`) will break
aspects of the `universal API`. Sub-classing the `base processors` is the
route that should be taken. For example, both the `IGXLBasedTester::Pattern` and
`SmartestBasedTester::Pattern` classes return a sub-classed base `vector processor`
(`OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Vector`).
`IGXLBasedTester::Pattern` actually returns a sub-classed `frontmatter` processor as well.

#### Platform Tokens

Using the `vector based grammar` requires that `comment_start` token. But,
there's a bit of the circular dependency, as the `comment_start` is platform-specific,
but the platform-specific grammar requires the `vector based` grammar. To
overcome this, the decompiler can build a dynamic grammar from the `platform_tokens`
Hash. This is the same Hash required by the
`vector delimiter`, but can be expanded here to cover anything else needed.
Any pairs defined will be built into treetop rules,
where the `key` is the `rule name` and the `value` is the `rule value`. Indicate
that this grammar should be built and included by setting `include_platform_generated_grammar: true`
in the `parser_config`. 
[See the `IGXLBasedTester::Pattern` for an example.](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/igxl_based_tester/decompiler.rb)

#### Selecting Processors

When a `vector body element` is encountered, it'll first try to call
`select_processor` on the decompiler, allowing the decompiler to have the
first say in what processor is used. Define a method `#select_processor`
on the `decompiler class`:

~~~ruby
def select_processor(node:, source:, **options)
  case node.type
    when :type1
      OrigenTesters::MyPlatform::Decompiler::Processors::Type1
    when :type2
      OrigenTesters::MyPlatform::Decompiler::Processors::Type2
    when :vector
      # Use this vector class instead of the base vector.
      OrigenTesters::MyPlatform::Decompiler::Processors::Vector
  end
end
~~~

This returns either the class of the processor to use, or `nil`. If `nil` is
returned, the [default selector](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/decompiler/base_grammar/vector_based/processors.rb)
will be called. If the type still hasn't returned a `class`, then an exception
is raised, implying that any platform that provides custom `vector body elements`
__must__ implement this method and match the custom types.

#### Registering The Decompiler

Compared to the base and grammar setups, this part is easy, and is much more
'boiler-plate'.

Extending the `OrigenTesters::Decompiler::API` module allows the extending module
to register itself as a decompiler.

When the `#select_decompiler` method is called on the `Decompiler API`, it'll iterate through any registered
decompilers and ask whether or not the decompiler in question can handle either
the file type, or the current environment. Add a `::suitable_decompiler_for`
class method onto your `decompiler` module to provide this `yes/no` response.
This method uses the _keyword-argument_ syntax,
and supports either the pattern extension OR the tester name, it should
return the `class` of the decompiled pattern, which the `decompiler API` will
create an instance of and call `#decompile`.

For example:

~~~ruby
module OrigenTesters
  module MyPlatform
    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && Pathname(pattern).extname == "<support extension>")
        OrigenTesters::MyDecompiler::Pattern
      elsif tester && tester == '<supported tester name>'
        OrigenTesters::MyDecompiler::Pattern
      end
    end
    
    class Pattern < OrigenTesters::Decompiler::Pattern
      # ...
    end
  end
end
~~~

This method can be as complex or as simple as needed. After this is defined,
extend the `API module` and call `register_decompiler` with the module as
the argument:

~~~ruby
module OrigenTesters
  module MyPlatform
    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && Pathname(pattern).extname == "<support extension>")
        OrigenTesters::MyDecompiler::Pattern
      elsif tester && tester == '<supported tester name>'
        OrigenTesters::MyDecompiler::Pattern
      end
    end

    # Extend the Decompiler API and register MyPlatform as an available decompiler
    extend OrigenTesters::Decompiler::API
    register_decompiler(self)
 
    class Pattern < OrigenTesters::Decompiler::Pattern
      # ...
    end
  end
end
~~~

#### Setting Up The Specs

The decompiler's specs are handfull on their own.
[See the Decompiler's specs README](https://github.com/Origen-SDK/origen_testers/blob/master/spec/decompiler/README.md)
for more.

