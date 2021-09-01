#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import time
import urllib.request
from html.parser import HTMLParser
import argparse

flags = argparse.ArgumentParser(description='Print draft release notes.')
flags.add_argument('release',
                   metavar='release',
                   type=str,
                   help='name of the release branch')
flags.add_argument('--main',
                   default='main',
                   type=str,
                   help='name of the main branch')
args = flags.parse_args()


class TitleParser(HTMLParser):
    def __init__(self, titleSet):
        HTMLParser.__init__(self)
        self.titleSet = titleSet
        self.match = False

    def handle_starttag(self, tag, attributes):
        self.match = tag == 'title'

    def handle_data(self, data):
        if self.match:
            self.titleSet.add(data)
            self.match = False


stream = os.popen(f'git log --left-right --graph --cherry-pick --oneline {args.main}...{args.release}')
output = stream.read()

regexp = re.findall("Merge pull request #[0-9]+", output)
nums = set()
for num in regexp:
    nums.add(int(num.split("#")[1]))

sorted = []
for num in nums:
    sorted.append(num)

sorted.sort()

for num in nums:
    req = urllib.request.urlopen(f'https://github.com/crossplane/crossplane/pull/{num}')
    page = req.read().decode("utf8")
    parsedTitles = set()
    parser = TitleParser(parsedTitles)
    parser.feed(page)
    title = parsedTitles.pop().split(" · ")[0]
    words = title.split(" ")
    user = words[len(words)-1]
    titleWithUser = title.replace(user, f'@{user}')
    print(f'* #{num} - {titleWithUser}')
    req.close()
    time.sleep(1)
