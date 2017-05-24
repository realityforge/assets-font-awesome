#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Noft
  module Base
    # Base class for templates that generate a single directory
    class SingleDirectoryOutputTemplate < Reality::Generators::Template
      attr_reader :output_directory_pattern

      def initialize(template_set, facets, target, template_key, output_directory_pattern, helpers = [], options = {})
        super(template_set, facets, target, template_key, helpers, options)
        @output_directory_pattern = output_directory_pattern
      end

      def output_path
        output_directory_pattern
      end

      protected

      def generate!(target_basedir, element, unprocessed_files)
        object_name = name_for_element(element)
        render_context = create_context(element)
        context_binding = render_context.context_binding
        begin
          output_directory = eval("\"#{self.output_directory_pattern}\"", context_binding, "#{self.template_key}#Filename")
          output_directory = File.join(target_basedir, output_directory)
          unprocessed_files.delete_if { |f| f =~ /^#{output_directory}\/.*/ }

          FileUtils.mkdir_p File.dirname(output_directory) unless File.directory?(File.dirname(output_directory))
          generated = generate_to_directory!(output_directory, element)

          if generated
            Reality::Generators.debug "Generated #{self.name} for #{self.target} #{object_name} to #{output_directory}"
          else
            Reality::Generators.debug "Skipped generation of #{self.name} for #{self.target} #{object_name} to #{output_filename} due to no changes"
          end
        rescue => e
          raise Reality::Generators::GeneratorError.new("Error generating #{self.name} for #{self.target} #{object_name} due to '#{e}'", e)
        end
      end

      def generate_to_directory!(output_directory, element)
        Reality::Generators.error('generate_to_directory! not implemented')
      end
    end

    class AssetsTemplate < SingleDirectoryOutputTemplate
      def initialize(template_set, facets, target, template_key, output_directory_pattern, helpers, options = {})
        super(template_set, facets, target, template_key, output_directory_pattern, helpers, options)
      end

      protected

      def generate_to_directory!(output_directory, element)
        FileUtils.rm_rf output_directory
        Noft::Generator.generate_assets(element.name, output_directory)
      end
    end
  end
end
