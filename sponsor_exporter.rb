require 'open-uri'
require 'nokogiri'
require 'pry'

class SponsorList
  def self.fetch
    document.css(".sponsorList li").each do |html|
      sponsor_name = html["id"]
      label = 
      binding.pry
    end
  end

  private

  def self.document
    Nokogiri::HTML(open("http://codemash.org/sponsors"))
  end
end

class Sponsor
  def self.from_html(html)
    image_tag = html.css("> img").first
    image = image_tag ? image_tag["src"] : nil

    name = html["id"]

    description = "#{html.text.strip.gsub(/\s+/, " ")
  end
end
