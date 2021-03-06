require "yast"
require "cwm/dialog"
require "cwm/common_widgets"

module Y2Partitioner
  module Dialogs
    # Determine the type (primary/extended/logical)
    # of a partition to be created.
    # Part of {Sequences::AddPartition}.
    # Formerly MiniWorkflowStepPartitionType
    class PartitionType < CWM::Dialog
      # Choose partition type: primary/extended/logical.
      class TypeChoice < CWM::RadioButtons
        def initialize(ptemplate, slots)
          textdomain "storage"
          @ptemplate = ptemplate
          @slots = slots
        end

        def label
          _("New Partition Type")
        end

        def help
          # helptext
          _("<p>Choose the partition type for the new partition.</p>")
        end

        def items
          available_types = Y2Storage::PartitionType.all.map do |ty|
            [ty.to_s, !@slots.find { |s| s.possible?(ty) }.nil?]
          end.to_h

          [
            # radio button text
            ["primary", _("&Primary Partition")],
            # radio button text
            ["extended", _("&Extended Partition")],
            # radio button text
            ["logical", _("&Logical Partition")]
          ].find_all { |t, _l| available_types[t] }
        end

        def validate
          !value.nil?
        end

        def store
          @ptemplate.type = Y2Storage::PartitionType.new(value)
        end
      end

      # @param slots [Array<Y2Storage::PartitionTables::PartitionSlot>]
      def initialize(disk, ptemplate, slots)
        @disk = disk
        @ptemplate = ptemplate
        @slots = slots
        textdomain "storage"
      end

      def title
        # dialog title
        Yast::Builtins.sformat(_("Add Partition on %1"), @disk.name)
      end

      def contents
        HVSquash(TypeChoice.new(@ptemplate, @slots))
      end
    end
  end
end
