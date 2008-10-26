module Hermes
  module Image
    module Metadata
      module Import
        def self.included(base)
          base.extend(Hermes::Image::Metadata::Import::ClassMethods)
        end

        require 'RMagick'
        require 'mini_exiftool'
      
        # Mapping the data from mini_exiftool to Image model attributes
        MAP = {
            :AFPoint => :focus_point,
            :ApertureValue => :aperture,
            :CaptionAbstract => :caption,
            :Category => :content_rating,
            :City => :city,
            :ContinuousDrive => :drive_mode,
            :CopyrightNotice => :copyright_notice,
            :Country => :country,
            :Creator => :photographer,
            "DateTimeOriginal" => :taken_at,
            :Description => :description,
            :ImageHeight => :height,
            :ImageWidth => :width,
            :ExposureCompensation => :exposure_compensation,
            :ExposureProgram => :exposure_mode,
            :FileName => :filename,
            :Flash => :flash,
            :FocalLength => :focal_length,
            :FocusMode => :focus_mode,
            :GPSAltitude => :altitude,
            :GPSLatitude => :latitude,
            :GPSLongitude => :longitude,
            :IntellectualGenre => :genre,
            :ISO => :iso,
            :Lens => :lens,
            :Location => :location,
            :Make => :camera_make,
            :MeteringMode => :metering_mode,
            :Model => :camera_model,
            :OwnerName => :owner,
            "Province-State" => :state,
            :SerialNumber => :camera_serial_number,
            :SceneCaptureType => :scene,
            :ShutterSpeedValue => :shutter,
            :Subject => :tag_list,
            :SubjectCode => :subjects,
            :Title => :title,
            :WhiteBalance => :white_balance
        }

        DRIVE_MODE = [
          "Single", 
          "Continuous", 
          "Movie", 
          "Continuous, Speed Priority",
          "Continuous, Low",
          "Continuous, High"
        ]

        FOCUS_MODE = [
          "One-shot AF", 
          "AI Servo AF", 
          "AI Focus AF",
          "Manual Focus", 
          "Single",
          "Continuous",
          "Manual Focus"
        ]

        THUMBNAIL_SUFFIX      = "-thumb"
        DISPLAY_SUFFIX        = "-display"
        SLIDE_SUFFIX          = "-slide"
        Location_pattern      = /(\d{1,3}) deg (\d{1,2})\' (\d{1,2}\.\d{1,2})\"/
        
        # Instance methods
        def caption
          asset.description
        end

        def caption=(c)
          asset.description = c
        end

        def import_metadata
          logger.info "Image Import: Import metadata for '#{self.full_path_name}'"
          image_exif = MiniExiftool.new(self.full_path_name)
          @geo_set_counter = 0
          MAP.each do |k, v|
            if k == :GPSLatitude
              set_latitude(image_exif)
            elsif k == :GPSLongitude
              set_longitude(image_exif)
            else
              send("#{v.to_s}=", image_exif[k.to_s]) if image_exif[k.to_s]
            end
          end
          self.created_by = User.find_by_email(image_exif["CreatorContactInfoCiEmailWork"]) || User.current_user
          if @geo_set_counter == 2 # Which means both lat and lng were set
            self.geocode_method = Asset::GEO_GPS
            self.geocode_accuracy = Google_geocode_accuracy.length - 1
          end
          true
        end

        def import_tags
          logger.info "Image Import Tags"
          image_exif = MiniExiftool.new(self.full_path_name)
          self.tag_list = image_exif["Subject"]
        end

        def flash=(f)
          unless f && f == "No flash function"
            super(f)
          end
        end

        def aperture=(v)
          if v
            a = v.is_a?(Float) ? v.to_s.sub("\.0",'') : v
            a = 'f/' + a if !a.match(/^f\//)
            write_attribute(:aperture, a.gsub(/ +/,''))
          end
        end

        def shutter=(v)
          if v
            a = v.to_s.match(/s$/) ? v.to_s : v.to_s + "s"
            write_attribute(:shutter, a)
          end
        end

        def lens=(v)
          if v
            l = v.gsub(/\.0/,'').gsub(/ +/,'')
            l = l + "mm" if !l.match(/mm$/)
            write_attribute(:lens, l)
          end
        end

        def focal_length=(v)
          if v.is_a?(String)
            l = v.gsub(/\.0/,'').gsub(/ +/,'')
            l = l + "mm" if !l.match(/mm$/)
            write_attribute(:focal_length, l)
          end
        end

        def taken_at=(v)
          ta = DateTime.strptime(v,'%Y:%m:%d %H:%M:%S%Z') if v.is_a?(String)
          ta = v if (v.is_a?(DateTime) || v.is_a?(Time))
          write_attribute(:taken_at, ta) if ta
        end

        def drive_mode=(v)
          dm = DRIVE_MODE[v] if v.is_a?(Fixnum)
          dm = v if v.is_a?(String)
          write_attribute(:drive_mode, dm) if dm
        end

        def exposure_mode=(v)
          if v =~ /Aperture-priority/
            write_attribute(:exposure_mode, "Av")
          elsif v =~ /Shutter/
            write_attribute(:exposure_mode, "Tv")
          elsif v =~ /Manual/
            write_attribute(:exposure_mode, "M")
          elsif v =~ /Program/
            write_attribute(:exposure_mode, "P")
          else
            write_attribute(:exposure_mode, v)
          end if v
        end

        def focus_mode=(v)
          fm = FOCUS_MODE[v] if v.is_a?(Fixnum)
          fm = v if v.is_a?(String)
          write_attribute(:drive_mode, fm) if fm
        end
      

        def set_latitude(image_exif)
          if image_exif["GPSLatitude"] && (lat = image_exif["GPSLatitude"].match(Location_pattern))
            lat_decimal = $1.to_f + ($2.to_f / 60.0) + ($3.to_f / 3600.0)
            lat_decimal = lat_decimal * -1 if image_exif["GPSLatitudeRef"] == "South"
            send("latitude=", lat_decimal)
            @geo_set_counter += 1
          end
        end

        def set_longitude(image_exif)
          if image_exif["GPSLongitude"] && (lon = image_exif["GPSLongitude"].match(Location_pattern))
            lon_decimal = $1.to_f + ($2.to_f / 60.0) + ($3.to_f / 3600.0)
            lon_decimal = lon_decimal * -1 if image_exif["GPSLongitudeRef"] == "West"
            send("longitude=", lon_decimal)
            @geo_set_counter += 1
          end
        end  
      
        # Derive thumbnail file name from the image.
        def thumbnail_filename
          return File.basename(self.filename, ".*") + THUMBNAIL_SUFFIX + File.extname(self.filename)
        end

         # Derive slide file name from the image.
        def slide_filename
          return File.basename(self.filename, ".*") + SLIDE_SUFFIX + File.extname(self.filename)
        end

         # Derive thumbnail file name from the image.
        def display_filename
          return File.basename(self.filename, ".*") + DISPLAY_SUFFIX + File.extname(self.filename)
        end

        def full_path_name
          return self.catalog.directory + self.folder + self.filename
        end

        def thumbnail_path_name
          return self.catalog.directory + self.folder + self.thumbnail_filename
        end

        def slide_path_name
          return self.catalog.directory + self.folder + self.slide_filename
        end

        def display_path_name
          return self.catalog.directory + self.folder + self.display_filename
        end
        
        module ClassMethods
          def make_image_files(filename, destination_folder)
            RAILS_DEFAULT_LOGGER.info "Making catalog image files from #{filename}"
            destination = Catalog.default.directory + destination_folder.with_slash
            FileUtils.mkdir(destination) unless File.exists?(destination)
            file_root = File.basename(filename, '.*')
            thumbnail_file = destination + file_root + thumbnail_suffix + ".jpg"
            slide_file = destination + file_root + slide_suffix + ".jpg"
            display_file = destination + file_root + display_suffix + ".jpg"
            full_file = destination + file_root + ".jpg"

            image = Magick::ImageList.new(filename)

            # Thumbnail
            new_image = image.resize_to_fit(Catalog.default.max_thumbnail_dimension, Catalog.default.max_thumbnail_dimension )
            new_image.write(thumbnail_file)

            # Slide
            new_image = image.resize_to_fit(Catalog.default.max_slide_dimension, Catalog.default.max_slide_dimension )
            new_image.write(slide_file)

            # Display
            new_image = image.resize_to_fit(Catalog.default.max_display_dimension, Catalog.default.max_display_dimension )
            new_image.write(display_file)

            # Full
            new_image = image.resize_to_fit(Catalog.default.max_image_dimension, Catalog.default.max_image_dimension )
            new_image.write(full_file)

            image.destroy!
            new_image.destroy!
            full_file
          end

          def import_metadata
            all.each do |i|
              i.import_metadata
              i.save!
            end
            true
          end

          def import_tags
            all.each do |i|
              i.import_tags
              i.save!
            end
            true
          end       

          def thumbnail_suffix
            THUMBNAIL_SUFFIX
          end

          def slide_suffix
            SLIDE_SUFFIX
          end

          def display_suffix
            DISPLAY_SUFFIX
          end
        end
      end
    end
  end
end