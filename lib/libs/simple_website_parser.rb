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
      url = config['web_scraping']['start_page']

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
      # Використовуємо новий селектор для отримання посилань на продукти
      product_selector = '.product-card a'
      links = page.search(product_selector).map { |link| link['href'] }
      LoggerManager.log_processed_file("Extracted #{links.size} product links")
      links.map { |link| URI.join(page.uri.to_s, link).to_s } # Переконуємось, що посилання повні
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
        image_url = extract_product_image(product_page)
    
        # For saving images, get the category dynamically (e.g., from config or the page itself)
        category = 'dresses' # This can be adjusted
    
        image_path = save_product_image(image_url, category)
    
        # Initialize the item with the parsed data
        item = Item.new(
          title: name,        # Correctly assign title
          price: price,       # Correctly assign price
          image_url: image_path # Correctly assign image_path (not the URL directly)
        )
    
        @item_collection << item
        LoggerManager.log_processed_file("Parsed product: #{name}, Price: #{price}, Image Path: #{image_path}")
    
      rescue StandardError => e
        LoggerManager.log_error("Failed to parse product page at #{product_link}: #{e.message}")
      end
    end

    def extract_product_name(product)
      # Використовуємо новий селектор з конфігурації
      product.search(config['web_scraping']['product_name_selector']).text.strip
    end

    def extract_product_price(product)
      # Використовуємо новий селектор для ціни з конфігурації
      price = product.search(config['web_scraping']['product_price_selector']).text.strip
      price.empty? ? 'N/A' : price
    end

    def extract_product_image(product)
      # Використовуємо новий селектор для зображень з конфігурації
      image = product.search(config['web_scraping']['product_image_selector']).first['src']
      LoggerManager.log_processed_file("Extracted image URL: #{image}")
      URI.join('https://fabrikacin.com.ua/zhinochi-sukni', image).to_s
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
