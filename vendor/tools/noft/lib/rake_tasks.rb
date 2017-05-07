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

module Noft #nodoc
  class Build #nodoc
    DEFAULT_RESOURCES_FILENAME = 'noft.rb'

    def self.define_load_task(filename = nil, &block)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      candidate_file = File.expand_path("#{base_directory}/#{DEFAULT_RESOURCES_FILENAME}")
      if filename.nil?
        filename = candidate_file
      elsif File.expand_path(filename) == candidate_file
        Noft.warn("Noft::Build.define_load_task() passed parameter '#{filename}' which is the same value as the default parameter. This parameter can be removed.")
      end
      Noft::LoadResourceDescriptor.new(File.expand_path(filename), &block)
    end

    def self.define_generate_task(generator_keys, options = {}, &block)
      repository_key = options[:repository_key]
      target_dir = options[:target_dir]
      buildr_project = options[:buildr_project]

      if buildr_project.nil? && Buildr.application.current_scope.size > 0
        buildr_project = Buildr.project(Buildr.application.current_scope.join(':')) rescue nil
      end

      build_key = options[:key] || (buildr_project.nil? ? :default : buildr_project.name.split(':').last)

      if target_dir
        base_directory = File.dirname(Buildr.application.buildfile.to_s)
        target_dir = File.expand_path(target_dir, base_directory)
      end

      if target_dir.nil? && !buildr_project.nil?
        target_dir = buildr_project._(:target, :generated, 'resgen', build_key)
      elsif !target_dir.nil? && !buildr_project.nil?
        Noft.warn('Noft::Build.define_generate_task specifies a target directory parameter but it can be be derived from the context. The parameter should be removed.')
      end

      if target_dir.nil?
        Noft.error('Noft::Build.define_generate_task should specify a target directory as it can not be derived from the context.')
      end

      Noft::GenerateTask.new(repository_key, build_key, generator_keys, target_dir, buildr_project, &block)
    end
  end

  class GenerateTask
    attr_accessor :description
    attr_accessor :namespace_key
    attr_accessor :filter
    attr_writer :verbose

    attr_reader :repository_key
    attr_reader :key
    attr_reader :generator_keys
    attr_reader :target_dir

    attr_reader :task_name

    def initialize(repository_key, key, generator_keys, target_dir, buildr_project = nil)
      @repository_key, @key, @generator_keys, @buildr_project =
        repository_key, key, generator_keys, buildr_project
      @namespace_key = :resgen
      @filter = nil
      @template_map = {}
      # Turn on verbose messages if buildr is turned on tracing
      @verbose = trace?
      @target_dir = target_dir
      yield self if block_given?
      define
      @templates = Noft::Generator.generator.load_templates_from_template_sets(generator_keys)
      Reality::Generators::Buildr.configure_buildr_project(buildr_project, task_name, @templates, target_dir)
    end

    private

    def verbose?
      !!@verbose
    end

    def full_task_name
      "#{self.namespace_key}:#{self.key}"
    end

    def define
      desc self.description || "Generates the #{key} artifacts."
      namespace self.namespace_key do
        t = task self.key => ["#{self.namespace_key}:load"] do
          begin

            repository = nil
            if self.repository_key
              repository = Noft.repository_by_name(self.repository_key)
              if Noft.repositories.size == 1
                Noft.warn("Noft task #{full_task_name} specifies a repository_key parameter but it can be be derived as there is only a single repository. The parameter should be removed.")
              end
            elsif self.repository_key.nil?
              repositories = Noft.repositories
              if repositories.size == 1
                repository = repositories[0]
              else
                Noft.error("Noft task #{full_task_name} does not specify a repository_key parameter and it can not be derived. Candidate repositories include #{repositories.collect { |r| r.name }.inspect}")
              end
            end

            repository.send(:extension_point, :scan_if_required)
            repository.send(:extension_point, :validate)

            Reality::Logging.set_levels(verbose? ? ::Logger::DEBUG : ::Logger::WARN,
                                        Noft::Logger,
                                        Reality::Generators::Logger,
                                        Reality::Facets::Logger) do
              Noft.info "Generator started: Generating #{self.generator_keys.inspect}"
              Noft::Generator.generator.generate(:repository,
                                                   repository,
                                                   self.target_dir,
                                                   @templates,
                                                   self.filter)
            end
          rescue Reality::Generators::GeneratorError => e
            puts e.message
            if e.cause
              puts e.cause.class.name.to_s
              puts e.cause.backtrace.join("\n")
            end
            raise e.message
          end
        end
        @task_name = t.name
        Noft::TaskRegistry.get_aggregate_task(self.namespace_key).enhance([t.name])
      end
    end
  end

  class LoadResourceDescriptor
    attr_accessor :description
    attr_accessor :namespace_key
    attr_writer :verbose

    attr_reader :filename

    def initialize(filename)
      @filename = filename
      @namespace_key = :resgen
      yield self if block_given?
      define
    end

    private

    def verbose?
      !!@verbose
    end

    def define
      namespace self.namespace_key do
        task :preload

        task :postload

        desc self.description
        task :load => [:preload, self.filename] do
          begin
            Noft.current_filename = self.filename
            Reality::Logging.set_levels(verbose? ? ::Logger::DEBUG : ::Logger::WARN,
                                        Noft::Logger,
                                        Reality::Generators::Logger,
                                        Reality::Facets::Logger) do

              require self.filename
            end
          rescue Exception => e
            print "An error occurred loading repository\n"
            puts $!
            puts $@
            raise e
          ensure
            Noft.current_filename = nil
          end
          task("#{self.namespace_key}:postload").invoke
        end
        Noft::TaskRegistry.get_aggregate_task(self.namespace_key)
      end
    end
  end

  class TaskRegistry
    class << self
      def get_aggregate_task(namespace)
        all_task = namespace_tasks[namespace.to_s]
        unless all_task
          desc "Generate all #{namespace} artifacts"
          all_task = task('all')
          namespace_tasks[namespace.to_s] = all_task
        end
        all_task
      end

      private

      def namespace_tasks
        @namespace_tasks ||= {}
      end
    end
  end
end