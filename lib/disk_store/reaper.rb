class DiskStore
  class Reaper
    DEFAULT_OPTS = {
      cache_size: 1073741824, # 1 gigabyte
      reaper_interval: 10 # seconds
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
      @thread.alive?
    end

    def running?
      !@thread.stop?
    end

    private

    def perform_sweep!
      # Evict and delete selected files
      files_to_evict.each { |file| FileUtils.rm(file[:path]) }
    end

    def needs_eviction?
      current_cache_size > maximum_cache_size
    end

    def files_to_evict
      # Collect and sort files based on last access time
      sorted_files = files
        .map { |file|
          data = nil
          File.new(file, 'rb').tap { |fd|
            data = { path: file, last_fetch: fd.atime, size: fd.size }
          }.close
          data
        }
        .sort { |a, b| a[:last_fetch] <=> b[:last_fetch] } # Oldest first

      # Determine which files to evict
      space_to_evict = current_cache_size - maximum_cache_size
      space_evicted = 0
      evictions = []
      while space_evicted < space_to_evict
        evicted_file = sorted_files.shift
        space_evicted += evicted_file[:size]
        evictions << evicted_file
      end

      evictions
    end

    def wait_for_next
      sleep @options[:reaper_interval]
    end

    def files
      Dir[File.join(path, "**", "*")].select { |f| File.file?(f) }
    end

    def current_cache_size
      files.map { |file| File.new(file).size }.inject { |sum, size| sum + size } || 0
    end

    def maximum_cache_size
      @options[:cache_size].to_i
    end
  end
end