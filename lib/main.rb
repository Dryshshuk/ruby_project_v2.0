require_relative "./libs/app_config_loader"
require_relative "./libs/logger_manager"
require_relative "./libs/configurator"
require_relative "./libs/item"
require_relative "./libs/cart"

module RbParser
  class Main
    def self.start
      config_loader = AppConfigLoader.new("config/default_config.yaml", "config/yaml")

      config_loader.load_libs

      config_data = config_loader.config

      config_loader.pretty_print_config_data

      LoggerManager.initialize_logger(config_data)
      LoggerManager.log_processed_file("example_file")

      item = RbParser::Item.new(title: "Товар 1", price: 150) do |i|
        i.subtitle = "Це підзаголовок товару 1"
      end

      puts item.to_s
      puts item.to_h
      puts item.inspect

      item.update do |i|
        i.title = "Новий товар"
        i.price = 100
      end

      puts item.info

      fake_item = RbParser::Item.generate_fake
      puts fake_item.info

      puts "\n\n===================== Lab3.2 ==========================\n\n"
      cart = RbParser::Cart.new
      cart.generate_test_items(5)
      cart.show_all_items

      cart.save_to_file
      cart.save_to_json
      cart.save_to_csv
      cart.save_to_yml

      puts "Class info: #{Cart.class_info}"
      puts "Total items created: #{Cart.item_count}"

      expensive_items = cart.select_items { |item| item.price > 50 }
      puts "Expensive items: #{expensive_items}"
      puts "\n\n=======================================================\n\n"

      # Configurator boom 😎
      puts "\n\n===================== Lab3.3 ==========================\n\n"
      configurator = RbParser::Configurator.new

      puts "\n\nStarted configuration: #{configurator.config}\n"

      configurator.configure(
        run_website_parser: 1,
        run_save_to_csv: 1,
        run_save_to_yaml: 1,
        run_save_to_sqlite: 1
      )

      puts "Configs after updates: #{configurator.config}\n\n"
      puts "Available configs: #{RbParser::Configurator.available_methods}"
      puts "\n\n=======================================================\n\n"
    end
  end
end

RbParser::Main.start