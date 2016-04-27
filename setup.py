from setuptools import setup
import sys

prefix = '/usr/local'
for arg in sys.argv:
    if '--prefix' in arg:
        prefix = arg[arg.find('=') + 1:]

setup(name='googler',
      description='Google from the command-line',
      long_description=open('README.md').read(),
      version='2.3',
      author='Arun Prakash Jana',
      author_email='engineerarun@gmail.com',
      url='https://github.com/jarun/googler',
      data_files=[
          (prefix + "/share/man/man1", ["googler.1"]),
          (prefix + "/share/doc/googler", ["LICENSE"]),
          (prefix + "/share/fish/vendor_completions.d",
           ["auto-completion/fish/googler.fish"]),
          ("/etc/bash_completion.d",
              ["auto-completion/bash/googler-completion.bash"]),
          (prefix + "/share/zsh/site-functions",
              ["auto-completion/zsh/_googler"])
      ],
      scripts=['googler'],
      classifiers=['Intended Audience :: End Users/Desktop',
                   'Programming Language :: Python :: 2',
                   'Programming Language :: Python :: 3'],
      license='GPL3')
