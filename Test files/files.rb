#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")
course_id = "494716"

list_files = canvas.get("/api/v1/courses/" + course_id + "/folders/3965530")
#files = Array.new(list_files['files_url'])

puts list_files