require 'csv'
require 'google/apis/civicinfo_v2'

puts "Event Manager Initialized"

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = File.read("../civic_info.key").strip

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0...5]
end

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
begin
  legislators = civic_info.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: ['legislatorUpperBody', 'legislatorLowerBody']
  )
  legislators = legislators.officials
rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end
  puts "#{name}: #{zipcode}"
end
