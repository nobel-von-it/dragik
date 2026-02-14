require 'nokogiri'
require 'open-uri'
require 'uri'

def fetch_vavilon(url)
  raw_html = URI.open(url, "User-Agent" => "Mozilla/5.0").read
  Nokogiri::HTML(raw_html, nil, "koi8-r")
end

def parse_first_collection(toc_url)
  doc_toc = fetch_vavilon(toc_url)

  toc_map = {}
  doc_toc.css('td ul p a').each do |link|
    anchor = link['href'].split('#').last
    title = link.text.strip
    toc_map[anchor] = title
  end

  first_link = doc_toc.at_css('td ul p a')['href'].split('#').first
  content_url = URI.join(toc_url, first_link).to_s

  puts "Загружаем тексты из: #{content_url}"
  doc_content = fetch_vavilon(content_url)

  results = []

  anchors = doc_content.css('a[name]')

  anchors.each_with_index do |anchor, index|
    name = anchor['name']
    next unless toc_map.key?(name)

    poem_title = toc_map[name]
    poem_body = []

    current_node = anchor.next_element
    while current_node && current_node.name != 'a' && !current_node['name']
      text = current_node.text.strip
      poem_body << text unless text.empty?

      current_node = current_node.next_element
    end

    results << {
      id: name,
      title: poem_title,
      body: poem_body.join("\n\n")
    }
  end

  results
end

def get_vavilon_links(root_url)
  doc = fetch_vavilon(root_url)

  links = doc.css('a.alink').map do |link|
    {
      title: link.text.strip.gsub(/[:]$/, ''),
      url:   URI.join(root_url, link['href']).to_s
    }
  end

  links
end

url = "https://www.vavilon.ru/texts/dragomot0.html"
begin
  works = get_vavilon_links(url)
  puts "\nНайдено произведений: #{works.size}\n"
  puts "-" * 40

  collection = parse_first_collection(works[0][:url])
  collection.each do |poem|
    puts "=== СТИХ №#{poem[:id]}: #{poem[:title]} ==="
    puts poem[:body][0..200] + "..." # Выведем начало для проверки
    puts "\n"
  end
  # works.each do |work|
  #   puts "Название: #{work[:title]}"
  #   puts "Ссылка:   #{work[:url]}"
  #   puts "-" * 40
  # end
rescue => e
  puts "Ошибка: #{e.message}"
end
