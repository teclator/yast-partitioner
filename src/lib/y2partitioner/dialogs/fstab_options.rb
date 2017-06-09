require 'yast'
require 'cwm'

module Y2Partitioner
  class FstabOptions < CWM::Dialog
    def initialize(filesystem)
      @filesystem = filesystem
    end

    def init
    end

    def store
    end
  end
end
