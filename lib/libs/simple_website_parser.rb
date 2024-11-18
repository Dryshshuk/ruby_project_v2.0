require 'mechanize'
require 'yaml'
require 'fileutils'
require 'securerandom'

require_relative '../libs/logger_manager'
require_relative '../libs/item'

module RbParser
  class SimpleWebsiteParser
    attr_reader :config, :agent, :item_collection

    def initialize(config_path)
      @config = YAML.load_file(config_path)
      @agent = Mechanize.new
      @item_collection = []
      LoggerManager.log_processed_file("Initialized SimpleWebsiteParser with config #{config_path}")
    end

    def start_parse
      LoggerManager.log_processed_file("Starting parsing process")
      url = config['start_page']

      if check_url_response(url)
        page = agent.get(url)
        product_links = extract_products_links(page)

        threads = product_links.map do |product_link|
          Thread.new do
            parse_product_page(product_link)
          end
        end

        threads.each(&:join)
        LoggerManager.log_processed_file("Finished parsing product pages")
      else
        LoggerManager.log_error("Start URL is not accessible: #{url}")
      end
    end

    def extract_products_links(page)
      # eBay specific selector for product links
      product_selector = '.s-item__link'
      links = page.search(product_selector).map { |link| link['href'] }
      LoggerManager.log_processed_file("Extracted #{links.size} product links")
      links
    end

    def parse_product_page(product_link)
      unless check_url_response(product_link)
        LoggerManager.log_error("Product page is not accessible: #{product_link}")
        return
      end

      begin
        product_page = agent.get(product_link)
        name = extract_product_name(product_page)
        price = extract_product_price(product_page)
        description = extract_product_description(product_page)
        image_url = extract_product_image(product_page)
        category = config['selectors']['category']

        image_path = save_product_image(image_url, category)

        item = Item.new(
          name: name,
          price: price,
          description: description,
          category: category,
          image_path: image_path
        )

        @item_collection << item
        LoggerManager.log_processed_file("Parsed product: #{name}, Price: #{price}, Description: #{description}, Category: #{category}, Image Path: #{image_path}")

      rescue StandardError => e
        LoggerManager.log_error("Failed to parse product page at #{product_link}: #{e.message}")
      end
    end

    def extract_product_name(product)
      # Extract name of the product from eBay's page
      product.search('.x-item-title').text.strip
    end

    def extract_product_price(product)
      # eBay specific selector for price
      price = product.search('.x-price-primary .x-price-approx__price').text.strip
      price.empty? ? product.search('.x-price-primary .x-price-primary__price').text.strip : price
    end

    def extract_product_description(product)
      # eBay might not have a structured description directly available in the HTML for all items
      # Often descriptions are dynamically loaded, so you may need a more complex approach like using eBay's API for full data
      description = product.search('.d-item-condition').text.strip
      description.empty? ? 'No description available' : description
    end

    def extract_product_image(product)
      # eBay uses images embedded in their HTML, so you need to target the correct image selector
      image = product.search('.d-item-image img').first['src']
      LoggerManager.log_processed_file("Extracted image URL: #{image}")
      image
    end

    def save_product_image(image_url, category)
      media_dir = File.join('media', category)
      FileUtils.mkdir_p(media_dir)
      image_path = File.join(media_dir, "#{SecureRandom.uuid}.jpg")

      begin
        @agent.get(image_url).save(image_path)
        LoggerManager.log_processed_file("Saved image to #{image_path}")
      rescue StandardError => e
        LoggerManager.log_error("Failed to download image: #{e.message}. Using default image.")
        image_path = File.join('media', 'default.jpg')
      end

      image_path
    end

    def check_url_response(url)
      begin
        response = agent.head(url)
        response.code.to_i == 200
      rescue StandardError => e
        LoggerManager.log_error("URL check failed for #{url}: #{e.message}")
        false
      end
    end
  end
end
