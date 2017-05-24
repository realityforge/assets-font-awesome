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
  Reality::Mda.define_system(Noft) do |r|
    r.model_element(:icon_set)
    r.model_element(:icon, :icon_set)
  end

  class << self
    def read_model(filename)
      data = JSON.parse(IO.read(filename))
      name = data['name']
      Noft.error("Noft icon model configuration file '#{filename}' is missing a name") unless name
      icon_set = Noft.icon_set(name.to_sym)
      icon_set.read_from(data)
      icon_set
    end
  end

  module Model #nodoc
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
      # The local filename of the font file
      attr_accessor :font_file

      def font_file?
        !(@font_file ||= nil).nil?
      end

      def write_to(filename)
        File.write(filename, JSON.pretty_generate(to_h) + "\n")
      end

      def read_from(data)
        self.display_string = data['displayString'] if data['displayString']
        self.description = data['description'] if data['description']
        self.version = data['version'] if data['version']
        self.url = data['url'] if data['url']
        self.license = data['license'] if data['license']
        self.license_url = data['licenseUrl'] if data['licenseUrl']

        data['icons'].each_pair do |icon_name, icon_data|
          self.icon(icon_name.to_sym).read_from(icon_data)
        end if data['icons']
      end

      def to_h
        data = {}
        data[:name] = self.name
        data[:displayString] = self.display_string if self.display_string
        data[:description] = self.description if self.description
        data[:version] = self.version if self.version
        data[:url] = self.url if self.url
        data[:license] = self.license if self.license
        data[:licenseUrl] = self.license_url if self.license_url

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

      # Categories which this Icon exists. Useful when displaying an icon sheet.
      def categories
        @categories ||= []
      end

      # Alternative aliases under which this icon may be known.
      def aliases
        @aliases ||= []
      end

      def read_from(data)
        self.display_string = data['displayString'] if data['displayString']
        self.description = data['description'] if data['description']
        self.unicode = data['unicode'] if data['unicode']
        data['aliases'].each do |a|
          self.aliases << a
        end if data['aliases']
        data['categories'].each do |c|
          self.categories << c
        end if data['categories']
      end

      def to_h
        data = {}
        data[:displayString] = self.display_string if self.display_string
        data[:description] = self.description if self.description
        data[:aliases] = self.aliases unless self.aliases.empty?
        data[:categories] = self.categories unless self.categories.empty?
        data[:unicode] = self.unicode if self.unicode

        data
      end
    end
  end
end
