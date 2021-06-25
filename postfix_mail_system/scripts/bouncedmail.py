#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os
import re
import email
from hashlib import md5
import time
from time import gmtime, strftime
import datetime
import mimetypes
from urllib2 import urlopen, URLError
import mysql.connector

# Read in the email
msg = sys.stdin.read()
emsg = email.message_from_string(msg)

date = emsg['date']
if date is None:
   sys.exit(0)

# Get message_id from message
for line in msg.split('\n'):
   if "X-message-id" in line:
       bits = line.split()
       try:
           message_id = bits[1]
       except IndexError:
           pass

try:
   message_id
except NameError:
   message_id = None

# Try to grab message body as intelligently as possible
body = ""
# For multipart emails
if emsg.is_multipart():
  for part in emsg.walk():
       ctype = part.get_content_type()
       cdispo = str(part.get('Content-Disposition'))
       # skip any text/plain (txt) attachments
       if ctype == 'text/plain' and 'attachment' not in cdispo:
           body = part.get_payload(decode=True)
           break
# Non-multipart emails i.e. plain text, no attachments
else:
   body = emsg.get_payload(decode=True)

# Set up database connection (modify this as per requirements)
cnx = mysql.connector.connect(user='user', password='password',
                             host='dbhost.company.com',
                             database='email')
cursor = cnx.cursor()

# Insert message_id and body into database
# (modify this as per requirements)
insert = ("INSERT INTO bounce "
         "(message_uid, content) "
         "VALUES (%s, %s)")
data = (message_id, body)
if message_id is not None:
   try:
       cursor.execute(insert, data)
   except Exception:
       pass

# Complete and close database connection
cnx.commit()
cursor.close()
cnx.close()
