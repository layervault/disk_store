Dir[File.join(File.dirname(__FILE__), "eviction_strategies", "*.rb")].each { |f| require f }

class DiskStore
  class Reaper
    DEFAULT_OPTS = {
      cache_size: 1073741824, # 1 gigabyte
      reaper_interval: 10, # seconds,
      eviction_strategy: nil
    }

    @reapers = {}

    # Spawn exactly 1 reaper for each cache path
    def self.spawn_for(path, opts = {})
      return @reapers[path] if @reapers.has_key?(path)

      reaper = Reaper.new(path, opts)
      reaper.spawn!

      @reapers[path] = reaper
      reaper
    end

    # Mostly useful for testing purposes
    def self.kill_all!
      @reapers.each { |path, reaper| reaper.thread.kill }
      @reapers = {}
    end

    attr_reader :path, :thread

    def initialize(path, opts = {})
      @path = path
      @options = DEFAULT_OPTS.merge(opts)
      @thread = nil

      set_eviction_strategy(@options[:eviction_strategy])
    end

    def set_eviction_strategy(strategy)
      return if strategy.nil?
      self.class.send :prepend, DiskStore::Reaper.const_get(strategy)
    end

    def spawn!
      @thread = Thread.new do
        loop do
          perform_sweep! if needs_eviction?
          wait_for_next
        end
      end
    end

    def alive?
      @thread && @thread.alive?
    end

    def running?
      @thread && !@thread.stop?
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

    def files_to_evict
      []
    end

    def directories_to_evict
      []
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
      files.map { |file| File.new(file).size }.inject { |sum, size| sum + size } || 0
    end

    def maximum_cache_size
      @options[:cache_size].to_i
    end
  end
end