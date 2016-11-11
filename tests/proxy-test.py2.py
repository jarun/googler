#!/usr/bin/env python
import os
import urlparse
import httplib
import base64

proxy = os.environ['https_proxy']
host = 'www.google.com'
port = 443

url = urlparse.urlparse(proxy)
conn = httplib.HTTPSConnection(url.hostname, url.port)
headers = {}

if url.username and url.password:
  auth = '%s:%s' % (url.username, url.password)
  headers['Proxy-Authorization'] = 'Basic ' + base64.b64encode(auth)

conn.set_tunnel(host, port, headers)
conn.request("GET", "/")
response = conn.getresponse()
print response.status, response.reason
output = response.read()
