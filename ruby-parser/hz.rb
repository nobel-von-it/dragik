require 'nokogiri'
require 'open-uri'
require 'uri'
require 'json'
require 'openssl'

# --- КОНФИГУРАЦИЯ ---
AUTHOR_URL = "http://www.vavilon.ru/texts/dragomot0.html" # Используем http
OUTPUT_FILE = "dragomoshchenko.json"

def fetch_vavilon(url, limit = 3)
  # Принудительно переводим в http для стабильности на старом сервере
  url = url.gsub("https://", "http://")

  begin
    # Настройки для обхода ошибок SSL на старых серверах
    options = {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      :read_timeout => 15,
      :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE # Отключаем проверку сертификата
    }

    raw_html = URI.open(url, options).read
    Nokogiri::HTML(raw_html, nil, "koi8-r")
  rescue => e
    if limit > 0
      puts "!!! Ошибка на #{url} (#{e.message}). Пробую еще раз... (осталось #{limit})"
      sleep(2)
      return fetch_vavilon(url, limit - 1)
    else
      puts "!!! Не удалось загрузить #{url} после всех попыток."
      nil
    end
  end
end

# Улучшенная очистка текста
def clean_text(nodes)
  content = []
  nodes.each do |node|
    # Сохраняем структуру стихов
    node.search('br').each { |br| br.replace("\n") }
    txt = node.text.strip

    next if txt.empty?

    # Фильтруем только явный технический мусор
    next if txt =~ /ISBN|ББК|УДК|Copyright|©|Вернуться на|Вернуться к/i

    # Если это разделитель или короткая строка - ОСТАВЛЯЕМ (это может быть стих)
    # Удаляем только если это явно служебная строка "СПб.: Издат, 2000"
    if txt.size < 50 && txt =~ /[0-9]{4}|Издат\.центр|вып\.|стр\./
       next
    end

    content << txt
  end
  content.join("\n\n")
end

# ТИП 1: Якоря
def parse_anchor_style(toc_url, links)
  target_hrefs = links.map { |l| l['href'].split('#').first }.reject { |h| h =~ /glazova|barzakh|yampolsky/ }
  most_common_page = target_hrefs.group_by(&:itself).values.max_by(&:size)&.first
  return [] unless most_common_page

  content_url = URI.join(toc_url, most_common_page).to_s
  doc_content = fetch_vavilon(content_url)
  return [] unless doc_content

  toc_map = {}
  links.each { |l| toc_map[l['href'].split('#').last] = l.text.strip }

  results = []
  doc_content.css('a[name]').each do |anchor|
    name = anchor['name']
    next unless toc_map.key?(name)

    body_nodes = []
    curr = anchor.next_element
    while curr && !(curr.name == 'a' && curr['name'])
      body_nodes << curr
      curr = curr.next_element
    end

    text = clean_text(body_nodes)
    # Если всё еще пусто, берем сырой текст нод
    text = body_nodes.map(&:text).join("\n").strip if text.empty?

    results << { "item_title" => toc_map[name], "text" => text }
  end
  results
end

# ТИП 2: Главы
def parse_chapter_style(toc_url, links)
  results = []
  author_links = links.reject { |l| l['href'] =~ /glazova|barzakh|yampolsky/i }

  author_links.each do |link|
    chapter_url = URI.join(toc_url, link['href']).to_s
    doc = fetch_vavilon(chapter_url)
    next unless doc

    results << {
      "item_title" => link.text.strip,
      "text" => clean_text(doc.css('p, ul, table, font'))
    }
  end
  results
end

# ТИП 3: Роман
def parse_sequential_style(start_url)
  full_content = []
  current_url = start_url
  visited = []

  while current_url && !visited.include?(current_url)
    visited << current_url
    doc = fetch_vavilon(current_url)
    break unless doc

    full_content << clean_text(doc.css('p, ul, table, font'))

    next_link = doc.css('a').find { |l| l.text =~ /Продолжение|Окончание/i }
    if next_link && next_link['href'] =~ /dragom/i
       current_url = URI.join(current_url, next_link['href']).to_s
    else
       current_url = nil
    end
  end
  [{ "item_title" => "Полный текст", "text" => full_content.join("\n\n") }]
end

def get_collection_data(url)
  doc = fetch_vavilon(url)
  return [] unless doc

  all_links = doc.css('td ul p a, td p a').reject { |l| l.text.size < 3 }

  if all_links.any? { |l| l['href']&.include?('#') }
    parse_anchor_style(url, all_links)
  elsif doc.css('a').any? { |l| l.text =~ /Продолжение/i && l['href'] =~ /dragom/ }
    parse_sequential_style(url)
  elsif !all_links.empty? && all_links.any? { |l| l['href'] =~ /dragom/ }
    parse_chapter_style(url, all_links)
  else
    # Одиночная страница
    [{ "item_title" => "Текст", "text" => clean_text(doc.css('p, ul, table, font')) }]
  end
end

# --- ЗАПУСК ---

final_data = {
  "author" => "Аркадий Драгомощенко",
  "collected_at" => Time.now.to_s,
  "books" => []
}

main_doc = fetch_vavilon(AUTHOR_URL)
exit if main_doc.nil?

collections = main_doc.css('a.alink').map do |l|
  { title: l.text.strip.gsub(/[:]$/, ''), url: URI.join(AUTHOR_URL, l['href']).to_s }
end

puts "--- Парсинг всех произведений (#{collections.size} разделов) ---"

collections.each_with_index do |coll, index|
  puts "[#{index+1}/#{collections.size}] Сборник: #{coll[:title]}..."

  items = get_collection_data(coll[:url])

  final_data["books"] << {
    "book_title" => coll[:title],
    "book_url" => coll[:url],
    "content" => items
  }
  sleep(1)
end

File.write(OUTPUT_FILE, JSON.pretty_generate(final_data))
puts "--- Готово! Проверьте #{OUTPUT_FILE} ---"
