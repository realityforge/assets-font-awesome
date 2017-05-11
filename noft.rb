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
BASE_WORKING_DIRECTORY = File.expand_path('tmp/working')
WORKING_DIRECTORY = "#{BASE_WORKING_DIRECTORY}/#{INPUT_VERSION}"

Noft.icon_set(:fa) do |s|
  s.display_string = 'Font Awesome'
  s.description = 'The iconic font and CSS toolkit'
  s.version = INPUT_VERSION
  s.url = 'http://fontawesome.io'
  s.license = 'SIL Open Font License (OFL)'
  s.license_url = 'http://scripts.sil.org/OFL'
  s.font_file = "#{WORKING_DIRECTORY}/fontawesome-webfont.svg"

  icon_metadata_filename = "#{WORKING_DIRECTORY}/icons.yml"

  # Download font assets
  NoftPlus::Util.download_file("https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v#{INPUT_VERSION}/src/icons.yml",
                               icon_metadata_filename)
  NoftPlus::Util.download_file("https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v#{INPUT_VERSION}/fonts/fontawesome-webfont.svg",
                               s.font_file)

  #scan font descriptor for required metadata
  YAML.load_file(icon_metadata_filename)['icons'].each do |entry|
    name = entry['id'].gsub(/-o$/, '-outlined').gsub(/-o-/, '-outlined-')

    s.icon(name) do |i|
      i.display_string = entry['name'] unless entry['name'] == name || entry['name'] == Reality::Naming.humanize(name)
      i.unicode = entry['unicode']
      entry['aliases'].each do |a|
        i.aliases << a
      end if entry['aliases']
    end
  end
end


module Schmooze
  class Base
    class << self
      protected
        def dependencies(deps)
          @_schmooze_imports ||= []
          deps.each do |identifier, package|
            @_schmooze_imports << {
              identifier: identifier,
              package: package
            }
          end
        end

        def method(name, code)
          @_schmooze_methods ||= []
          @_schmooze_methods << {
            name: name,
            code: code
          }

          define_method(name) do |*args|
            call_js_method(name, args)
          end
        end

        def finalize(stdin, stdout, stderr, process_thread)
          proc do
            stdin.close
            stdout.close
            stderr.close
            Process.kill(0, process_thread.pid)
            process_thread.value
          end
        end
    end

    def initialize(root, env={})
      @_schmooze_env = env
      @_schmooze_root = root
      @_schmooze_code = ProcessorGenerator.generate(self.class.instance_variable_get(:@_schmooze_imports) || [], self.class.instance_variable_get(:@_schmooze_methods) || [])
    end

    def pid
      @_schmooze_process_thread && @_schmooze_process_thread.pid
    end

    private
      def ensure_process_is_spawned
        return if (@_schmooze_process_thread ||= nil)
        spawn_process
      end

      def spawn_process
        process_data = Open3.popen3(
          @_schmooze_env,
          'node',
          '-e',
          @_schmooze_code,
          chdir: @_schmooze_root
        )
        p process_data
        ensure_packages_are_initiated(*process_data)
        ObjectSpace.define_finalizer(self, self.class.send(:finalize, *process_data))
        @_schmooze_stdin, @_schmooze_stdout, @_schmooze_stderr, @_schmooze_process_thread = process_data
      end

      def ensure_packages_are_initiated(stdin, stdout, stderr, process_thread)
        input = stdout.gets
        raise Schmooze::Error, "Failed to instantiate Schmooze process:\n#{stderr.read}" if input.nil?
        result = JSON.parse(input)
        unless result[0] == 'ok'
          stdin.close
          stdout.close
          stderr.close
          process_thread.join

          error_message = result[1]
          if /\AError: Cannot find module '(.*)'\z/ =~ error_message
            package_name = $1
            package_json_path = File.join(@_schmooze_root, 'package.json')
            begin
              package = JSON.parse(File.read(package_json_path))
              %w(dependencies devDependencies).each do |key|
                if package.has_key?(key) && package[key].has_key?(package_name)
                  raise Schmooze::DependencyError, "Cannot find module '#{package_name}'. The module was found in '#{package_json_path}' however, please run 'npm install' from '#{@_schmooze_root}'"
                end
              end
            rescue Errno::ENOENT
            end
            raise Schmooze::DependencyError, "Cannot find module '#{package_name}'. You need to add it to '#{package_json_path}' and run 'npm install'"
          else
            raise Schmooze::Error, error_message
          end
        end
      end

      def call_js_method(method, args)
        ensure_process_is_spawned
        @_schmooze_stdin.puts JSON.dump([method, args])
        input = @_schmooze_stdout.gets
        raise Errno::EPIPE, "Can't read from stdout" if input.nil?

        p input

        status, message, error_class = JSON.parse(input)

        if status == 'ok'
          message
        else
          if error_class.nil?
            raise Schmooze::JavaScript::UnknownError, message
          else
            raise Schmooze::JavaScript.const_get(error_class, false), message
          end
        end
      rescue Errno::EPIPE, IOError
        # TODO(bouk): restart or something? If this happens the process is completely broken
        raise ::StandardError, "Schmooze process failed:\n#{@_schmooze_stderr.read}"
      end
  end
end
