require "logger"
require_relative "app_config_loader"

module RbParser
  class LoggerManager
    class << self
      attr_reader :logger

      def initialize_logger(config_data)
        log_dir = config_data.dig("logging", "directory") || "logs"
        Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

        @logger = Logger.new(File.join(log_dir, config_data.dig("logging", "files", "application_log")))
        @logger.level = Logger.const_get(config_data.dig("logging", "level") || "DEBUG")
      end

      def log_processed_file(file_name)
        @logger.info("Processed file: #{file_name}")
      end

      def log_error(error_message)
        @logger.error("Error: #{error_message}")
      end
    end
  end
end