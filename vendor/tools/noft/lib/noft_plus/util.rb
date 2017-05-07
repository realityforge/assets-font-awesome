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

module NoftPlus
  module Util
    class << self

      # Download file to target unless it is already present
      # Typically used to download font libraries from a remote location
      def download_file(url, target_filename)
        unless File.exist?(target_filename)
          FileUtils.mkdir_p File.dirname(target_filename)
          File.write(target_filename, Net::HTTP.get(URI(url)))
        end
      end
    end
  end
end
