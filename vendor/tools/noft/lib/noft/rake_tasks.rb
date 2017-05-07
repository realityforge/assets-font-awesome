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

module Noft #nodoc
  class Build #nodoc
    DEFAULT_DESCRIPTOR_FILENAME = 'noft.rb'

    class << self
      include Reality::Generators::Rake::BuildTasksMixin

      def default_descriptor_filename
        DEFAULT_DESCRIPTOR_FILENAME
      end

      def generated_type_path_prefix
        :noft
      end

      def root_element_type
        :icon_set
      end

      def log_container
        Noft
      end
    end

    class GenerateTask < Reality::Generators::Rake::BaseGenerateTask
      def initialize(icon_set_key, key, generator_keys, target_dir, buildr_project = nil)
        super(icon_set_key, key, generator_keys, target_dir, buildr_project)
      end

      protected

      def default_namespace_key
        :noft
      end

      def generator_container
        Noft::Generator
      end

      def instance_container
        Noft
      end

      def root_element_type
        :icon_set
      end

      def log_container
        Noft
      end
    end

    class LoadDescriptor < Reality::Generators::Rake::BaseLoadDescriptor
      protected

      def default_namespace_key
        :noft
      end

      def log_container
        Noft
      end
    end
  end
end
