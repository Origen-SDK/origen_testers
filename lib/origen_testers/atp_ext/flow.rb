require 'atp/flow'
module ATP
  class Flow
    # The idiomatic way of creating a group in SMT8 is a sub-flow, this overrides the flow.group method
    # inherited from ATP to convert any groups into sub-flows
    alias_method :orig_group, :group
    def group(name, options = {}, &block)
      if tester.try(:smt8?)
        extract_meta!(options) do
          apply_conditions(options) do
            parent, sub_flow = *::Flow._sub_flow(name, options, &block)
            path = sub_flow.output_file.relative_path_from(Origen.file_handler.output_directory)
            ast = sub_flow.atp.raw
            name, *children = *ast
            nodes = [name]
            nodes << id(options[:id]) if options[:id]
            nodes << n1(:path, path.to_s)
            nodes += children
            ast = ast.updated :sub_flow, nodes,
                              file:        options.delete(:source_file) || source_file,
                              line_number: options.delete(:source_line_number) || source_line_number,
                              description: options.delete(:description) || description
            ast
          end
        end
      else
        orig_group(name, options, &block)
      end
    end
  end
end
