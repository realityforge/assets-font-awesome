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
  class FontBlast < Schmooze::Base
    dependencies fontBlast: 'font-blast'

    method :blast, 'function(fontFile, destinationFolder, userConfig) {fontBlast(fontFile, destinationFolder, userConfig);}'
  end

  module Generator
    class << self
      def generate_assets(icon_set_name, output_directory)
        icon_set = Noft.icon_set_by_name(icon_set_name)
        FileUtils.rm_rf output_directory

        metadata_file = "#{output_directory}/fonts.json"

        FileUtils.mkdir_p File.dirname(metadata_file)

        icon_set.write_to(metadata_file)

        # Generate filename mapping
        filenames = {}
        icon_set.icons.each { |icon| filenames[icon.unicode] = icon.name }

        # Actually run the font blast to extract out the svg files
        Noft::FontBlast.new('.').blast(icon_set.font_file, output_directory, { :filenames => filenames })

        # Node writes the file asynchronously. This needs to be in place to ensure
        # all the files are written as it is the last file to be generated
        wait_until { File.exist?("#{output_directory}/verify.html") }

        FileUtils.rm "#{output_directory}/verify.html"
        FileUtils.mv "#{output_directory}/source-font.ttf", "#{output_directory}/font.ttf"
        FileUtils.mv Dir["#{output_directory}/svg/*.svg"], output_directory
        FileUtils.rmdir "#{output_directory}/svg"

        reset_state_if_unchanged(output_directory)

        output_directory
      end

      private

      # if the assets are stored in git and the only file that is modified is font.ttf
      # then we can assume that there is no actual change, just a result of the underlying svg2ttf
      # tool not giving a stable output given stable input. Unclear where the fault lies. In this
      # scenario just reset the file.
      # Note: svg2ttf uses current date for some fields even if you pass in a date. Also font-blast
      # does not pass in a date.
      def reset_state_if_unchanged(output_directory)
        output = `git status -s #{output_directory}`
        if output.split("\n").size == 1 &&
          -1 != (output =~ /^ M (.*\/)font.ttf$/)
          `git checkout #{output_directory}/font.ttf`
        end
      end

      def wait_until(count = 100000, &block)
        i = count
        while i > 0
          if block.call
            break
          else
            i -= 1
            Thread.pass
            sleep 1
          end
        end
        Noft.error('Node failed to generate the required files within an expected time frame') unless block.call
      end
    end
  end
end
