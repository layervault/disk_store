require 'open-uri'

class DiskStore
  def initialize(path=nil)
    path ||= "."
    @root_path = File.expand_path path
  end

private

  # These methods were borrowed from ActiveSupport::Cache::FileStore
  def lock_file(file_name, &block) # :nodoc:
    if File.exist?(file_name)
      File.open(file_name, 'r+') do |f|
        begin
          f.flock File::LOCK_EX
          yield
        ensure
          f.flock File::LOCK_UN
        end
      end
    else
      yield
    end
  end

  # Translate a key into a file path.
  def key_file_path(key)
    fname = URI.encode_www_form_component(key)
    hash = Zlib.adler32(fname)
    hash, dir_1 = hash.divmod(0x1000)
    dir_2 = hash.modulo(0x1000)
    fname_paths = []

    # Make sure file name doesn't exceed file system limits.
    begin
      fname_paths << fname[0, FILENAME_MAX_SIZE]
      fname = fname[FILENAME_MAX_SIZE..-1]
    end until fname.blank?

    File.join(cache_path, DIR_FORMATTER % dir_1, DIR_FORMATTER % dir_2, *fname_paths)
  end

  # Translate a file path into a key.
  def file_path_key(path)
    fname = path[cache_path.to_s.size..-1].split(File::SEPARATOR, 4).last
    URI.decode_www_form_component(fname, Encoding::UTF_8)
  end

end
