require 'csv'
require 'json'
require 'yaml'
require 'sqlite3'
require 'mongo'
require 'pony'
require 'zip'

require_relative "./libs/simple_website_parser"
require_relative "./libs/item"
require_relative "./libs/database_connector"

module RbParser
  class Engine
    attr_reader :parser, :config, :db_connector

    def initialize(config_path, db_config_path)
      @config_path = config_path
      @db_connector = DatabaseConnector.new(db_config_path)
      load_config
      initialize_parser
    end

    def load_config
      @config = YAML.load_file(@config_path)
      puts "Configuration loaded successfully from #{@config_path}"
    rescue StandardError => e
      puts "Failed to load configuration: #{e.message}"
    end

    def initialize_parser
      @parser = RbParser::SimpleWebsiteParser.new(@config_path)
    end

    def run
      puts "Running Engine..."
      db_connector.connect_to_databases
      parser.start_parse
      puts "Items collected: #{parser.item_collection.size}"

      parser.item_collection.each_with_index do |item, index|
        puts "Item #{index + 1}: #{item.to_h}"
      end

      if parser.item_collection.empty?
        puts "No items were collected. Check the configuration and selectors."
        return
      end

      if config["methods"].nil? || config["methods"].empty?
        puts "No methods specified in configuration to execute."
      else
        puts "Methods to execute: #{config["methods"].inspect}"
      end

      run_methods(config["methods"])

    ensure
      db_connector.close_connections
    end

    def run_methods(config_params)
      unless config_params.is_a?(Array)
        puts "Configuration error: 'methods' should be an array of method names."
        return
      end

      config_params.each do |method_name|
        if respond_to?(method_name)
          send(method_name)
        else
          puts "Method #{method_name} not found or cannot be executed."
        end
      rescue StandardError => e
        puts "Error executing #{method_name}: #{e.message}"
      end
    end

    def run_website_parser
      parser.start_parse
      puts "Website parsing completed with #{parser.item_collection.size} items."
    end

    def run_save_to_csv
      CSV.open("output/data.csv", "w") do |csv|
        csv << ["Title", "Price", "Image URL"]
        parser.item_collection.each do |item|
          csv << [item.title, item.price, item.image_url]
          puts "Saving item: #{item.title}, #{item.price}, #{item.image_url}"
        end
      end
      puts "Data saved to CSV at output/data.csv"
    end

    def run_save_to_json
      data = parser.item_collection.map(&:to_h)
      File.write("output/data.json", JSON.pretty_generate(data))
      puts "Data saved to JSON at output/data.json"
    end

    def run_save_to_yaml
      data = parser.item_collection.map(&:to_h)
      File.write("output/data.yaml", data.to_yaml)
      puts "Data saved to YAML at output/data.yaml"
    end

    def run_save_to_sqlite
      db = db_connector.sqlite_db
      db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS items (
          id INTEGER PRIMARY KEY,
          title TEXT,
          price TEXT,
          image_url TEXT
        );
      SQL

      parser.item_collection.each do |item|
        db.execute("INSERT INTO items (title, price, image_url) 
                    VALUES (?, ?, ?)", 
                    [item.title, item.price, item.image_url])
      end
      puts "Data saved to SQLite at #{db_connector.get_sqlite_path}"
    end

    def run_save_to_mongodb
      client = db_connector.mongodb_client
      collection_name = db_connector.get_mongodb_collection_name
      items_collection = client[collection_name.to_sym]

      data = parser.item_collection.map(&:to_h)
      items_collection.insert_many(data)
      puts "Data saved to MongoDB in database '#{db_connector.get_mongodb_name}'"
    end
  end
end
