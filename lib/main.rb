require_relative "./libs/app_config_loader"
require_relative "./libs/logger_manager"

module RbParser
  class Main
    def self.start
      config_loader = AppConfigLoader.new("config/default_config.yaml", "config/yaml")

      config_loader.load_libs

      config_data = config_loader.config

      config_loader.pretty_print_config_data

      LoggerManager.initialize_logger(config_data)
      LoggerManager.log_processed_file("example_file")
      LoggerManager.log_error("Example error")
    end
  end
end

RbParser::Main.start