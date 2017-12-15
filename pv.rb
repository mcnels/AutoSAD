#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'
#require 'time'

# Check for command line arguments
if (ARGV.length <= 0)
    puts "ERROR\n"
    puts "Usage:./page_views.rb canvas_course_id start_time"
    exit
end

# Take the course id and start_time from argument
course_id = ARGV[0]
# start time from command line
period_start = ARGV[1]

canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get all students
list_student = canvas.get("/api/v1/courses/" + course_id + "/users?", {'enrollment_type[]' => 'student'})
students = Array.new(list_student)

# Create workbook for student
p = Axlsx::Package.new

# Get the quizzes
quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

# Get all the quizzes
while quiz_list.more? do
    quiz_list.next_page!
end

quiz_list.each_with_index do |x, ran|
    if (x['title'].include? "Test A") || (x['title'].include? "Test B")
      next if (x['title'].include? "Bonus")
      quiz_id = x['id'].to_s

      # Get all submissions for each quiz
      submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions?", {'per_page' => '100'})
      while submissions_list.more? do
          submissions_list.next_page!
      end
      puts x['title'].to_s
      submissions = Array.new(submissions_list)
      sheetnames = Array.new
      submissions_list.each do |submission|
        user_id = submission['user_id'].to_s
        sheetname = ""
        currstudent = ""

        # Set start time for page views to 1 hour before test start time
        start_time1 = submission['started_at'].to_s
        start = DateTime.parse(start_time1)
        start_time = start - (1/24.0)

        # Set end time for page views to 1 hour after test submission time
        end_time1 = submission['finished_at'].to_s
        endt = DateTime.parse(end_time1)
        end_time = endt + (1/24.0)

        # Compare submission time and period_start
        startperiod = DateTime.parse(period_start)

        next if endt < startperiod
        # if endt >= startperiod
        #sheetnames = Array.new # is a new array created every submission or does it just add to it?
        # # determine name for the different sheets in the excel file
        students.each do |student|
          if user_id == student['id'].to_s
            sheetname = student['sortable_name']
            currstudent = student['sortable_name']
            # save all sheetnames in an array
            if sheetnames.include?(currstudent)
              next
            else
              sheetnames.push(sheetname)
            end
          end
        end
        puts sheetnames.length
        puts currstudent +" started"

        # Get page views activity for each student who submitted a quiz
        page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> start_time, 'end_time' => end_time, 'per_page' => '100'})

        # Keep loading the page views till we get them all!
        while page_views.more?  do
            page_views.next_page!
        end

        # Check for existing sheetnames
        #sheetnames.each_with_index do |name, i|
          #puts name
          #if (currstudent == name && i != 0) # change condition because sheetname will always be equal to name as it's just been assigned in the previous lines,
            # need to assign the tab names differently the first time around or check for that condition only from the second iteration onwards

          #if ran == 0 # handle first iteration (temp solution)
          #   puts "no conflict"
          #   # create headers to specify which quiz is being reported
          #   sheet.add_row [x['title']], :types => [:string]
          #
          #   # create headers
          #   sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip","start/stop","unit test","file name","IP Switch","Browser Switch"]
          #
          #   page_views.each do |x|
          #     # if (x['created_at'] == submission['started_at']) || (x['created_at'] == submission['end_at'])
          #     #   sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], "Unit 1 Test A"], :types => [nil, nil, :string, :string, :string, :string, :string]
          #     # else
          #       sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']], :types => [nil, nil, :string, :string, :string, :string]
          #     # end
          #   end
          #
          #   # add new line after each quiz results
          #   sheet.add_row [""]
          #
          #   # rename sheet
          #
          #   sheet.name = currstudent
          #   puts currstudent+" done and created new sheet"
          # else

          if sheetnames.include?(currstudent) # need to skip first iteration of this
            puts "conflict"
            # Add data in existing sheet
            p.workbook.add_worksheet(name: sheetname, tab_selected: true) do |sheet|
              sheet.sheet_view.tab_selected = true
              # create headers to specify which quiz is being reported
              sheet.add_row [x['title']], :types => [:string]

              # create headers
              sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip","start/stop","unit test","file name","IP Switch","Browser Switch"]

              page_views.each do |x|
                # if (x['created_at'] == submission['started_at']) || (x['created_at'] == submission['end_at'])
                #   sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], "Unit 1 Test A"], :types => [nil, nil, :string, :string, :string, :string, :string]
                # else
                  sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']], :types => [nil, nil, :string, :string, :string, :string]
                # end
              end

              # add new line after each quiz results
              sheet.add_row [""]
              # determine name for the different sheets in the excel file
              # students.each do |student|
              #   if curr == student['id'].to_s
              #     sheetname = student['sortable_name']
              #     # save all sheetnames in an array
              #     sheetnames.push(sheetname)
              #   end
              # end
              #sheet.name = name
              puts currstudent+" done and added in existing sheet"
            end
          else
            #Create new worksheet for student
            p.workbook.add_worksheet do |sheet|
              puts "no conflict"
              # create headers to specify which quiz is being reported
              sheet.add_row [x['title']], :types => [:string]

              # create headers
              sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip","start/stop","unit test","file name","IP Switch","Browser Switch"]

              page_views.each do |x|
                # if (x['created_at'] == submission['started_at']) || (x['created_at'] == submission['end_at'])
                #   sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], "Unit 1 Test A"], :types => [nil, nil, :string, :string, :string, :string, :string]
                # else
                  sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']], :types => [nil, nil, :string, :string, :string, :string]
                # end
              end

              # add new line after each quiz results
              sheet.add_row [""]

              # rename sheet

              sheet.name = currstudent
              puts currstudent+" done and created new sheet"
            end
            puts "ready for next student"
          end
        #end for temp solution
          # Create the Excel document
          p.serialize('ultimate1.xlsx')
        #end
      end
      puts "ready for next test"
    else
      puts "not a unit test"
    end
end
puts "all done"
