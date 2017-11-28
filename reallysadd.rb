#!/usr/bin/env ruby
# Requirements
require 'canvas-api'
require 'json'
require 'spreadsheet'
require 'axlsx'
#require 'date'

# Check for command line arguments
if (ARGV.length <= 0)
    puts "ERROR\n"
    puts "Usage:./page_views.rb canvas_course_id start_time"
    exit
end

# Take the course id and start_time from argument
course_id = ARGV[0]
start_time = ARGV[1]

canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Creating Workbook
Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new

# Get the quizzes
quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

# Get all the quizzes
while quiz_list.more? do
    quiz_list.next_page!
end

#Create worksheet for student
sheet = book.create_worksheet

# create headers
sheet.row(0).push "url","controller","created_at","user_agent","participated","remote_ip","start/stop"#,"unit test","file name","IP Switch","Browser Switch"

quiz_list.each do |x|
  # Compare quiz_list['title'] to "Test A" || "Test B"
  if (x['title'].include? "Test A") || (x['title'].include? "Test B")
    next if (x['title'].include? "Bonus")
    quiz_id = x['id']

    # Get all submissions for each quiz
    submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions?", {'per_page' => '100'})
    while submissions_list.more? do
        submissions_list.next_page!
    end

    submissions_list.each do |submission|
      user_id = submission['user_id']
      #end_time = DateTime.now.strftime("%Y-%m-%dT%H:%M:00-05:00")

      # Get page views activity for each student who submitted a quiz
      page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> start_time, 'end_time' => '2017-11-17T23:59:00-05:00', 'per_page' => '100'})

      # Keep loading the page views till we get them all!
      while page_views.more?  do
          page_views.next_page!
      end

      page_views.each_with_index do |x, i|
        sheet.row(i+1).push x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], submission['started_at']
      end

  # if there's an existing sheet for the current student, then append data to that sheet
  # else create new sheet

      # rename sheet
      sheet.name = user_id
      # Create the Excel document
      book.write 'sadder.xls'
    end
  end
end
