#!/usr/bin/env python3
#
# Copyright (C) 2008 Henri Hakkinen
#
# Copyright (C) 2015-2016 Arun Prakash Jana <engineerarun@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from setuptools import find_packages, setup

# Get the version from googler/version.py without importing the package
exec(compile(open('googler/version.py').read(),
'googler/version.py', 'exec'))

setup(
    name='googler',
    version=__version__,
    author='Arun Prakash Jana',
    author_email='engineerarun@gmail.com',
    description='''Google Search, Google Site Search, Google News from the
                   terminal''',
    entry_points={
        'console_scripts': [
            'googler=googler:main'
        ],
    },
    license='GNU General Public License v3 (GPLv3)',
    keywords='CLI Googler search terminal',
    url='https://github.com/jarun/googler',
    packages=find_packages(),
    classifiers=[
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Topic :: Internet',
        'Topic :: Internet :: WWW/HTTP',
        'Topic :: Internet :: WWW/HTTP :: Indexing/Search',
    ],
)
