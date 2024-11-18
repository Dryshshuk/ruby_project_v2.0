require 'yaml'
require 'sqlite3'
require 'mongo'

class DatabaseConnector
  attr_reader :config, :sqlite_db, :mongodb_client

  def initialize(config_path)
    load_config(config_path)
  end

  def load_config(config_path)
    @config = YAML.load_file(config_path)
    puts "Loaded config: #{@config.inspect}"  # Debug line to check the content
  rescue StandardError => e
    raise "Error loading database config: #{e.message}"
  end

  def connect_to_databases
  if @config && @config["database"]
    # SQLite Connection
    if @config["database"]["sqlite"]
      sqlite_path = @config["database"]["sqlite"]["path"]
      @sqlite_db = SQLite3::Database.new(sqlite_path)
      puts "Connected to SQLite database at #{sqlite_path}"
    end

    # MongoDB Connection
    if @config["database"]["mongodb"]
      host = @config["database"]["mongodb"]["host"]
      port = @config["database"]["mongodb"]["port"]
      db_name = @config["database"]["mongodb"]["database_name"]
      @mongodb_client = Mongo::Client.new(["#{host}:#{port}"], database: db_name)
      puts "Connected to MongoDB at #{host}:#{port}, Database: #{db_name}"
    end
    else
      raise "Database configuration is missing or invalid"
    end
  rescue StandardError => e
    raise "Error connecting to database(s): #{e.message}"
  end

  def close_connections
    # Close SQLite connection
    @sqlite_db.close if @sqlite_db

    # Close MongoDB connection
    @mongodb_client.close if @mongodb_client
  rescue StandardError => e
    puts "Error closing database connections: #{e.message}"
  end
end
