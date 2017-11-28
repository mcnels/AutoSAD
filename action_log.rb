#!/usr/bin/env ruby
# Requirements
require 'canvas-api'
require 'json'
require 'spreadsheet'
require 'axlsx'
# Check for command line arguments
if (ARGV.length <= 0)
    puts "ERROR\n"
    puts "Usage:./page_views.rb canvas_course_id canvas_quiz_id"
    exit
end

# Take the student id and quiz id from argument
# Could potentially take start_time and end_time at command line as ARGV[1] and ARGV[2] then pass it as argument to the GET request
course_id = ARGV[0]
quiz_id = ARGV[1]
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")
count = 0
# Creating Workbook
Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new

# Get list of students in a course
 list_student = canvas.get("/api/v1/courses/" + course_id + "/students")

submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions")
submissions = Array.new(submissions_list['quiz_submissions'])

user_id = ""
# Generate action logs for each student in course
# list_student.each do |y| # not necessary
  # next if y['id'].to_s == user_id #go to next student
  #submissions_list = canvas.get("/api/v1/courses/513752/quizzes/803249/submissions?", {'per_page' => '100'})
  # Define user ID and username, so they can later be used to name the worksheets
  user_id = y['id'].to_s
  sheet_name = y['login_id']

  submissions.each_with_index do |submission, j|
    id = submission['id'].to_s
    puts id
    # Get action logs for each student for a Unit Test
    action_logs = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions/" + id + "/events")
    # action_logs = canvas.get("/api/v1/courses/513752/quizzes/803249/submissions/8235907/events")
    # page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> '2017-10-13T12:00:00-04:00', 'end_time' => '2017-10-20T23:59:00-04:00', 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    # while page_views.more?  do
    #     page_views.next_page!
    # end

    # Create worksheet for student
    sheet = book.create_worksheet

    logs = Array.new(action_logs['quiz_submission_events'])
    # create headers
    sheet.row(0).push "event_type","created_at"

    logs.each_with_index do |log, i|
      sheet.row(i+1).push log['event_type'], log['created_at']
    end

    # rename sheet
    sheet.name = sheet_name
    #sheet.name = "shireen"
    # Console message

    count = count + 1
    puts  count # + "done"
    puts sheet_name+"done"
    book.write 'logstest3333.xls'
  end

# end

# Create the Excel document
