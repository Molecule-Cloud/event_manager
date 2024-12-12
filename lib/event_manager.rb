require 'erb'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'time'
puts 'Event Manager Initialized'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0...5]
end

def clean_phone_number(number)
  # Remove non-digit characters
  number = number.gsub(/\D/, '')
  if number.length < 10
    'Error! Please enter a valid 10-digit number'
  elsif number.length == 10
    number.to_s
  elsif number.length == 11 && number[0] == '1'
    number.to_s[1..]
  elsif number.length > 11
    'Error! Enter a valid 10-digit number'
  else
    'Error! Invalid number'
  end
end

def count_registrations_per_hour(contents)
  registration_hours = Hash.new(0) # Initialize a hash to count registrations per hour
  contents.each do |row|
    registration_date_time = Time.strptime(row[:regdate], '%m/%d/%Y %k:%')
    hour = registration_date_time.hour
    registration_hours[hour] += 1 # Increment the count for this hour
  end
  registration_hours
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('../civic_info.key').strip
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def count_registration_per_hour(contents)
  registration_hours = Hash.new(0)
  contents.each do |row|
    registration_date_time = Time.strptime(row[:regdate], '%m/%d/%Y %k:%M')
    hour = registration_date_time.hour
    registration_hours[hour] += 1
  end
  registration_hours
end

def count_registrations_per_day(contents)
  registration_days = Hash.new(0) # Initialize a hash to count registrations per day
  contents.each do |row|
    registration_date_time = Time.strptime(row[:regdate], '%m/%d/%Y %k:%M') # Parse the registration date and time
    day_of_week = registration_date_time.strftime('%A') # Get the day of the week (e.g., 'Monday')
    registration_days[day_of_week] += 1 # Increment the count for this day
  end
  registration_days
end

# Method to save the thank-you letter
def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output') # Creates the output directory if it doesn't exist
  file_name = "output/thanks_#{id}.html" # Creates the file name
  File.open(file_name, 'w') do |file|
    file.puts form_letter # Writes the form letter to the file
  end
end

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter # Creates a new ERB template

contents = CSV.open('../event_attendees.csv',
                    headers: true, # Treats the first row as headers
                    header_converters: :symbol) # Converts headers to symbols

contents.each do |row|
  id = row[0] # Extracts the ID
  name = row[:first_name] # Extracts the first name
  zipcode = clean_zipcode(row[:zipcode]) # Cleans the ZIP code
  phonenumbers = clean_phone_number(row[:homephone])
  registration_hours = count_registration_per_hour(contents)
  registration_hours.each do |hour, count|
    puts "#{hour}: #{count} registrations"
  end
  registration_days = count_registrations_per_day(contents) # Print out the registration counts per day of the week
  registration_days.each do |day, count|
    puts "#{day}: #{count} registrations"
  end
  legislators = legislators_by_zipcode(zipcode) # Fetches legislators by ZIP code
  form_letter = erb_template.result(binding) # Generates the form letter using ERB template
  save_thank_you_letter(id, form_letter) # Saves the form letter
end
