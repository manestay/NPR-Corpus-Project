# Copyright (c) 2015 Jesse Harris
# Using Beautiful Soup to collect NPR transcripts
# First version: June 20, 2013
# Python3 version: 2016

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""
Title: NPRdownload.py
Author: Jesse Harris (jharris@hummet.ucla.edu)
Version: May 21, 2016

OVERVIEW:
This program searches through a directory containing XML files formatted with Beautiful Soup. XML files should have the following tags: 
  <title> 		Title of the transcript.
  <urllink>		Address of transcript.
  <audlink>		Address of audio file.
  <transcript>	Text body of transcript stripped of html formatting.

USAGE: 
For use at command line. Allows user to search for a string or regular expression in a folder of XML transcript files. 
The basic usage consists of simply running the program at the command line:

>> python3 NPRdownload.py

Additional arguments may be specified in order: 
	path 			Path to directory with XML files. If not specified as argument, program will request input.
	filename		Name of CSV file to write data. If not specified as argument, program will request input.
	regex			Regular expression. If not specified as argument, program will request input.

An example with all arguments specified at command line:

>> python3 npr-search.py /Users/Username/Documents/XML Folder/ results.csv cowabunga .* dude

This will search through the directory '/Users/Username/Documents/XML Folder/' for the regular expression 'cowabunga .* dude' 
and write the results to results.csv.

COMMANDS FLAG:
You may also specify these variables in a separate text file. If the --command or -c flag is called, you will be prompted to supply the name
of the file where these variables are defined. For example: 

>> python3 npr-search.py -c

Each variable must be assigned to a string in a seaparate text file, like so:

path = '/Users/Username/Documents/XML Folder/'
filename = 'resutls.csv'
regexin = 'cowabunga .* dude'

VERBOSE FLAG:
You may also wish to see output as the program computes. In that case, use the --verbose or -v flag. This flag may be used with 
other arguments or the command flag. For example: 

>> python3 npr-search.py /Users/Username/Documents/XML Folder/ -v

>> python3 npr-search.py -c -v

"""



# TODO: Setup external directory of files to scrape in iterative sequence, writing a transcript file for each url

# http://www.npr.org/templates/transcript/transcript.php?storyId=

from bs4 import BeautifulSoup
import urllib
import cgi
import re
import glob
import csv
import argparse
from lxml import etree

# Function to strip tags from:
# http://stackoverflow.com/questions/1765848/remove-a-tag-using-beautifulsoup-but-keep-its-contents

def strip_tags(html, whitelist=[]):
    """
    Strip all HTML tags except for a list of whitelisted tags.
    """
    soup = BeautifulSoup(html)

    for tag in soup.findAll(True):
        if tag.name not in whitelist:
            tag.append(' ')
            tag.replaceWithChildren()

    result = unicode(soup)

    # Clean up any repeated spaces and spaces like this: '<a>test </a> '
    result = re.sub(' +', ' ', result)
    result = re.sub(r' (<[^>]*> )', r'\1', result)
    return result.strip()

# Open XML Directory
urlDir = []
# Open transcripts file
with open('transcripts2.txt', 'r') as g:
	for url in g.readlines():
		urlDir.append(url.replace('\n',''))


# Initialize num counter
num = 0


for page in urlDir:
	
	# Test for proper url
	req = urllib.request.urlopen(page)
	try: 
		url = urllib.request.urlopen(page, 'rb')

	# Read in url
		content = url.read()
		
		# Converty to BS object
		soup = BeautifulSoup(content)

		# Find date
		date = soup.findAll('span',{'class':'date'})
		date = strip_tags(str(date)).replace('[', '').replace(']', '')

		# Find link to original page
		ulink = soup.find(attrs={'rel':'canonical'})['href']

		# Getting link to audio
		url2 = urllib.urlopen(str(ulink))
		content = url.read()
		soup2 = BeautifulSoup(content)
		audlink = soup2.find(attrs={'class':'download'})['href']

		# Download audio
		"""
		Note: Automatic downloading will cause program to slow way down for large batches.
		May be best to simply print location of audio file - if so , just comment out next 4 lines.
		"""
	#	audfile = urllib2.urlopen(str(audlink))
	#	audoutput = open(writeDir+soup.title.getText().replace(' : NPR','')+'-audio.mp3', 'wb')
	#	audoutput.write(audfile.read())
	#	audoutput.close()

		# Build an XML tree structure
		root = etree.Element("document")

		# Title
		titletag = etree.SubElement(root, "title")	
		titletag.text = soup.title.getText().replace(' : NPR','')
		titletag.text = unicode(titletag.text, errors = 'ignore')


		# Date
		datetag = etree.SubElement(root,"date")
		datetag.text = date

		# URL link
		urllinktag = etree.SubElement(root, "urllink")
		urllinktag.text = str(ulink)

		audlinktag = etree.SubElement(root, "audlink")
		audlinktag.text = str(audlink)

		# Find main text without class and data-mod attributes 
		text = soup.findAll('p', {'class':None,'data-mod':None})

		# Escape from html with cgi
		text = cgi.escape(str(text))

		# Replace escaped strings with linebreaks, plus general cleanup
		# See: http://wiki.python.org/moin/EscapingHtml
		text = text.replace('&lt;', '\n').replace('/p&gt;,', '\n').replace('p&gt;', '').replace('[', '').replace('/]','')

		# Transcript
		transcripttag = etree.SubElement(root, "transcript")
		transcripttag.text = text

		# 
		tree = etree.ElementTree(root)
		etree.ElementTree(root).write(writeDir+titletag.text+'.xml', pretty_print = True)	
		print(titletag.text)
		print(page) # url
		print('---------------------------') # spacing
		num = num + 1
		
		
	except:
		print('Error: '+ str(req))
		print('---------------------------')
		continue

print('\n', '\n', 'Number of transcripts downloaded:', num)
		

	# Have to use lxml for pretty printing, but lxml is fussy
	# x = etree.parse('NPRfiles/'+soup.title.getText()+'.xml')
	# print etree.tostring(x, pretty_print = True)





