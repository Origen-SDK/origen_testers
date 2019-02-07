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
            @top_level_flow ||= Origen.interface.flow
            parent = Origen.interface.flow
            # If the parent flow already has a child flow of this name then we need to generate a
            # new unique name/id
            # Also generate a new name when the child flow name matches the parent flow name, SMT8.2
            # onwards does not allow this
            if parent.children[name] || parent.name.to_s == name.to_s
              i = 0
              tempname = name
              while parent.children[tempname] || parent.name.to_s == tempname.to_s
                i += 1
                tempname = "#{name}_#{i}"
              end
              name = tempname
            end
            if parent
              id = parent.path + ".#{name}"
            else
              id = name
            end
            sub_flow = Origen.interface.with_flow(id) do
              Origen.interface.flow.instance_variable_set(:@top_level, @top_level_flow)
              Origen.interface.flow.instance_variable_set(:@parent, parent)
              ::Flow._create(options, &block)
            end
            parent.children[name] = sub_flow
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
