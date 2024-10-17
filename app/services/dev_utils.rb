class DevUtils

  def self.create_temp_file_for_content content
    file = Tempfile.new('temp')
    file.write content
    file.close
    yield file
    file.unlink
  end

end