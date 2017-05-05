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
    @base_temp_dir ||= ENV['TEST_TMP_DIR'] || File.expand_path("#{File.dirname(__FILE__)}/../tmp")
    @temp_dir = "#{@base_temp_dir}/#{name}"
    FileUtils.mkdir_p @temp_dir

    Noft.reset
  end

  def teardown
    FileUtils.rm_rf @base_temp_dir if File.exist?(@base_temp_dir)
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
    @temp_dir
  end
end
