module HermesImageMetadataImport
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
end