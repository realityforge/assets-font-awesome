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
    class AssetsTemplate < Reality::Generators::Template
      def initialize(template_set, facets, target, template_key, helpers, options = {})
        super(template_set, facets, target, template_key, helpers, options)
      end

      protected

      def generate!(target_basedir, element, unprocessed_files)
        base_dir = File.join(target_basedir, 'assets')
        output_dir = File.join(base_dir, element.name.to_s)

        FileUtils.rm_rf output_dir
        Noft::Generator.generate_assets(element.name, output_dir)
        unprocessed_files.delete_if { |f| f =~ /^#{output_dir}\/.*/ }
      end
    end
  end
end
