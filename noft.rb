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

require 'json'
require 'reality/logging'
require 'reality/model'
require 'reality/naming'
require 'fileutils'
require 'schmooze'

# noft is a script to pull down fonts and extract them into svg assets that can be used as desired.

module Noft
  Reality::Logging.configure(Noft, ::Logger::WARN)

  Reality::Model::Repository.new(:Noft, Noft) do |r|
    r.model_element(:icon_set)
    r.model_element(:icon, :icon_set)
  end

  class IconSet
    # A human readable name for icon set
    attr_accessor :display_string
    attr_accessor :description
    # The version of the source library from which this was extracted
    attr_accessor :version
    # The url to the source library
    attr_accessor :url
    # The license of the library
    attr_accessor :license
    # The url of the license
    attr_accessor :license_url

    def write_to(filename)
      File.write(filename, JSON.pretty_generate(to_h) + "\n")
    end

    def to_h
      data = { :name => self.name }
      data[:display_string] = self.display_string if self.display_string
      data[:description] = self.description if self.description
      data[:version] = self.version if self.version
      data[:url] = self.url if self.url
      data[:license] = self.license if self.license
      data[:license_url] = self.license_url if self.license_url

      data[:icons] = {}
      self.icons.each do |icon|
        data[:icons][icon.name] = icon.to_h
      end

      data
    end
  end

  class Icon
    # A human readable name for icon
    attr_accessor :display_string
    attr_accessor :description

    # The unicode that it was assigned inside the font.
    attr_accessor :unicode

    def qualified_name
      "#{self.icon_set.name}-#{self.name}"
    end

    # Categories which this Icon exists. Useful when displaying an icon sheet.
    def categories
      @categories ||= []
    end

    # Alternative aliases under which this icon may be known.
    def aliases
      @aliases ||= []
    end

    def to_h
      data = {}
      data[:display_string] = self.display_string if self.display_string
      data[:description] = self.description if self.description
      data[:aliases] = self.aliases unless self.aliases.empty?
      data[:categories] = self.categories unless self.categories.empty?

      data
    end
  end

  class FontBlast < Schmooze::Base
    dependencies fontBlast: 'font-blast'

    method :blast, 'function(fontFile, destinationFolder, userConfig) {fontBlast(fontFile, destinationFolder, userConfig);}'
  end

  class Generator
    class << self
      def generate_assets(icon_set, output_directory)
        FileUtils.rm_rf output_directory

        # Generate filename mapping
        filenames = {}
        icon_set.icons.each { |icon| filenames[icon.unicode] = icon.name }

        # Actually run the font blast to extract out the svg files
        Noft::FontBlast.new(Dir.pwd).blast(icon_set.font_file, output_directory, { :filenames => filenames })

        # Output the metadata
        icon_set.write_to("#{output_directory}/svg/fonts.json")
      end
    end
  end
end

INPUT_VERSION='4.7.0'
OUTPUT_DIRECTORY = 'assets'
BASE_WORKING_DIRECTORY = 'tmp/working'
WORKING_DIRECTORY = "#{BASE_WORKING_DIRECTORY}/#{INPUT_VERSION}"

FileUtils.mkdir_p WORKING_DIRECTORY

require 'uri'
require 'net/http'
require 'yaml'

def download_file(url, target_filename)
  unless File.exist?(target_filename)
    File.write(target_filename, Net::HTTP.get(URI(url)))
  end
end

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

  #p YAML.load_file(icon_metadata_filename)
  YAML.load_file(icon_metadata_filename)['icons'].each do |entry|
    s.icon(entry['id']) do |i|
      i.display_string = entry['name'] unless entry['name'] == entry['id']
      entry['aliases'].each do |a|
        i.aliases << a
      end if entry['aliases']
    end
  end
end


output_directory = OUTPUT_DIRECTORY
FileUtils.mkdir_p output_directory
icon_set = Noft.icon_set_by_name(:fa)
icon_set.write_to("#{output_directory}/fonts.json")
