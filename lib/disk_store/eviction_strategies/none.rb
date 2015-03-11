class DiskStore
  class Reaper
    module None
      def files_to_evict
        []
      end

      def directories_to_evict
        []
      end
    end
  end
end
