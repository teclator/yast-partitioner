require "cwm/widget"
require "cwm/tree_pager"

require "y2partitioner/widgets/disk_table"
require "y2partitioner/sequences/add_partition"
require "y2partitioner/widgets/delete_disk_partition_button"
require "y2partitioner/widgets/disk_bar_graph"
require "y2partitioner/widgets/disk_description"
require "y2partitioner/icons"

module Y2Partitioner
  module Widgets
    # A Page for a disk: contains {DiskTab} and {PartitionsTab}
    class DiskPage < CWM::Page
      def initialize(device_graph, disk, pager)
        textdomain "storage"
        @device_graph = device_graph
        @disk = disk
        @pager = pager
        self.widget_id = "disk:" + disk.name
      end

      # @macro seeAbstractWidget
      def label
        @disk.sysfs_name
      end

      # @macro seeCustomWidget
      def contents
        icon = Icons.small_icon(Icons::HD)
        VBox(
          Left(
            HBox(
              Image(icon, ""),
              Heading(format(_("Hard Disk: %s"), @disk.name))
            )
          ),
          CWM::Tabs.new(
            DiskTab.new(@disk),
            PartitionsTab.new(@device_graph, @disk, @pager)
          )
        )
      end
    end

    # A Tab for a disk
    class DiskTab < CWM::Tab
      def initialize(disk)
        textdomain "storage"
        @disk = disk
      end

      # @macro seeAbstractWidget
      def label
        _("&Overview")
      end

      # @macro seeCustomWidget
      def contents
        # Page wants a WidgetTerm, not an AbstractWidget
        @contents ||= VBox(DiskDescription.new(@disk))
      end
    end

    # A Tab for disk partitions
    class PartitionsTab < CWM::Tab
      # Add a partition
      class AddButton < CWM::PushButton
        # Y2Storage::Disk
        def initialize(disk)
          textdomain "storage"
          @disk = disk
        end

        def label
          _("Add...")
        end

        def handle
          res = Sequences::AddPartition.new(@disk).run
          res == :finish ? :redraw : nil
        end
      end

      # Edit a partition
      class EditButton < CWM::PushButton
        # Constructor
        #
        # @param disk [Y2Storage::Disk]
        # @param table [Y2Partitioner::Widgets::DiskTable]
        def initialize(disk, table)
          textdomain "storage"
          @disk  = disk
          @table = table
        end

        def label
          _("Edit...")
        end

        def handle
          if @table.items.empty? || !@table.value
            Yast::Popup.Error(_("There are no partitions to edit."))
            return nil
          end

          name = @table.value[/table:partition:(.*)/, 1]
          partition = @disk.partitions.detect { |p| p.name == name }

          Dialogs::FormatAndMount.new(partition).run

          :redraw
        end
      end

      def initialize(device_graph, disk, pager)
        textdomain "storage"
        @device_graph = device_graph
        @disk = disk
        @pager = pager
      end

      def initial
        true
      end

      # @macro seeAbstractWidget
      def label
        _("&Partitions")
      end

      # @macro seeCustomWidget
      def contents
        @partitions_table = DiskTable.new(@disk.partitions, @pager)
        @contents ||= VBox(
          DiskBarGraph.new(@disk),
          @partitions_table,
          HBox(
            AddButton.new(@disk),
            EditButton.new(@disk, @partitions_table),
            DeleteDiskPartitionButton.new(device_graph: @device_graph,
                                          table:        @partitions_table)
          )
        )
      end
    end
  end
end
