require_relative "../test_helper"

require "cwm/rspec"
require "y2partitioner/widgets/disk_page"

# FIXME: remove these once they are in cwm/rspec
# (a duplicate definition does work)
RSpec.shared_examples "CWM::Page" do
  include_examples "CWM::CustomWidget"
end

RSpec.shared_examples "CWM::PushButton" do
  include_examples "CWM::AbstractWidget"
end

describe Y2Partitioner::Widgets::DiskPage do
  let(:pager) { double("Pager") }
  let(:disk) do
    double("Disk",
      name: "mydisk", sysfs_name: "sysmydisk",
      partitions: [], partition_table: partition_table)
  end
  let(:partition_table) do
    double("PartitionTable", unused_partition_slots: [])
  end
  let(:ui_table) do
    double("BlkDevicesTable", value: "table:partition:/dev/hdf4", items: ["a", "b"])
  end

  subject { described_class.new("mydisk", pager) }
  before do
    allow(Y2Storage::Disk)
      .to receive(:find_by_name).and_return(disk)
  end

  include_examples "CWM::Page"

  describe Y2Partitioner::Widgets::DiskTab do
    subject { described_class.new(disk) }

    include_examples "CWM::Tab"
  end

  describe Y2Partitioner::Widgets::PartitionsTab do
    subject { described_class.new("mydisk", pager) }

    include_examples "CWM::Tab"
  end

  describe Y2Partitioner::Widgets::PartitionsTab::AddButton do
    subject { described_class.new("mydisk") }

    include_examples "CWM::PushButton"
  end

  describe Y2Partitioner::Widgets::PartitionsTab::EditButton do
    subject { described_class.new(disk, ui_table) }
    before do
      allow(Y2Partitioner::Dialogs::FormatAndMount)
        .to receive(:new).and_return(double(run: :next))
    end

    include_examples "CWM::PushButton"
  end
end
