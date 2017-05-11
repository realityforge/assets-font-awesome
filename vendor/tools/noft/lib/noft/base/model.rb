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
    class BaseRepository
      class << self
        include Noft::ArtifactDSL

        def facet_key
          nil
        end

        def target_key
          :icon_set
        end
      end

      artifact(:svg_assets, :guard => 'icon_set.font_file?') do |template_set, facets, helpers, template_options|
        Noft::Base::AssetsTemplate.new(template_set, facets, self.target_key, 'svg_assets', helpers, template_options)
      end
    end
  end
end
