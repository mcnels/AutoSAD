# INSTALL RUBY ON WINDOWS
1. Install cygwin
    - Get appropriate version of cygwin for OS (32-bit or 64-bit)
    - Install default packages

2. Packages for cygwin:
  Verify following packages have been installed
    - Run cygwin setup
    - GnuPG, autoconf, automake, git, make, m4, curl, libcurl, openssl, openssh, patch, cygwin32-readline, sqlite3, bison, libtool, lib-readline, ruby-devel, ruby (interpreter), mingw64, mingw64-x86, requirements_cygwin_libs_install gcc gcc-core mingw64-x86_64-gcc-core zlib-devel openssl-devel libyaml-devel libffi-devel libreadline-devel

3. Install RVM
    ```
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    \curl -sSL https://get.rvm.io | bash -s stable --ruby
    source ~/.rvm/scripts/rvm
    ```

4. Set default environment (optional)

5. Install Ruby 2.5.0 using RVM
    ```
    rvm install 2.5.0
    ```

6. Install Gems
    
    ```
    gem install axlsx
    gem install canvas-api
    gem install json
    ```

7. Replace canvas-api by edited canvas-api
  
  Path: C:\cygwin64\home\user\.rvm\gems\ruby-2.5.0\gems\canvas-api-1.1.1

8. Edit sheet_pr.rb from axlsx to get tab_color option

    Note: replace 'ahudson2014' with home directory username and replace 'lkangas' with home directory username
  - Path (mac): /Users/lkangas/.rbenv/versions/2.5.0/lib/ruby/gems/2.5.0/gems/axlsx-2.0.1/lib/axlsx/workbook/worksheet
  - Path (Win): C:\cygwin64\home\ahudson2014/.rvm\gems\ruby-2.5.0\gems\axlsx-2.0.1\lib\axlsx\workbook\worksheet
  
  Link to modification: https://github.com/randym/axlsx/pull/396/files
  
9. Take care of curl and libcurl issues
    Ref: http://devadraco.blogspot.com/2016/08/running-wpscan-on-cygwin.html 
    Note: replace 'ahudson2014' with home directory username
    - Modify settings.rb located at C:\cygwin64\home\ahudson2014\.rvm\gems\ruby-2.5.0\gems\ethon-0.11.0\lib\ethon\curls\
    ```Original:
    6:    ffi_lib ['libcurl', 'libcurl.so.4']

    Modified:
    6:    ffi_lib ['libcurl', 'libcurl.so.4', 'libcurl-4.dll']
    ```
    
    - Modify functions.rb located atC:\cygwin\home\ahudson2014\.gem\ruby\gems\ethon-0.9.0\lib\ethon\curls\ ~line 56 to 60 (comment the if-statement branches out)
    ```Original:
    55:        if Curl.windows?
    56:            base.ffi_lib 'ws2_32'
    57:        else
    58:            base.ffi_lib ::FFI::Library::LIBC
    59:        end

    Modified:
    55:#        if Curl.windows?
    56:#            base.ffi_lib 'ws2_32'
    57:#        else
    58:            base.ffi_lib ::FFI::Library::LIBC
    59:#        end```

