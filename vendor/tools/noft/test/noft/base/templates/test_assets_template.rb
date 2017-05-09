require File.expand_path('../../../../helper', __FILE__)

class TestAssetsTemplate < Noft::TestCase
  def test_generate_assets
    icon_set = load_sample1_icon_set
    output_directory = run_generators([:svg_assets], icon_set)

    assert_sample1_dist_output("#{output_directory}/assets/sample1")
  end
end
