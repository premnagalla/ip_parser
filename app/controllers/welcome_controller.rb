class WelcomeController < ApplicationController

  def index
  end

  def parse_csv
    # raise params.to_yaml
    require 'csv'
    input_file = params[:input_file]

    # To write to a file
    output_file_path = "#{Rails.root}/tmp/ips_output_data.csv"

    # Delete previous generated file, if there is any
    File.delete(output_file_path) if File.file?(output_file_path)

    # Open a new file and write the required data fetched
    File.open(output_file_path, "w") do |csv|
      header_attributes = ["Given country","IP Address","City","Region","Country",'Address', 'Valid / Invalid']
      header_string = header_attributes.join(',')
      csv << header_string
      csv << "\n"

      # Parse & write to file
      CSV.parse(input_file.read, :headers => false) do|row|
        begin
          # row.headers.each{ |cell| row[cell] = row[cell].to_s.strip }
          given_country = row[3]
          given_ip = row[4]
          result = Geocoder.search(given_ip)

          if result[0].present? && result[0].data.present?
            ip_latitude = result[0].data['latitude']
            ip_longitude = result[0].data['longitude']

            # To get full address with latitude & longitude
            full_address_search = Geocoder.search([ip_latitude, ip_longitude].join(','))
            ip_address = nil
            if full_address_search[0].present? && full_address_search[0].data.present?
              ip_address = full_address_search[0].data['formatted_address']
            end

            op_data_string = "#{given_country},#{given_ip},#{result[0].data['city']},#{result[0].data['region_name']},#{result[0].data['country_name']},\"#{ip_address}\",Valid IP"
            csv << op_data_string
            csv << "\n"      
          else
            op_data_string = "#{given_country},#{given_ip},,,,,InValid IP"
            csv << op_data_string
            csv << "\n"      
          end
        rescue Exception => e
          p "failed for record: #{row}"
          p "Exception ---------: #{e.message}"
          # op_data_string = "#{given_country},#{given_ip},,,,InValid IP"
          # csv << op_data_string
          # csv << "\n"                
        end
      end
      send_file output_file_path, :type=>"application/csv", :x_sendfile=>true      
    end

    respond_to do|format|
      format.html{}
      format.js{}    
    end
  end

end