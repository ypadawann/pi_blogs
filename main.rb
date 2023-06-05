require 'open-uri'
require 'nokogiri'
require 'fileutils'

BLOG_ROOT_URL = ""
BLOGS_DIR = File.expand_path("./blogs")
LOG_FILE = File.expand_path("./log.log")


def output_log(log)
  log = log.to_s
  p log
  File.open(LOG_FILE, "a") do |f|
    time = Time.now.to_s
    f.puts ("["+time.to_s+"] " + log)
  end
end

def get_doc(url)
  charset = nil
  html = URI.open(url) do |f|
    charset = f.charset
    f.read
  end
  doc = Nokogiri::HTML.parse(html, nil, charset)
  return doc
end

def get_article(url)
  doc = get_doc(url)
  return doc.xpath('//div[@class="blog_detail__main"]').text
end

def save(dirpath, url)
  doc = get_doc(url)

  main_node = doc.xpath('//div[@class="blog_detail__main"]')

  File.open(dirpath + "/text.txt", "w") do |f|
    f.puts(main_node.text)
  end
  File.open(dirpath+"/html.txt", "w") do |f|
    f.puts(main_node.inner_html)
  end

  main_node.xpath(".//img[@src]").each do |node|
    image_src = node.attr("src")
    output_log(image_src)
    next if !image_src.start_with?("/images")
    image_url = BLOG_ROOT_URL + image_src
    image_name = File.basename(image_url)
    output_log(image_url)
    URI.open(image_url) do |image|
      File.open(dirpath+"/"+image_name, "w") do |f|
        f.write(image.read)
      end
    end

  end
end

def get_blog_dirpath(auther, date, title)
  auther_dir = BLOGS_DIR + "/" + auther + "/" + date + "_" + title
  FileUtils.mkdir_p(auther_dir)
  filename = date + "_" + title + ".txt"
  filepath = auther_dir + "/" + filename
end

def get_articles(url_path)
  exist_flag = false
  url = BLOG_ROOT_URL + url_path
  output_log("Blog list page: " + url)

  doc = get_doc(url)
  doc.xpath('//ul[contains(@class,"blog-list")]/li').each do |node|
    title_node = node.xpath('.//*[@class="blog-list__title"]')
    title = title_node.xpath('.//*[@class="title"]').text
    auther = title_node.xpath('.//*[@class="name"]').text
    date = title_node.xpath('.//*[@class="date"]').text
    article_url = node.xpath(".//a[@href]").attr("href").value

      output_log(auther)
      output_log date + " " + title
      output_log article_url

    dirpath = BLOGS_DIR + "/" + auther + "/" + date + "_" + title
    if Dir.exist?(dirpath)
      output_log "this article is exist"
      #exist_flag = true
      #break
    end

    FileUtils.mkdir_p(dirpath)
    text = ""
    save(dirpath, article_url)
  end

  if exist_flag
    output_log "finish"
    return
  end

  next_page_node = doc.xpath('//p[@class="pager_next"]/a')
  if next_page_node.empty?
    output_log "finish: this page is last"
    return
  end

  next_page_link = next_page_node.attr("href").value
  get_articles(next_page_link)
end

def test_save
  url = "" 
  dirpath = "./test/auther/date_title"
  FileUtils.mkdir_p(dirpath)
  save(dirpath, url)

end

begin
  top_url = ''
  get_articles(top_url)
  output_log "complete"
rescue=> e
  output_log e.backtrace
  output_log e.message
end

#test_save
