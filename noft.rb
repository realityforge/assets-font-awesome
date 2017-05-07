#!/usr/bin/env ruby

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

require 'rubygems'
require 'bundler/setup'
require 'noft_plus'
require 'yaml'

INPUT_VERSION='4.7.0'
OUTPUT_DIRECTORY = 'assets'
BASE_WORKING_DIRECTORY = 'tmp/working'
WORKING_DIRECTORY = "#{BASE_WORKING_DIRECTORY}/#{INPUT_VERSION}"

icon_metadata_filename = "#{WORKING_DIRECTORY}/icons.yml"
svg_font_filename = "#{WORKING_DIRECTORY}/fontawesome-webfont.svg"
download_file("https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v#{INPUT_VERSION}/src/icons.yml",
              icon_metadata_filename)
download_file("https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v#{INPUT_VERSION}/fonts/fontawesome-webfont.svg",
              svg_font_filename)

Noft.icon_set(:fa) do |s|
  s.display_string = 'Font Awesome'
  s.description = 'The iconic font and CSS toolkit'
  s.version = INPUT_VERSION
  s.url = 'http://fontawesome.io'
  s.license = 'SIL Open Font License (OFL)'
  s.license_url = 'http://scripts.sil.org/OFL'
  s.font_file = svg_font_filename

  #p YAML.load_file(icon_metadata_filename)
  YAML.load_file(icon_metadata_filename)['icons'].each do |entry|
    name = entry['id'].gsub(/-o$/,'-outlined').gsub(/-o-/,'-outlined-')

    s.icon(name) do |i|
      i.display_string = entry['name'] unless entry['name'] == name || entry['name'] == Reality::Naming.humanize(name)
      i.unicode = entry['unicode']
      entry['aliases'].each do |a|
        i.aliases << a
      end if entry['aliases']
    end
  end
end


output_directory = OUTPUT_DIRECTORY
icon_set = Noft.icon_set_by_name(:fa)

Noft::Generator.generate_assets(icon_set, output_directory)
