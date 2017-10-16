# This file should be used to extend the origen command line tool with tasks 
# specific to your application.
# The comments below should help to get started and you can also refer to
# lib/origen/commands.rb in your Origen core workspace for more examples and 
# inspiration.
#
# Also see the official docs on adding commands:
#   http://origen.freescale.net/origen/latest/guides/custom/commands/

# Map any command aliases here, for example to allow origen -x to refer to a 
# command called execute you would add a reference as shown below: 
aliases ={
  "g"  => "generate"
}

# The requested command is passed in here as @command, this checks it against
# the above alias table and should not be removed.
@command = aliases[@command] || @command

case @command

  #when "latpc"
  #  require "#{Origen.root(:testers)}/lib/commands/latpc"
  # Need to see if --compile is included and setup compiler
  when "generate"
    @application_options << ['--compile', 'Compile the current pattern or the list', ->(options) { options[:testers_compile_pat] = true }]
    @application_options << ['--compiler NAME', String, 'Override the default application pattern compiler', ->(options, compiler) { options[:testers_compiler_instance_name] = compiler.to_sym }]
    @application_options << ['--no_inline_comments', 'Disable the duplication of comments inline (V93k patterns)', ->(options) { options[:testers_no_inline_comments] = true }]
    @application_options << ['-v', '--vector_comments', 'Add the vector and cycle number to the vector comments', lambda { |options| options[:testers_enable_vector_comments] = true }]

    $_testers_enable_vector_comments = ARGV.delete("-v") || ARGV.delete("--vector_comments")
    $_testers_no_inline_comments = ARGV.delete("--no_inline_comments")

  when "testers:build"
    require "#{Origen.root!}/lib/commands/build"
    exit 0

  when "testers:run"
    require "#{Origen.root!}/lib/commands/run"
    exit 0

  else
    @plugin_commands << " testers:build   Build a test program from a collection of sub-programs"
    @plugin_commands << " testers:run     Run the last test program generated for the current target"

end 
