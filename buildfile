require 'noft_plus'

Noft::Build.define_load_task
Noft::Build.define_generate_task([], :target_dir => 'target/assets')