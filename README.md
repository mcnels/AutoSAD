# AutoSAD

This tool eases the process of checking academic dishonesty in a Canvas course,
by pulling students' page views activity during the period of a test is being taken, for all Unit Tests and all students in said course.

# Requirements

- Ruby 2.5.0
- canvas-api gem from @whitmer (using modified canvas-api.rb file)
- axlsx gem (using modified sheet_pr.rb file)
- json gem
- date gem
- Admin access in Canvas
- Bearer token

# Preconditions
 - No unpublished unit tests in the quizzes section
 - File system for course should follow the following structure:
    * Course 50xx
        * Course Resources
            * Slides
                * *files*
            * Reading Assignment
                * *files*
            * SAFMEDS (optional)
                * *files*
            * Study Guide
                * *files*
        * ...
        * Instructor Materials
            * Instructor A
                * *files*
            * Instructor B
                * *files*
            * ...
            * Instructor Z
                * *files*

# Usage
 - RubyMine:
 
    * Go to Run -> Edit Configurations
    * Add [course_id] [check_start_time] [check_end_time]
    * Run
 - Command Line:
    
        chmod 755 program.rb    
        ./program.rb [course_id] [check_start_time] [check_end_time]
 
# Features

- Creates a workbook of student activity within a course
    - Creates a worksheet for each student in course
        - Displays page views activity (URL accessed, time accessed, test taken, IP used, Browser used, test start time, submission time) for all tests taken in check period
- Highlights files accessed during test period in yellow
- Highlights worksheet if any suspicious activity is present
    - Activity while taking unit test, review files or prior test
