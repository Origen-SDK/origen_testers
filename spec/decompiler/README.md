# Decompiler Specs

This README covers the specs from a developer's/maintainer's perspective.
This'll include the specs' organization and details on the platform interface.

### Organization

The Decompiler's specs are split into a few different scopes:

* The base class, `OrigenTesters::Decompiler::Pattern`, including:
  * Behavorial specs for `OrigenTesters::Decompiler::Pattern` class
  * Specs for proper class inheritance and child class setup/verification
  * Found in `pattern.rb`
* The 'advertised launch point', `OrigenTesters`, and the top-level methods
  * (`OrigenTester.add_pins`, `OrigenTesters.execute`, etc.)
  * Found in `topmost_methods.rb`
* The Decompiler module-level API, extendable by other modules
  * Found in `decompiler_api.rb`
* A spec driver for any tester platform which implements the decompiler's spec
  * Driver is found in `platform_interface/platform_interface.rb`
  * Platform specific setups and parameters are found in `platforms/<platform>`

#### Spec Driver

The main spec driver is located one level up at `../decompiler_spec.rb`. This
is the launching point for the decompiler's specification and contains the
common setup that is used across the various test scopes.

The driver will load up the `OrigenTesters::Decompiler::RSpec` namespace with
the common API and definitions. Any static stuff that is reused should
be placed in the `@defs` hash to make it easily available and maintainable across the scopes.

_Aside_: the reason for the additional namespace is the limitation of `RSpec`.
The decompiler's driver and platform interface together act as a specification factory
for various platforms. However, RSpec requires that all of the test be 'unrolled'
or 'loaded' before anything executes, which means that dynamic definitions
are lost during the course of the examples (like the current platform).
Additionally, much of the `#let`, or `context`  blocks don't allow
static helper methods within their scope.

To counter this, a `OrigenTesters::Decompiler::RSpec` namespace is defined
upfront to be an available locker for all shared methods and common definitions.
This is the cleanest way of handling the volume of common defines and methods
while still keeping within RSpec's comfort zone.

#### Matchers

A few custom matchers provide more detailed feedback without
blowing up the test count or having lots of long-winded, copy-and-pasted test
cases.

Two of these are `match_pins` and `match_pin_names`, which will verify the
DUT pins against expected values. `match_pins` will check both the names and sizes
of the pins whereas `match_pin_names` checks only that the names match. Pin ordering
and pin name cases are __NOT__ checked.

The third matcher is a simple driver to wrap the `changed_patterns` that `examples`
uses, allowing for behavioral tests for `execute`.

### Non-Platform Philosophy

The brunt of the specification is to verify that various platforms either conform
to the existing spec, or prove that the spec is, in fact, flexible enough to support any
arbitrary test platform that may come along.

However, many non-platform dependent/platform-specific specs are added to make
sure the decompiler maintains the same behavior and flags any changes that occur during development.

In this context, non-platform means _'assuming the platform interface has already passed'_.
The non-platform specs use both the `J750` and `V93K` platforms as some sample platforms to
verify real cases and get actual results. Obviously, changes to either of these
which causes the platform interface to fail invalidates the non-platform specs.

#### Overview of Non-Platform Specs

##### OrigenTesters::Decompiler::Pattern

Located in `pattern.rb`, these specs serve two purposes:

1. Make sure the child-class interface is consistent.
2. Tests the general behavior of non-platform dependent methods.

For `1.`, the goal of these are to make sure the abstract interface inherited
when `Pattern` is sub-classed remains stable and does what it's supposed to.

For `2.`, we're testing methods that, assuming the child class implements a valid
decompiler, should work regardless of what platform is selected. This includes
simple behaviors, like `#decompile` with various input types and the
`VectorBodyElement`'s API, but also includes the entire enumerable extension
methods. Other generic behaviors that should apply across platforms can be added here.

##### Decompiler API

The specs in `decompiler_api.rb` covers the module extensions, allowing any
`module` to become either a registered or unregistered decompiler (recall,
register modules will limit the decompiler method calls to only decompilers
that _that_ module supports).

##### Top-Most Methods

The top-most methods, found in `topmost_methods.rb`, are specs for the general
decompiler use cases; that is, the topmost API that is assumed to cover almost
all use cases. This includes behavioral specs for `#add_pins` and `#execute`, both
being called on the `OrigenTesters` namespace (the advertised methodology present
in the guides).

Additional top-most methods can go there. This is, to some extent, redundant with
the `decompiler_api` specs, but explicitly covers what is present in the guides.

### Platform Interface

The platform interface provides a suite of common, generic tests to ensure that:

1. the platform supports the common API
2. the decompiler successfully decompiles some standard patterns
3. the decompiler can uniformly handle error or corner cases, such as parsing failures or formatting errors.

#### Platform Setup

The platform setup is defined in the `./platforms` directory. These will be automatically
loaded by the spec driver at boot time. The platform setup is defined on the
namespace `OrigenTester::Decompiler::RSpec::<platform>`,
for example, `OrigenTester::Decompiler::RSpec::J750` for the J750.

The platform's namespace should initialize a `@defs` Hash, containing setup parameters specific to this platform.
The keys that are currently used are below:

~~~
@defs = {
  # The expected decompiler class.
  #   E.g.:
  decompiler: OrigenTesters::SmartestBasedTester::Pattern,

  # The environment file corresponding to this platform.
  #   E.g.:
  env: 'v93k.rb',

  # Location of the approved pattern directory.
  #   E.g.:
  approved_dir: Pathname("#{Origen.app!.root}/approved/v93k"),

  # Hash of non-standard patterns/pattern names. A :workout key is required here.
  #   E.g.:
  patterns: {
    workout: 'v93k_workout',
  },

  # The pattern extension used to auto-build filenames.
  #   E.g.:
  ext: '.avc',
}
~~~

See the full [J750](https://github.com/Origen-SDK/origen_testers/tree/master/spec/decompiler/platforms/j750.rb)
or [V93K](https://github.com/Origen-SDK/origen_testers/tree/master/spec/decompiler/platforms/v93k.rb)
setup for example setups.

#### Patterns

The platform interface requires several patterns, for three different cases:

1. Working (Expected) Patterns - These patterns should decompile correctly and will be compared against an approved _Pattern Model_.
    * `sanity`: Bare minimum pattern that can be generated from Origen. Literally, just an empty `Pattern.create` block. Generate with the `empty.rb` target to get the absolute minimum source (that is, no initial pin states, no startup).
    [See the pattern source](https://github.com/Origen-SDK/origen_testers/blob/master/pattern/sanity.rb)
    * `delay`: A bit more involved than `sanity`, but not by much. Just generates some delays.
    [See the pattern source](https://github.com/Origen-SDK/origen_testers/blob/master/pattern/delay.rb)
    * `<platform>_workout`: A platform-specific workout pattern. This should contain an example of everything the platform supports and that the decompile may encounter.
    Note that it may not be necessary for the decompiler to know how to _execute_ everything in this pattern, but it __must__ decompile and yield a valid decompiled pattern object to compare against the pattern model.
2. Corner Cases - These patterns should decompile correctly, but may have missing information (e.g., no pattern header, no frontmatter)
    * `no_pattern_header`: No pattern header, but may contain other frontmatter stuff, depending what the platform supports. This may just be whitespace or even the same as the `no_frontmatter` source.
    * `no_frontmatter`: Pattern containing no frontmatter at all, just straight into the `pinlist`. `Pattern.frontmatter` will be empty, but the source should still decompile and attempts to use `Pattern.frontmatter` should, correctly, return empty structures (no stack trace dumps, that is).
3. Error Conditions - These patterns should not decompile, but should throw a meaningful error
(none of the `unknown method for NilClass` stack trace dumps, for example)
    * `empty_file`: Literally just an empty file. This should return a useful error message though rather than hitting some sort of `IOError` or yielding the unhelpful `NilClass` stack trace dumps, or just doing nothing.
    * `empty_pinlist`: Pattern containing no pins in the pinlist. This will yield some `first_vector` problems later down the road, so its flagged as an error case for now. This can be revisited if support for empty-pinlist patterns are needed.
    * `no_first_vector`: Pattern containing no first vector. Like `empty_pinlist`, this will cause some problems later on, so its currently in the `error_conditions`. This pattern should decompile initially, but throw an error complaining about no first vector if pretty much anything else is done with the model (e.g., `#execute`, or `#add_pins`).
    * `no_pinlist`: Pattern containing no pinlist start or stop symbols. Tests that the `splitter` can handle an ill-formatted or unexpected pattern source.
    * `no_vector_body`: Pattern containing no vector body. Like `no_pinlist`, Tests the `splitter` can handle an ill-formatted or unexpected pattern source.
    * `parse_failure_frontmatter`: Pattern that has injected a syntax error in the `frontmatter`. Tests that the grammar and parser and able to catch and return syntax errors.
    * `parse_failure_pinlist`: Same as `parse_failure_frontmatter`, except for the injected syntax error is in the pinlist. Tests that the grammar and parser and able to catch and return syntax errors.
    * `parse_failure_vector`: Same as the above two patterns, but for a vector. Tests that the grammar and parser and able to catch and return syntax errors.

For the patterns in `1.`, the minimum that needs to be supported is just toggling some pins and dealing with repeats. Everything else is a bonus as far as the generic API is concerned. So, if it appears that the patterns kind of go from 0-to-100 (a couple of delays to a full platform workout), that's because they do!

The `Working/Expected Patterns` requires `Pattern Models` to verify that the decompilation was a success. `Pattern models` are covered a bit further down.

The pattern source for each should be in the `approved/` directory, behind the platform name given in the setup, `decompiler`, and the use case. For example, this is `approved/j750/decompiler/error_conditions` for the J750's error pattern sources. The common API will expect this location.

For some examples, see [the J750 patterns](https://github.com/Origen-SDK/origen_testers/tree/master/approved/j750)
or [the V93K patterns](https://github.com/Origen-SDK/origen_testers/tree/master/approved/v93k).

#### Matchers & Validators

The platform interface relies on some custom validators and matchers. Each
pattern in `1.` is run against the `pattern_validator` example group, located in
`./platform_interface/validators`. This validator will decompile the given pattern
source and compare it section-by-section and vector-by-vector against a previously
approved model.

A few helper validators are present as well.

A custom matcher for a vector is provided in `./platform_interface/matchers`.
This matcher checks various aspects of the vector, using the vector from the
pattern model as the comparison point.

The validator compares the vectors at equivalent indices, so any issues that arise
that either adds or removes vectors will see a significant error rate increase with
possibly every aspect of the matcher failing.

The validator defers to the platform setup whenever a platform-specific `vector body element`
is encountered. The platform setup should provide a `handle_platform_specific_vector_body_element`
method which will be given the `RSpec` `context` and the vector type, and should
implement some matcher/validator to verify that element. See either the
[J750 setup](https://github.com/Origen-SDK/origen_testers/tree/master/spec/decompiler/platforms/j750.rb)
or the [V93K setup](https://github.com/Origen-SDK/origen_testers/tree/master/spec/decompiler/platforms/v93k.rb)
for examples on providing these.

Additional `vector body elements` can also be added there.

#### Pattern Models

The patterns listed in `1.` need some kind of reference point to compare against.

The `OrigenTesters::Decompiler::Pattern` object has a `SpecHelper` module,
containing a `write_spec_yaml` method. Given a decompiled pattern, this method
will spit out a [YAML](https://yaml.org/)
representation of the pattern: the `pattern model`. This is a very generic
representation of the pattern, but provides enough to validate the decompilation process.

This can be generated either from an interactive session, or a Ruby script:

~~~
OrigenTesters::Decompiler.decompile('path/to/pattern').write_spec_yaml(approved: false)
  #=> Generates the pattern models in output/<platform_name>/decompiler/models

OrigenTesters::Decompiler.decompile('path/to/pattern').write_spec_yaml(approved: false)
  #=> Generates the pattern models in approved/<platform_name>/decompiler/models
~~~

Or, by using the development command built into `OrigenTesters`:

~~~
origen generate_pattern_model path/to/pattern1 path/to/pattern2
  #=> Generates the pattern models in output/<platform_name>/decompiler/models

origen generate_pattern_model path/to/pattern1 path/to/pattern2 --approve
  #=> Generates the pattern models in approved/<platform_name>/decompiler/models
~~~

The `approved` option will automatically move the output into the appropriate
`approved` directory so it can be found by the decompiler's specs.

Some existing pattern models are already present for the `J750` and `V93K` platforms.
See [those approved directories](https://github.com/Origen-SDK/origen_testers/tree/master/approved)
for the pattern models:

* [J750](https://github.com/Origen-SDK/origen_testers/tree/master/approved/j750/decompiler/models)
* [V93K](https://github.com/Origen-SDK/origen_testers/tree/master/approved/v93k/decompiler/models)

#### Additional Patterns

##### New Standard Patterns

Adding new standard patterns, that is patterns that should be run for all supported platforms,
can be directly added to the `platform interface`.

##### Non-Standard Patterns

Additional patterns can be added specifically for a given platform, allowing a condition
or feature only applicable to that platform to become part of the its standard regression.

In the platform's setup (`./platforms`), additional patterns can be added to the
`@defs[:patterns]` Hash. Patterns listed here are assumed to pass and will assume
that a `pattern model` is available to compare against.
The pattern model for any new cases added are assumed to be in the
`approved` directory, along with the other pattern models for `sanity`, `delay`, and the workout pattern.

`error conditions` and `corner cases` are a bit more involved. Since there's no
standard driver for these, the tests need to be implemented to check for whatever
the expected behavior is.

Both of these are just methods that will be called if the platform provides them.
When the method is called, it will be given the `RSpec` `context` which can be
used to provide the test cases. This is the `RSpec` object itself, so adding a new test would be:

~~~
context.it 'new test' do
  expect('this').to pass
end
~~~

Although there's no additional patterns, [the J750 setup](https://github.com/Origen-SDK/origen_testers/tree/master/spec/decompiler/platforms/j750.rb)
contains some example cases to ensure that this is working. See the
`error_conditions` and `corner_cases` methods.

#### Adding New Platforms

Assuming you already have a new platform added and registered, this will
detail how to ensure that it conforms to the general API and ensure that it is
regression tested along with the other supported platforms.

##### Platform Setup

Begin by creating a new platform file in `./platforms/` and creating a new
module in the `OrigenTesters::Decompiler::RSpec` namespace, e.g. `OrigenTesters::Decompiler::RSpec::J750`.
This module should include the `OrigenTesters::Decompiler::RSpec::Common` API, giving
it the behavior expected by the platform interface.

Next, add a method `handle_platform_specific_vector_body_element`. The
implementation of this method can be as broad or granular as needed, but
this will be called anytime a non-standard (platform-specific) `vector body element` is encountered.

See `./platforms/j750.rb` and `./platforms/v9k3.rb` for examples.

##### Required Patterns

As detailed in the above sections, the platform interface expects three
patterns and corresponding models for `sanity`, `delay`, and a `workout`. The
`sanity` and `delay` patterns can be generated with `origen g sanity delay`
then moved into the `approved` directory,
but the workout pattern is up to the platform implementer. This can be
as in-depth as needed to verify any expected `vector body elements` that
may be encountered. The more extensive this pattern is, the more robust
the decompiler, and its interface, will be. But, again, the exact scope is left up
to the implementer.

The pattern models can be generated in the same way as with the already-supported
platforms. See the _Pattern Models_ section
for the a description of the pattern models and how to generate them. The interface
is the same, even if this may be a first-time generation.

The error condition and corner case patterns are hand-modified to trigger the
desired case. The J750 and V93K patterns use hand-modified `delay` patterns, though
any source that triggers the case is sufficient.

Non-standard patterns can be added to this platform in the same way as the
existing platforms.

