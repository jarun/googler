#!/usr/bin/env python3

import re
import shutil

import setuptools

shutil.copyfile('googler', 'googler.py')

with open('googler.py', encoding='utf-8') as fp:
    version = re.search(r'_VERSION_ = \'(.*?)\'', fp.read()).group(1)

setuptools.setup(
    name='googler',
    version=version,
    url='https://github.com/jarun/googler',
    license='GPLv3',
    author='Arun Prakash Jana',
    author_email='engineerarun@gmail.com',
    description='Google from the terminal',
    long_description='See https://github.com/jarun/googler#readme.',
    py_modules=['googler'],
    entry_points={
        'console_scripts': [
            'googler = googler:main',
        ],
    },
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Internet :: WWW/HTTP :: Indexing/Search',
        'Topic :: Utilities',
    ],
)
