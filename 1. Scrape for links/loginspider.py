

import scrapy

from scrapy.spiders import Spider
from scrapy.selector import Selector
from scrapy.http import Request
from scrapy.utils.response import open_in_browser

"""
This program is intended to save you ~5 seconds a day
This program logs into SONA systems and prints the number timeslots that have credits granted and the number of timeslots awaiting action
Or, use this program as a shortcut to open the timeslots page in a browser window without having to log in yourself!

Replace:
<USERNAME> = your username
<PASSWORD> = yourpassword
"""

class LoginSpider(Spider):
    name = 'SONA'
    start_urls = ['https://ucla.sona-systems.com/default.aspx']

    def parse(self, response):
        hxs = Selector(response)
        if hxs.css("div.form-signin"):
            
#****************ENTER YOUR USERNAME AND PASSWORD BELOW****************
            return [scrapy.FormRequest.from_response(response,
                    formdata={'ctl00$ContentPlaceHolder1$userid': '<USERNAME>', 'ctl00$ContentPlaceHolder1$pw': '<PASSWORD>'},
                    callback=self.after_login)]

    def after_login(self, response):
    # check login succeed before going on
        if "Login failed" in response.body:
            print "Login Failed. Try again"
            return
    # We've successfully authenticated, go to timeslots modification page.
        else:
            return Request(url="https://ucla.sona-systems.com/exp_info_usage.aspx?experiment_id=479",
               callback=self.parse_timeslots)

    def parse_timeslots(self, response):
        hxs = Selector(response)
        
 #Uncomment below to open the timeslots modification page in a browser!
        #open_in_browser(response)
        credits_granted = hxs.xpath("//span[@id='ctl00_ContentPlaceHolder1_RepeaterExpInfo_ctl00_lblTotalCreditGranted']/text()").extract()[0].encode("utf-8")
        awaiting_action = hxs.xpath("//span[@id='ctl00_ContentPlaceHolder1_RepeaterExpInfo_ctl00_lblAwaitingAction']/text()").extract()[0].encode("utf-8")
        print "%s credits have been granted!" %credits_granted
        print "%s timeslots awaiting action." %awaiting_action
