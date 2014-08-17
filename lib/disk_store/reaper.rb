require 'celluloid'

Dir[File.join(File.dirname(__FILE__), "eviction_strategies", "*.rb")].each { |f| require f }

class DiskStore
  class Reaper
    include Celluloid

    DEFAULT_OPTS = {
      cache_size: 1073741824, # 1 gigabyte
      reaper_interval: 10, # seconds,
      eviction_strategy: nil
    }

    @reapers = {}

    # Spawn exactly 1 reaper for each cache path
    def self.spawn_for(path, opts = {})
      return Celluloid::Actor[path] if !Celluloid::Actor[path].nil?
      
      Reaper.supervise_as(path, path, opts)
      Celluloid::Actor[path].async.start!
      Celluloid::Actor[path]
    end

    attr_reader :path

    def initialize(path, opts = {})
      @path = path
      @options = DEFAULT_OPTS.merge(opts)

      set_eviction_strategy(@options[:eviction_strategy])
    end

    def set_eviction_strategy(strategy)
      strategy ||= :None
      self.class.send :include, DiskStore::Reaper.const_get(strategy)
    end

    def start!
      loop do
        perform_sweep! if needs_eviction?
        wait_for_next
      end
    end

    private

    def perform_sweep!
      # Evict and delete selected files
      files_to_evict.each { |file| FileUtils.rm(file[:path]) }
      directories_to_evict.each { |dir| Dir.rmdir(dir) }
    end

    def needs_eviction?
      current_cache_size > maximum_cache_size
    end

    def wait_for_next
      sleep @options[:reaper_interval]
    end

    def files
      Dir[File.join(path, "**", "*")].select { |f| File.file?(f) }
    end

    def directories
      Dir[File.join(path, "**", "*")].select { |f| File.directory?(f) }
    end

    def empty_directories
      directories.select { |d| Dir.entries(d).size == 2 }
    end

    def current_cache_size
      files.inject(0) { |sum, file| sum + File.size(file) }
    end

    def maximum_cache_size
      @options[:cache_size].to_i
    end
  end
end