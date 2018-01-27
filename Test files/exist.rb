#!/usr/bin/env ruby
require 'rubyXL'

# Check for command line arguments
# if (ARGV.length <= 0)
#     puts "ERROR\n"
#     puts "Usage:./page_views.rb canvas_course_id start_time"
#     exit
# end

# Add data in existing sheet
workbook = RubyXL::Parser.parse("newpvtest.xlsx")
existing_sheet = workbook["lfisgus2017"]
puts "ok"
# add_cell(row, column)
existing_sheet.add_cell(20, 1,'something else')
puts "ok"
workbook.write("newpvtest.xlsx")
