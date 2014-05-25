class DiskStore
  class Reaper
    module LRU
      def files_to_evict
        # Collect and sort files based on last access time
        sorted_files = files
          .map { |file|
            st = File.stat(file)
            { path: file, last_fetch: st.atime, size: st.size }
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

      def directories_to_evict
        empty_directories
      end
    end
  end
end