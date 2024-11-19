require 'mechanize'
require 'yaml'
require 'fileutils'
require 'securerandom'
require 'uri'

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
      # Books to Scrape specific selector for product links
      product_selector = '.product_pod h3 a'
      links = page.search(product_selector).map { |link| link['href'] }
      LoggerManager.log_processed_file("Extracted #{links.size} product links")
      links.map { |link| URI.join(page.uri.to_s, link).to_s } # Ensure full URLs for links
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
        category = extract_product_category(product_page)

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
      # Extract name of the product from the Books to Scrape page
      product.search('h1').text.strip
    end

    def extract_product_price(product)
      # Books to Scrape specific selector for price
      price = product.search('.price_color').text.strip
      price.empty? ? 'N/A' : price
    end

    def extract_product_description(product)
      # Books to Scrape doesn't have a specific description field, so use the product's information
      'No description available'
    end

    def extract_product_image(product)
      # Books to Scrape uses relative URLs for images, so join with the base URL
      image = product.search('.item img').first['src']
      LoggerManager.log_processed_file("Extracted image URL: #{image}")
      URI.join('https://books.toscrape.com', image).to_s
    end

    def extract_product_category(product)
      # Since the category isn't directly on the product page, you can use a default category or scrape from the site structure
      config['selectors']['category'] || 'Books'
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
