require 'httparty'
require 'nokogiri'

class PageReader
  def initialize(url)
    @url = url
  end

  def fetch_data
    response = HTTParty.get(@url)
    Nokogiri::HTML(response.body)
  end

  def extract_headings
    doc = fetch_data
    doc.css('h1, h2, h3, h4').map(&:text)
  end
end