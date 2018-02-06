#!/usr/bin/env ruby
students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
quizzes  = ["1A", "1B", "2A", "2B", "3A", "3B", "4A", "4B", "5A", "5B"]

dnest = Array.new(11){Array.new(11)}
count = 0
i = 1
students.each do |stu|
  j = 1
  quizzes.each do |q|
      dnest[i][0] = stu
      dnest[0][j] = q
      dnest[i][j] = {:stime => stu, :sub => q}
      # dnest[i][j] = {:stime => "start", :sub => "subtime"}
      j = j + 1
      count = count + 1
  end
  i = i + 1
end
# Print nested array
dnest.each { |x|
  puts x.join(" ")
}