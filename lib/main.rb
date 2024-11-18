require_relative './tasks/pagereader'

url = 'https://www.amazon.com/'
pageReader = PageReader.new(url)

puts "Heads on the page:"
pageReader.extract_headings.each do |heading|
  puts heading
end