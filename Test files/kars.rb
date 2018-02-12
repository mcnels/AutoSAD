#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

# Check for command line arguments
if ARGV.length <= 0
  puts "ERROR\n"
  puts "Usage:./page_views.rb canvas_course_id start_time"
  exit
end

# Take the course id from argument
course_id = ARGV[0]
# start and end time for check period
period_start = ARGV[1]
end_time = DateTime.now

canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get all students
list_student = canvas.get("/api/v1/courses/" + course_id + "/students")
students = Array.new(list_student)

# Create workbook for student
p = Axlsx::Package.new

# Get the quizzes
quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

# Get all the quizzes
while quiz_list.more? do
  quiz_list.next_page!
end

#stuRec = Array.new(Array.new)
stuRec = Array.new((students.size)+1){Array.new(19)}
conflict = ""
i = 1
students.each do |student|
  next if student['id'].to_s == conflict #go to next student
  next if student['id'].to_s == '1856840'
  conflict = student['id'].to_s
  j = 1
  # Get all unit tests for course
  quiz_list.each do |q|
    if (q['title'].include? "Test A") || (q['title'].include? "Test B")
      next if (q['title'].include? "Bonus") || (q['title'].include? "Proctored")
      quiz_id = q['id'].to_s

      # Get all submissions for each quiz
      submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions?", {'per_page' => '100'})
      while submissions_list.more? do
        submissions_list.next_page!
      end

      # Check if submissions array is empty or not, continue only if not empty *no longer relevant*
      tookTest = "N"
      stuRec[i][0] = student['id']
      stuRec[0][j] = q['title']
      # Add submissions info to array of records for student
      submissions_list.each do |submission|

        if student['id'].to_s == submission['user_id'].to_s #&& (submission['started_at'] != "null" || submission['finished_at'] != "null")
          # each student has a hash record (name, stime, sbmtime, quiztitle)
          # stuRec[i][0] = student['id']
          # stuRec[0][j] = q['title']
          stuRec[i][j] = {:stime => submission['started_at'], :sbmtime => submission['finished_at'], :unit => q['title']}
          tookTest = "Y"
          break if tookTest == "Y"
          #j = j + 1
          #stuRec << {:namen => submission['user_id'], :stime => submission['started_at'], :sbmtime => submission['finished_at'], :quizTitle => q['title']}
        # elsif student['id'].to_s != submission['user_id'].to_s
        #   else
        #   stuRec[i][j] = {:stime => "No info", :sbmtime => "No info"}
         # j = j + 1
        end
        # j = j + 1
      end
      if tookTest == "N"
        stuRec[i][j] = {:stime => "missing", :sbmtime => "missing", :unit => q['title']}
      end
      j = j + 1
      puts "submission info recorded for "+ q['title'].to_s + " for " + student['sortable_name']
    else
      puts "not a unit test"
    end
  end
  i = i + 1
end

stuRec.each { |x|
  puts x.join(" ")
}

# sort stuRec by row name
# Iterate over student records array to print page views activity
k = 0
stuRec[1..-1].each do |stu|
  user_id = stu[k].to_s
  puts user_id
  next if user_id.to_s == conflict #go to next student
  conflict = user_id.to_s
  currstudent = ""
  # Name worksheets
  students.each do |student|
    if user_id.to_s == student['id'].to_s
      currstudent = student['sortable_name'] # might need to change this to username
    end
  end
  puts currstudent+" started"
  p.workbook.add_worksheet do |sheet|

    # stu[1..-1].each do |rec|
        #next if stu == nil
        # user_id = rec.to_s
        # puts user_id
        # next if user_id.to_s == conflict #go to next student
        # conflict = user_id.to_s
        # currstudent = ""
        # # Name worksheets
        # students.each do |student|
        #   if user_id.to_s == student['id'].to_s
        #     currstudent = student['sortable_name'] # might need to change this to username
        #   end
        # end

        # Get page views activity for each student who submitted a quiz
        page_views = canvas.get("/api/v1/users/" + user_id.to_s + "/page_views?", {'start_time'=> period_start, 'end_time' => end_time, 'per_page' => '100'})

        # Keep loading the page views till we get them all!
        while page_views.more?  do
          page_views.next_page!
        end

        # puts currstudent+" started
        sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip", "unit test", "start/stop","file name","IP Switch","Browser Switch"]
        stu[1..-1].each do |rec|
        #Create worksheet for student
        # p.workbook.add_worksheet do |sheet|
          # create headers
          # sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip", "unit test", "start/stop","file name","IP Switch","Browser Switch"]

          if rec[:stime] == "missing" || rec[:sbmtime] == "missing"
            sheet.add_row ["missing", "missing", "missing", "missing", "missing", "missing", rec[:unit].to_s], :types => [:string, :string, :string, :string, :string, :string, :string]
          else
            page_views.each do |x|
              # puts rec[:stime]
              # puts DateTime.parse(x['created_at'])
              # newt = DateTime.parse(rec[:stime].to_s) - (1/24.0)
              # puts newt
              # puts DateTime.parse(rec[:stime])-(1/24.0)
              # next if DateTime.parse(x['created_at']) <= (DateTime.parse(rec[:stime])-(1/24.0)) || DateTime.parse(x['created_at']) >= (DateTime.parse(rec[:sbmtime])+(1/24.0))
              # if rec[:stime] == "missing" || rec[:sbmtime] == "missing"
              #   sheet.add_row ["missing", "missing", "missing", "missing", "missing", "missing", rec[:unit].to_s], :types => [:string, :string, :string, :string, :string, :string, :string]
              # else
                next if DateTime.parse(x['created_at']) <= (DateTime.parse(rec[:stime])-(1/24.0)) || DateTime.parse(x['created_at']) >= (DateTime.parse(rec[:sbmtime])+(1/24.0))
                sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], rec[:unit].to_s], :types => [nil, nil, :string, :string, :string, :string, :string]
            end

            #next if DateTime.parse(x['created_at']) >= (DateTime.parse(rec[:sbmtime])+(1/24.0))
            # next if (DateTime.parse(x['created_at']) <= DateTime.parse(stuRec[:stime])-(1/24.0)) || (DateTime.parse(x['created_at']) >= DateTime.parse(stuRec[:sbmtime])+(1/24.0))
            # sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stuRec['quizTitle']], :types => [nil, nil, :string, :string, :string, :string, :string]
            # sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stu[0][k+1]], :types => [nil, nil, :string, :string, :string, :string, :string]
          end
          # add new line after each quiz results
          sheet.add_row [""]
    end
    # rename sheet and add given name to sheetnames array
    sheet.name = currstudent
    # end
    puts currstudent+" done"

    k = k + 1
      # Create the Excel document
      p.serialize('/Users/mcnels/Documents/CE/Canvas/5011test1a6.xlsx')
  end
end
puts "all done"
