
import scrapy
from urlparse import urljoin
from scrapy.spiders import CrawlSpider, Rule
from scrapy.selector import Selector
from scrapy.http import Request


base = "http://www.npr.org/templates/transcript/transcript.php?storyId="
DOMAIN = 'www.npr.org'
URL = 'http://%s' % DOMAIN
trans_set = set()               #Set of all transcript links to handle duplicates




class TranscriptSpider(CrawlSpider):
    name = 'npr'
    allowed_domains = [DOMAIN]
    start_urls = [URL]
        

    def parse(self, response):
    #First checks if response URL is a transcript link
    #If not, scrapes all URLs from response URL
    
      if response.url.startswith(base):
        if response.url not in trans_set:
            trans_set.add(response.url)
            print current_url
        
        
        
        else:
            for href in response.css("a::attr('href')"):                              #Get all URLS on this page (~~This line was the big fix!~~)
                current_url = href.extract().encode("utf-8")                          #Extract link, convert from unicode to string
                current_url = response.urljoin(current_url)                           #Append extension to npr.org
                
                if current_url.startswith(base):                                      #Check if transcript link
                    if current_url not in trans_set:
                        trans_set.add(current_url)
                        print current_url
            
                else:
                    yield scrapy.Request(current_url, callback=self.parse)
