#!/usr/bin/env ruby
# Requirements
require 'canvas-api'
require 'json'
require 'spreadsheet'



canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")
# count = 0
# Creating Workbook
Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new


    #action_logs = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions/" + id + "/events")
    action_logs = canvas.get("/api/v1/courses/513752/quizzes/803249/submissions/8235907/events?", {'per_page' => '100'})
    # page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> '2017-10-13T12:00:00-04:00', 'end_time' => '2017-10-20T23:59:00-04:00', 'per_page' => '100'})

    # json = action_logs["quiz_submission_events"].to_a
    # Keep loading the page views till we get them all!
    while action_logs.more?  do
        action_logs.next_page!
    end

    # Create worksheet for student
    sheet = book.create_worksheet

    #logs = Array.new(action_logs['quiz_submission_events'])
    # create headers
    sheet.row(0).push "event_type","created_at"

    # logs.each_with_index do |log, i|
    #   sheet.row(i+1).push log['event_type'], log['created_at']
    # end
    action_logs.each_with_index do |log, i|
      sheet.row(i+1).push log['event_type'], log['created_at']
    end

    # rename sheet
    # sheet.name = sheet_name
    sheet.name = "shireen"

  book.write 'newfreezer.xlsx'
