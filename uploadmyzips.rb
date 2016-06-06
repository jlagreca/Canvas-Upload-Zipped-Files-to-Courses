require 'rubygems'
require 'json'
require 'typhoeus'
require 'bearcat'
require 'csv'

#------------------Global Variables----------------------#

$auth = 'TOKEN GOES HERE'
$domain = 'subdomain GOES HERE' #just need the subdomain - sooo {WHATEVER}.instructure.com
$file_location = '/Users/yourID/Desktop/myMigrations/' #Full path to the files/folders containing the zips. You need to have 1 folder per course. This is to keep you folder structure cleaner. 
$csv_file_name = 'content_mapping.csv'

#------------------ END Dont Change Anything Below This thing ----------------------#

$api_base_url = "https://#{$domain}.instructure.com/api/v1/"
$course_id, $course_csv_path, $module_id, $folder_id, $file_path, $course_name, $module_name = ''

def create_folder(name)
  # using create a folder API
  response1 = Typhoeus.post(
      $api_base_url + "courses/#{$course_id}/folders",
      headers: {:authorization => 'Bearer ' + $auth},
      body: {
          :name => name
      }
  )

  #parse JSON data to save in readable array
  folder = JSON.parse(response1.body)

  #assigns folder ID
  $folder_id = folder["id"]

  #for testing/logging purposes
  puts "Folder id: #{$folder_id}"
end

#--------------------------------------------------------#
#------------------perform file upload-------------------#
def import_content
  client = Bearcat::Client.new token: $auth,
                               prefix: "https://#{$domain}.instructure.com"

  params = {}
  params[:migration_type] = 'zip_file_importer'
  params[:pre_attachment] = {}
  params[:pre_attachment][:name] = File.basename($file_path) 

  params[:settings] = {}
  params[:settings][:folder_id] = $folder_id

  begin
    client.create_content_migration($course_id, $file_path, params)
    puts 'Content imported successfully'
  rescue => e
    puts e
    return
  end

end

#------------------perform import steps to create courses-------------------#
def perform_migration(file_name, folder_name)

  $file_path = file_name
  puts "Path to file is: #{$file_path}"
  # create folder
  create_folder(folder_name)

  #import the content
  import_content

end

#------------------Kickoff Script------------------------#
def migration_starter(drive_path)


  ignored_course_names = ['']
  CSV.foreach(drive_path + $csv_file_name, headers: true) do |row|
    $course_name = row['course_name']
    $course_id = "sis_course_id:#{row['course_id']}"
    Dir.foreach(drive_path + $course_name) do |file|
      next if file == '.' || file == '..' || file == '.DS_Store' #skip unnecessary file names and objects
      perform_migration("#{drive_path}#{$course_name}/#{file}", File.basename(file, '.zip'))
    end
  end
end


migration_starter($file_location)
