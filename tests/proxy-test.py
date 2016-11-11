#!/usr/bin/env python3

import os
import argparse
import atexit
import collections
import functools
import gzip
import html.entities
import html.parser
import http.client
from http.client import HTTPSConnection
import socket
import ssl
import logging
import os
import platform
import signal
import sys
import textwrap
import urllib.parse
import base64

proxy = os.environ['https_proxy']
host = 'www.google.com'
port = 443
url = urllib.parse.urlparse(proxy)

conn = HTTPSConnection(url.hostname, url.port)
headers = {}

if url.username and url.password:
  auth = '%s:%s' % (url.username, url.password)
  headers['Proxy-Authorization'] = 'Basic ' + base64.b64encode(auth.encode('ascii')).decode()

conn.set_tunnel(host, port, headers)
conn.request("GET", "/")
response = conn.getresponse()
print(response.status, response.reason)
output = response.read()
print(output)
