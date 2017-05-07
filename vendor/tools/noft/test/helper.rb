$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'noft'

module Noft
  class << self
    def reset
      self.send(:icon_set_map).clear
    end
  end
end

class Noft::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    @cwd = Dir.pwd

    FileUtils.mkdir_p self.working_dir
    Dir.chdir(self.working_dir)
    File.write("#{self.working_dir}/package.json", package_json)

    self.setup_node_modules

    Noft.reset
  end

  def teardown
    self.unlink_node_modules
    Dir.chdir(@cwd)
    FileUtils.rm_rf self.working_dir if File.exist?(self.working_dir)
  end

  def setup_node_modules
    node_modules_present = File.exist?(self.node_modules_dir)
    FileUtils.mkdir_p self.node_modules_dir
    FileUtils.link(self.node_modules_dir, "#{self.working_dir}/node_modules")
    system('npm install') unless node_modules_present
  end

  def unlink_node_modules
    FileUtils.rm("#{self.working_dir}/node_modules")
  end

  def create_file(filename, content)
    expanded_filename = "#{working_dir}/#{filename}"
    FileUtils.mkdir_p File.dirname(expanded_filename)
    File.write(expanded_filename, content)
    expanded_filename
  end

  def create_filename(extension = '')
    "#{working_dir}/#{SecureRandom.hex}#{extension}"
  end

  def working_dir
    @working_dir ||= "#{workspace_dir}/#{SecureRandom.hex}"
  end

  def workspace_dir
    @workspace_dir ||= ENV['TEST_TMP_DIR'] || File.expand_path("#{File.dirname(__FILE__)}/../tmp/workspace")
  end

  def node_modules_dir
    @node_modules_dir ||= "#{workspace_dir}/node_modules"
  end

  def package_json
    <<JSON
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "A project used to test",
  "author": "",
  "license": "Apache-2.0",
  "repository": ".",
  "devDependencies": {
    "font-blast": "^0.6.1"
  }
}
JSON
  end
end
