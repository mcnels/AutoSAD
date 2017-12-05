#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'
require 'time'

# Check for command line arguments
if (ARGV.length <= 0)
    puts "ERROR\n"
    puts "Usage:./page_views.rb canvas_course_id start_time"
    exit
end

# Take the course id and start_time from argument
course_id = ARGV[0]
# start time will be determined by started_at time

canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Create workbook for student
p = Axlsx::Package.new

# Get all submissions for each quiz
submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/802669/submissions?", {'per_page' => '100'})
while submissions_list.more? do
    submissions_list.next_page!
end

submissions_list.each do |submission|
  user_id = submission['user_id'].to_s
  puts user_id
  
  # Set start time for page views to 1 hour before test start time
  start_time1 = submission['started_at'].to_s
  start = DateTime.parse(start_time1)
  start_time = start - (1/24.0)
  # Set end time for page views to 1 hour after test submission time
  end_time1 = submission['finished_at'].to_s
  endt = DateTime.parse(end_time1)
  end_time = endt + (1/24.0)

  # Get page views activity for each student who submitted a quiz
  page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> start_time, 'end_time' => end_time, 'per_page' => '100'})

  # Keep loading the page views till we get them all!
  while page_views.more?  do
      page_views.next_page!
  end

  #Create worksheet for student
  p.workbook.add_worksheet do |sheet|
    # create headers
    sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip","start/stop"]#,"unit test","file name","IP Switch","Browser Switch"

    page_views.each do |x|
      # if (x['created_at'] == submission['started_at']) || (x['created_at'] == submission['end_at'])
      #   sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], "Unit 1 Test A"], :types => [nil, nil, :string, :string, :string, :string, :string]
      # else
        sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']], :types => [nil, nil, :string, :string, :string, :string]
      # end
    end

    # rename sheet
    puts user_id+" done"
    sheet.name = user_id
  end

  # Create the Excel document
  p.serialize('penultimate.xlsx')
end
