require File.expand_path('../../helper', __FILE__)

class TestGenerator < Noft::TestCase
  def test_generate_assets
    icon_set = load_sample1_icon_set

    output_directory = local_dir('assets')
    Noft::Generator.generate_assets(icon_set.name, output_directory)

    assert_sample1_dist_output(output_directory)
  end

  def test_generate_assets_with_existing_assets_in_place
    icon_set = load_sample1_icon_set

    git_dir = local_dir('myrepo')
    output_directory = "#{git_dir}/assets/fa"

    create_git_repo(git_dir) do |dir|
      update_dir_from_fixture(output_directory, 'sample1/dist')
      File.write("#{output_directory}/font.ttf", 'random_content')
    end

    Noft::Generator.generate_assets(icon_set.name, output_directory)

    assert_sample1_dist_output(output_directory)

    in_dir(git_dir) do
      assert_equal '', run_command('git status -s')
    end
  end

  def test_reset_state_if_unchanged
    git_dir = local_dir('myrepo')
    create_git_repo(git_dir) do |dir|
      update_dir_from_fixture(dir, 'sample1')
      File.write('font.ttf', 'random_content')
    end

    in_dir(git_dir) do
      File.write('font.ttf', 'other content')
      assert_equal " M font.ttf\n", run_command('git status -s')
      Noft::Generator.send(:reset_state_if_unchanged, git_dir)
      assert_equal '', run_command('git status -s')
    end
  end
end
