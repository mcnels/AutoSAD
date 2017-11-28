#!/usr/bin/env ruby
# Requirements
require 'canvas-api'
require 'json'
require 'spreadsheet'


canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Creating Workbook
Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new

  submissions_list = canvas.get("/api/v1/courses/513752/quizzes/803249/submissions?", {'per_page' => '100'})

  # Keep loading the submissions till we get them all!
  while submissions_list.more? do
      submissions_list.next_page!
  end

  # Create worksheet for student
  sheet = book.create_worksheet

  # create headers
  sheet.row(0).push "id", "user_id","started_at","finished_at"

  submissions_list.each_with_index do |submission, i|
    sheet.row(i+1).push submission['id'], submission['user_id'], submission['started_at'], submission['finished_at']
    puts  "done"
  end

  #sheet.name = sheet_name
  sheet.name = "5011"

book.write 'subm4.xls'
