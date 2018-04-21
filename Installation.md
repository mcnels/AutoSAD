# INSTALL RUBY ON WINDOWS
1. Install cygwin
    - Get appropriate version of cygwin for OS (32-bit or 64-bit)
    - Install default packages

2. Packages for cygwin:
  Verify following packages have been installed
    - Run cygwin setup
    - GnuPG, autoconf, automake, git, make, m4, curl, libcurl, openssl, openssh, patch, cygwin32-readline, sqlite3, bison, libtool, lib-readline

2. Install RVM
    - rvm install 2.5.0 (using git and curl)

3. Set default environment

4. Install Ruby 2.5.0 using RVM
    - rvm install 2.5.0

5. Install Gems
    - axlsx
    - canvas-api
    - json

6. Replace canvas-api by edited canvas-api
  Path: C/cygwin/user/.rvm

7. Edit sheet_pr.rb from axlsx to get tab_color option
  Path (mac): /Users/lkangas/.rbenv/versions/2.5.0/lib/ruby/gems/2.5.0/gems/axlsx-2.0.1/lib/axlsx/workbook/worksheet
  // Add screenshot here
