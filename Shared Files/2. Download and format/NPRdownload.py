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
Version: June 29, 2016

OVERVIEW:
This program creates a directory containing XML files formatted with Beautiful Soup. XML files are formatted with the following tags: 
  <title> 		Title of the transcript.
  <urllink>		Address of transcript.
  <audlink>		Address of audio file.
  <transcript>	Text body of transcript stripped of html formatting.

USAGE: 
The basic usage consists of simply running the program at the command line:

>> python3 NPRdownload.py

An dditional links argument may be specified: 
	links 			Name of file containing links to transcripts. If not specified as argument, program will request input.

An example with all arguments specified at command line:

>> python3 NPRdownload.py transcripts.txt

This will search through links stored the transcripts.txt file listed in the current directory, and create an XML directory of formatted transcripts.

AUDIO FLAG:
You may also wish to download audio files of the radio program as the program computes. In that case, use the --audio or -v a. For example: 

>> python3 NPRdownload.py transcripts.txt -a


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


# Specify arguments for command line
parser = argparse.ArgumentParser()

# Transcript argument
parser.add_argument('links', nargs = "?", 
help="Name of transcript file with links. If not specified as argument, program will request input.")

parser.add_argument('--audio', '-a',  action="store_true",
help="Optional flag to download audio files, in addition to transcripts.")

# Optional verbose argument
# parser.add_argument('--verbose', '-v', action="store_true", help="Optional argument to print summary statistics upon termination.")

args = parser.parse_args()


if args.commands:	
	# Tests to see if a path is provided
	if args.links:
		# If so, pass along argument
		links = args.links
	else:
		# Otherwise, request the path file.
		links = input("Please specify the file with the links to download. >>")



# Open XML Directory
urlDir = []
# Open transcripts file
# with open('transcripts2.txt', 'r') as g:
with open(str(links), 'r') as g:
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

		# Download audio files if audio flag is up
	
		if args.audio:
			audfile = urllib2.urlopen(str(audlink))
			audoutput = open(writeDir+soup.title.getText().replace(' : NPR','')+'-audio.mp3', 'wb')
			audoutput.write(audfile.read())
			audoutput.close()

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





