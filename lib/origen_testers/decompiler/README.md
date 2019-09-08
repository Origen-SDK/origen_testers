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
           -> < ext name >.rb
~~~

Nothing will stop you from implementing the decompiler directory structure in
other ways, but this is the structure for existing decompilers.

#### Extending the Base

Extending `OrigenTesters::Decompiler::Pattern` provides the entire `universal API`,
but also provides the shell for going from pattern _pattern source_ to _decompiled pattern_
object.

`Decompilation` entails:

1. Splitting the pattern source into `sections`, returning the start and stop lines for the
`frontmatter`, `pinlist`, and the `vector body`.
2. Parsing the `frontmatter`, storing the parsed contents in memory.
3. Parsing the `pinlist`, storing the parsed contents in memory.

The `vector body` itself it not actually parsed until required, and even then its
parsed and run line-by-line, only storing a single vector in memory at a time
(unless the given `block` by the user stores them manually).

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

* This assumes the `frontmatter` starts at line 0.
* The `vector_end` is used to end the `vector body` in the event that there's extra stuff at the bottom.
If the platform's syntax does not allow this, `-1` will indicate that the `vector body end` is at `EoF`.

Two other optional keys are available:

* `:vectors_include_start_line` A boolean that indicates if the `first vector` starts __on__ the
same line as the start token (`true`) or if the `first vector` is actually __on the next__ line
after the start token is encountered (`false`).
* `:vectors_include_end_line` Boolean similar to the above, but reversed. If `true`,
whatever token denotes the end of the vector appears __on the same line__ as the last vector.
If `false`, the token that denotes the end of the `vector body` does __not__ also contain a vector.

After splitting, the `frontmatter` and `pinlist` are parsed. The platform
should provide methods `parse_frontmatter` and `parse_pinlist` and return
`nodes` containing the parsed contents. `Nodes` will be covered in a later section.

The vector body will be parsed one vector at a time. The method `parse_vector` should
also be provided by the platform and should also return a `node` containing the
parsed contents.

In summary, the decompilation process goes:

~~~
pattern source (singleton) -> splitter (singleton) -> section parsers (per section) -> platform parsers (per section) -> node (per section/per vector)
~~~

The nodes are what is finally provided to the decompiled pattern and what the
`universal API` expects and operates on. Nodes will be covered more a few sections down.

#### Vector Delimiter

Individual `vector body elements` may span more than one line, the prime example
begin `comment blocks`, since sequential blocks are combined into a single element.
The `vector delimiter` is what _actually_ chops up lines of the `vector body` into
a _raw vectors_ to then be parsed.

So far, this has really only been used for comments, but could be expanded further.
To handle comments though, the `vector delimiter` requires knowledge of the
platform's `comment character`. This is set using the `platform_tokens` hash,
containing a key `comment_start`.

An example of setting this:

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

#### Parsing And Nodes

After the pattern is split into sections, its passed to the parsers. The parsers are
provided by the individual platforms, which must provide three class methods to
parse the sections:

~~~ruby
# Parse the frontmatter section
parse_frontmatter(raw_frontmatter:, context:)

# Parse the pinlist section
parse_pinlist(raw_pinlist:, context:)

# Parse each individual vector
parse_vector(raw_vector:, context:, meta:)
~~~

The `context` is the decompiled pattern itself. Any information contained
or anything parsed-and-stored is available for subsequent parsers to use. For example,
this allows the `V93K` decompiler to use knowledge of the `pinlist` as it
parses `vectors`.

Since vectors are parsed independently, but serially, the Hash, `meta` is passed
to each vector in turn for platforms whose decompilation of the current vector
depends on some information from a previous vector. This Hash can be loaded with
whatever is needed but its usage and maintainence is ultimately the platform's responsibility.

Each method above should return a `node` which will hold the parsed values. The nodes should
have the following fields:

~~~
Frontmatter:
  context: the current decompiled pattern object.
  pattern_header: any top-most comments, usually containing information such
    as the pattern name, dependencies, requirements, etc.
  comments: any other comments.
  
  What constitutes the pattern header as opposed just comments is up to the platform.

Pinlist:
  context: the current decompiled pattern object.
  pins: Array of pin names appearing in the pattern.

The vector body is a bit different, and can return either a genuine vector,
or another node, depending on what that particular vector body element is.

Is general, all that needed is:
  context: the current decompiled pattern object.

But for a Vector:
  context: the current decompiled pattern object.
  repeat
  timeset
  pin_states
  comment
~~~

The decompiler provides some [starter nodes](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/decompiler/nodes),
which can either be used directly
for simpler platforms, or inherited as a building block to enable more complex decompilation.

For examples, see: [the J750 nodes](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/igxl_based_tester/decompiler/atp.rb)
or the [the V93K nodes](https://github.com/Origen-SDK/origen_testers/blob/master/lib/origen_testers/smartest_based_tester/decompiler/avc.rb).

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

