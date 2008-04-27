FILE_EXTENSIONS = /\.(JPG|GIF|TIF|TIFF|JPEG|DOC|PPT|XLS|PNG)$/i
EMAIL = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
class String

  def permalink
    self.gsub(/'/,'').gsub(/(\W|_)+/,'-').sub(/-$/,'').sub(/^-/,'').downcase
  end
  
  def remove_file_suffix
    self.sub(FILE_EXTENSIONS,'')
  end
  
  def is_email?
    self.match(EMAIL)
  end
  
  def is_integer?
    self =~ /\A-?\d+\Z/
  end

  def with_slash
   self =~ /\/\Z/ ? self : self + "/"
  end
  
  def without_slash
    self.sub(/\/\Z/,'')
  end    
  
end