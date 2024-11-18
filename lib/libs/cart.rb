require "json"
require "csv"
require "yaml"
require_relative "./item_container"
require_relative "./logger_manager"

module RbParser
  class Cart
    include ItemContainer
    include Enumerable

    attr_accessor :items

    def initialize
      @items = []
      LoggerManager.log_info("Cart initialized with an empty items array")
    end

    def add_item(item)
      @items << item
      LoggerManager.log_info("Item added to cart: #{item.info}")
    end

    def save_to_file(filename = "items.txt")
      # Створення папки output, якщо вона не існує
      Dir.mkdir("output") unless Dir.exist?("output")
      File.open("output/#{filename}", "w") do |file|
        @items.each { |item| file.puts item.info }
      end
      LoggerManager.log_info("Items saved to text file: output/#{filename}")
    end

    def generate_test_items(count)
      count.times do
        item = RbParser::Item.generate_fake
        add_item(item)
      end
      LoggerManager.log_info("#{count} test items generated")
    end

    def save_to_json(filename = "items.json")
      Dir.mkdir("output") unless Dir.exist?("output")
      File.write("output/#{filename}", @items.map(&:to_h).to_json)
      LoggerManager.log_info("Items saved to JSON file: output/#{filename}")
    end

    def save_to_csv(filename = "items.csv")
      Dir.mkdir("output") unless Dir.exist?("output")
      CSV.open("output/#{filename}", "w") do |csv|
        csv << @items.first.to_h.keys if @items.any?
        @items.each { |item| csv << item.to_h.values }
      end
      LoggerManager.log_info("Items saved to CSV file: output/#{filename}")
    end

    def save_to_yml(dir = "items_yaml")
      # Створення папки output/items_yaml, якщо її не існує
      Dir.mkdir("output/#{dir}") unless Dir.exist?("output/#{dir}")
      @items.each_with_index do |item, index|
        File.write("output/#{dir}/item_#{index + 1}.yml", item.to_h.to_yaml)
      end
      LoggerManager.log_info("Items saved to YAML files in directory: output/#{dir}")
    end

    # Enumerable methods adapted for Item objects
    def map_items(&block)
      items.map(&block)
    end

    def select_items(&block)
      items.select(&block)
    end

    def reject_items(&block)
      items.reject(&block)
    end

    def find_item(&block)
      items.find(&block)
    end

    def reduce_items(initial_value, &block)
      items.reduce(initial_value, &block)
    end

    def all_items?(&block)
      items.all?(&block)
    end

    def any_item?(&block)
      items.any?(&block)
    end

    def none_items?(&block)
      items.none?(&block)
    end

    def count_items(&block)
      items.count(&block)
    end

    def sort_items(&block)
      items.sort(&block)
    end

    def uniq_items
      items.uniq
    end

    def each(&block)
      @items.each(&block)
    end
  end
end
