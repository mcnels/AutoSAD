#!/usr/bin/env ruby
# Requirements
require 'canvas-api'
require 'json'
require 'spreadsheet'

course_id = ARGV[0]
#quiz_id = ARGV[1]
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Creating Workbook
Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new

  quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

  while quiz_list.more? do
      quiz_list.next_page!
  end

  #Create worksheet for student
  sheet = book.create_worksheet

  index = 0
  sheet.row(0).push "id", "title"

  quiz_list.each do |x|
    if (x['title'].include? "Test A") || (x['title'].include? "Test B")
      next if (x['title'].include? "Bonus")
      sheet.row(index+1).push x['id'], x['title']
      index = index+1
    else
      next
    end
  end

# Create the Excel document
book.write 'quizlistfilt.xls'
