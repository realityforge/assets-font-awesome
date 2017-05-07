$:.unshift File.expand_path('../../lib', __FILE__)

require 'securerandom'
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
    if passed?
      FileUtils.rm_rf self.working_dir if File.exist?(self.working_dir)
    else
      $stderr.puts "Test #{self.class.name}.#{name} Failed. Leaving working directory #{self.working_dir}"
    end
  end

  def setup_node_modules
    node_modules_present = File.exist?(self.node_modules_dir)
    FileUtils.mkdir_p self.node_modules_dir
    FileUtils.ln_s(self.node_modules_dir, self.local_node_modules_dir)
    system('npm install') unless node_modules_present
  end

  def unlink_node_modules
    FileUtils.rm(self.local_node_modules_dir) if File.exist?(self.local_node_modules_dir)
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

  def local_node_modules_dir
    "#{self.working_dir}/node_modules"
  end

  # The base test directory
  def test_dir
    @test_dir ||= File.expand_path("#{File.dirname(__FILE__)}")
  end

  # The fixtures directory
  def fixture_dir
    "#{test_dir}/fixtures"
  end

  def fixture(filename)
    "#{fixture_dir}/#{filename}"
  end

  def load_sample1_icon_set
    # Load data from fixture json and make sure we link up all the non persisted attributes

    icon_set = Noft.read_model(fixture('sample1/fonts.json'))
    icon_set.font_file = fixture('sample1/webfont.svg')

    icon_set.icon_by_name('fire-extinguisher').unicode = 'f100'
    icon_set.icon_by_name('fire-symbol').unicode = 'f101'
    icon_set.icon_by_name('fire').unicode = 'f102'

    icon_set
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
