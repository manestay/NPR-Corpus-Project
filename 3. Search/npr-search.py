# Copyright (c) 2015 Jesse Harris
#
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
Title: npr-search.py
Author: Jesse Harris (jharris@hummet.ucla.edu)
Version: December 31, 2015

OVERVIEW:
This program searches through a directory containing XML files formatted with Beautiful Soup. XML files should have the following tags: 
  <title> 		Title of the transcript.
  <urllink>		Address of transcript.
  <audlink>		Address of audio file.
  <transcript>	Text body of transcript stripped of html formatting.

USAGE: 
For use at command line. Allows user to search for a string or regular expression in a folder of XML transcript files. 
The basic usage consists of simply running the program at the command line:

>> python3 npr-search.py

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

# Modules to import
import nltk
from bs4 import BeautifulSoup
import urllib
import cgi
import re
import argparse
import sys
import glob
import csv
from nltk.tokenize import sent_tokenize

# NOTE: Program also requires lxml module for BeautifulSoup parser.

# Specify arguments for command line
parser = argparse.ArgumentParser()

# Specify arguments for parser
# Commands argument
parser.add_argument('--commands', '-c',  action="store_true",
help="Optional external command file. If present, it overrides other variables.")
# Path argument
parser.add_argument('path', nargs = "?", 
help="Path to directory with XML files. If not specified as argument, program will request input.")
# Filename argument
parser.add_argument('filename', nargs = "?", 
help="Name of CSV file to write data. If not specified as argument, program will request input.")
# Regex argument
parser.add_argument('regex', nargs = "?", 
help="Regular expression. If not specified as argument, program will request input.")
# Optional verbose argument
parser.add_argument('--verbose', '-v', action="store_true", help="Optional argument to print summary statistics upon termination.")
args = parser.parse_args()

if args.commands:
	try:
		commands = input('What is the name of the file containing the variables? >>')
		commands = open(str(commands),'r')
		#this reads the file as text
		whole_file = commands.read()
		#this executes the whole thing as code
		exec(whole_file)
	except: 
		print('Commands file not found, or unable to execute.')
		sys.exit(0)

else:
	
	# Tests to see if a path is provided
	if args.path:
		# If so, pass along argument
		path = args.path
	else:
		# Otherwise, request the path file.
		path = input("Please specify the folder path to the XML files, ending with /. >>")


	# print(path)

	# Tests to see if a filename is provided
	if args.filename:
		# If so, pass along argument
		filename = args.filename
	else:
		# Otherwise, request the csv file.
		filename = input("What is the name of the CSV file to output the data? >>")

	# Tests to see if a colname argument is provided. If not, requests the colname.
	if args.regex:
		regexin = args.regex
	else:
		regexin = input("What is the regular expression to use for the search? >>")


# Add XML to path
path = str(path) + '*.xml'

# Turn string into regex pattern
regex = re.compile(regexin)

# Open file for writing output, along with header CSV
output = open(str(filename), 'w', newline='')
header = ['Number', 'Title', 'Trans link', 'Audio link', 'Context', 'Paragraph', 'Continuation', 'Continuation2', 'Sentence']

# Open writer function for writing to file, and write in header
mywriter = csv.writer(output, dialect='excel')
mywriter.writerow(header)

# Print summary of search information in case of verbose flag 
if args.verbose:
	print('\nStarting search ......... ')
	print('Using directory as path to XML files:')
	print(path)
	print('Writing to:\t\t', filename)
	print('Regular expression:\t', regexin, '\n')

# Variables to count files processed and number of hits
fileind = 0
sentnum = 1

# Start main search by opening files in path
files = glob.glob(str(path))
# Iterate through files
for file in files:
	# Update file count
	fileind = fileind + 1
	# Opens each individual file with lxml parser
	soup = BeautifulSoup(open(file), "lxml")
	# Searches paragraphs in file
	for trans in soup.transcript:
		# Create array of paragraphs
		paragraphs = trans.split('\n\n')
		# Loop through paragraphs from transcripts
		for index, para in enumerate(paragraphs):
			# Text in initial paragraphs, create empty context paragraphs
			if index == 0 and index+2 < len(paragraphs):
				context = '' 
				follow = paragraphs[index+1]
				follow2 = paragraphs[index+2]
			# Text in non-initial paragraphs, but not the final paragraph
			elif index > 0 and index+2 < len(paragraphs):
				context = paragraphs[index-1]
				follow = paragraphs[index+1]
				follow2 = paragraphs[index+2]
			# 
			elif index > 0 and index+2 == len(paragraphs):
				context = paragraphs[index-1]
				follow = paragraphs[index+1]
				follow2 = ''
			# Final paragraphs, create empty following paragraph	
			else:
				context = paragraphs[index-1]
				follow = ''
				follow2 = ''
			# For search. Split on punctuation.
			for sent in sent_tokenize(para):
			# for sent in re.split(r' *[\.\?!][\'"\)\]]* *', para):
				# Remove excess whitespace
				sent = re.sub("\s\s+" , " ", sent)
				# Search for regex in sentence
				if re.findall(regex, sent):
					# Collect data into array and write to csv	
					data = [sentnum, soup.title.contents[0], soup.urllink.contents[0], soup.audlink.contents[0], context, para, follow, follow2, sent]
					mywriter.writerow(data)
					# Print out each hit, in case of verbose flag
					if args.verbose:
						print('------------------------------------')
						print(str(sentnum),'. ', soup.title.contents[0], '\n')	
						print(str(sent))
					# Update hit counter	
					sentnum = sentnum + 1
					
output.close()

# Prints summary of processing, in case of verbose flag
if args.verbose:
	print('------------------------------------')
	print('Number of files:', fileind)
	print('Number of hits:\t', str(sentnum - 1))


