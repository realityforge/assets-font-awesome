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
    class AssetsTemplate < Reality::Generators::SingleDirectoryOutputTemplate
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
