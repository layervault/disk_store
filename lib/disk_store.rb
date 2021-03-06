require 'open-uri'
require 'disk_store/reaper'

class DiskStore
  class MD5DidNotMatch < StandardError; end

  DIR_FORMATTER = "%03X"
  FILENAME_MAX_SIZE = 228 # max filename size on file system is 255, minus room for timestamp and random characters appended by Tempfile (used by atomic write)
  EXCLUDED_DIRS = ['.', '..'].freeze

  attr_reader :reaper

  def initialize(path=nil, opts = {})
    path ||= "."
    @root_path = File.expand_path path
    @options = opts
    @reaper = Reaper.spawn_for(@root_path, @options)
  end

  def read(key, md5 = nil)
    fd = File.open(key_file_path(key), 'rb')
    validate_file!(key_file_path(key), md5) if !md5.nil?
    fd
  rescue MD5DidNotMatch => e
    delete(key)
    raise e
  end

  def write(key, io, md5 = nil)
    file_path = key_file_path(key)
    ensure_cache_path(File.dirname(file_path))

    fd = File.open(file_path, 'wb') do |f|
      begin
        f.flock File::LOCK_EX
        IO::copy_stream(io, f)
      ensure
        # We need to make sure that any data written makes it to the disk.
        # http://stackoverflow.com/questions/6701103/understanding-ruby-and-os-i-o-buffering
        f.fsync
        f.flock File::LOCK_UN
      end
    end

    validate_file!(file_path, md5) if !md5.nil?
    fd
  rescue MD5DidNotMatch => e
    delete(key)
    raise e
  end

  def exist?(key)
    File.exist?(key_file_path(key))
  end

  def delete(key)
    file_path = key_file_path(key)
    if exist?(key)
      begin
        File.delete(file_path)
      rescue Error::ENOENT
        # Weirdness can happen with concurrency
      end
      
      delete_empty_directories(File.dirname(file_path))
    end
    true
  end

  def fetch(key, md5 = nil)
    if block_given?
      if exist?(key)
        read(key, md5)
      else
        io = yield
        write(key, io, md5)
        read(key)
      end
    else
      read(key, md5)
    end
  end

private

  # These methods were borrowed mostly from ActiveSupport::Cache::FileStore

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
    end until fname.nil? || fname == ""

    File.join(@root_path, DIR_FORMATTER % dir_1, DIR_FORMATTER % dir_2, *fname_paths)
  end

  def validate_file!(file_path, md5)
    real_md5 = Digest::MD5.file(file_path).hexdigest
    if md5 != real_md5
      raise MD5DidNotMatch.new("MD5 mismatch. Expected: #{md5}, Actual: #{real_md5}")
    end
  end

  # Make sure a file path's directories exist.
  def ensure_cache_path(path)
    FileUtils.makedirs(path) unless File.exist?(path)
  end

   # Delete empty directories in the cache.
  def delete_empty_directories(dir)
    return if File.realpath(dir) == File.realpath(@root_path)
    if Dir.entries(dir).reject{ |f| EXCLUDED_DIRS.include?(f) }.empty?
      Dir.delete(dir) rescue nil
      delete_empty_directories(File.dirname(dir))
    end
  end

end
