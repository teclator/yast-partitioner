require "cwm/tree_pager"
require "y2partitioner/widgets/overview"
require "y2partitioner/device_graphs"
require "y2storage"

Yast.import "CWM"
Yast.import "Popup"
Yast.import "Stage"
Yast.import "Wizard"

# Work around YARD inability to link across repos/gems:
# (declaring macros here works because YARD sorts by filename size(!))

# @!macro [new] seeAbstractWidget
#   @see http://www.rubydoc.info/github/yast/yast-yast2/CWM%2FAbstractWidget:${0}
# @!macro [new] seeCustomWidget
#   @see http://www.rubydoc.info/github/yast/yast-yast2/CWM%2FCustomWidget:${0}

# The main module for this package
module Y2Partitioner
  # YaST "clients" are the CLI entry points
  module Clients
    # Main entry point to see partitioner configuration
    class Main
      extend Yast::I18n
      extend Yast::UIShortcuts
      extend Yast::Logger

      # Run the client
      def self.run
        textdomain "storage"

        probed = Y2Storage::StorageManager.instance.y2storage_probed
        staging = Y2Storage::StorageManager.instance.y2storage_staging
        DeviceGraphs.instance.original = probed
        DeviceGraphs.instance.current = staging
        overview_w = CWM::TreePager.new(Widgets::OverviewTree.new(staging))

        contents = MarginBox(
          0.5,
          0.5,
          overview_w
        )

        Yast::Wizard.CreateDialog unless Yast::Stage.initial
        res = Yast::CWM.show(contents, caption: _("Partitioner"))

        # Running system: presenting "Expert Partitioner: Summary" step now
        # ep-main.rb SummaryDialog
        if res == :next && Yast::Popup.ContinueCancel("(potentially) d3stR0y Ur DATA?!??")
          storage.commit
        end
        Yast::Wizard.CloseDialog unless Yast::Stage.initial
      end
    end
  end
end
