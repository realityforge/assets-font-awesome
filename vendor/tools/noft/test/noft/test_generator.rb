require File.expand_path('../../helper', __FILE__)

class TestGenerator < Noft::TestCase
  def test_generate_assets
    icon_set = load_sample1_icon_set

    output_directory = "#{working_dir}/assets"
    Noft::Generator.generate_assets(icon_set.name, output_directory)

    assert_fixture_matches_output('sample1_fire.svg', "#{output_directory}/svg/fire.svg")
    assert_fixture_matches_output('sample1_fire-extinguisher.svg', "#{output_directory}/svg/fire-extinguisher.svg")
    assert_fixture_matches_output('sample1_fire-symbol.svg', "#{output_directory}/svg/fire-symbol.svg")
    assert_fixture_matches_output('sample1.json', "#{output_directory}/svg/fonts.json")

    assert_true File.exist?("#{output_directory}/source-font.ttf")
    assert_true File.exist?("#{output_directory}/verify.html")
  end

  def assert_fixture_matches_output(fixture_name, output_filename)
    assert_equal true, File.exist?(output_filename), "Expected filename to be created #{output_filename}"
    assert_equal IO.read(fixture(fixture_name)), IO.read(output_filename), "Content generated into #{output_filename}"
  end
end
