require "yaml"
require "erb"
require "json"

module RbParser
  class AppConfigLoader
    def initialize(config_file, yaml_dir)
      @config_file = config_file
      @yaml_dir = yaml_dir
      @config_data = {}
    end

    def config
      load_default_config
      load_config
      @config_data
    end

    def pretty_print_config_data
      puts JSON.pretty_generate(@config_data)
    end

    def load_libs
      system_libs = ["date"]
      system_libs.each { |lib| require lib }

      Dir.glob(File.expand_path("../*.rb", __dir__)).each do |file|
        require file unless file == __FILE__
      end
    end

    private

    def load_default_config
      erb = ERB.new(File.read(@config_file)).result(binding)
      @config_data.merge!(YAML.safe_load(erb))
    end

    def load_config
      Dir.glob(File.join(@yaml_dir, "*.yaml")).each do |file|
        yaml_content = YAML.safe_load(File.read(file))
        @config_data.merge!(yaml_content)
      end
    end
  end
end