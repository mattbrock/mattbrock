#!/usr/local/bin/python
# -*- coding: utf-8 -*-

import re
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-f", "--file", dest="filename", metavar="FILE", 
  help="read reminders from ICS FILE")
parser.add_option("-c", "--include-completed", action="store_true", 
  dest="include_completed", help="include completed tasks")
(options, args) = parser.parse_args()

if not options.filename:
  print "No filename specified; -h for help"
  exit(1)

with open(options.filename) as file:
  ics_export = file.readlines()
file.close

todos = []
for ics_line in ics_export:
  if "STATUS:COMPLETED" in ics_line and options.include_completed is None:
    exclude = True
  elif "STATUS:" in ics_line:
    exclude = False
  if "SUMMARY:" in ics_line and exclude is False:
    bits = re.split(":", ics_line)
    todos.append(bits[1].rstrip())

todos.sort(key=lambda y: y.lower())
for todo in todos:
  print "•", todo
