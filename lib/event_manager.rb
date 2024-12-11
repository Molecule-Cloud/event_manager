require 'erb'
require 'csv'
require 'google/apis/civicinfo_v2'

puts 'Event Manager Initialized'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0...5]
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
  legislators = legislators_by_zipcode(zipcode) # Fetches legislators by ZIP code
  form_letter = erb_template.result(binding) # Generates the form letter using ERB template
  save_thank_you_letter(id, form_letter) # Saves the form letter
end
