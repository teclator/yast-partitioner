require_relative "../test_helper"
require "ui/sequence"

describe UI::Sequence do
  describe "#abortable" do
    it "adds aborting edges where missing" do
      old = {
        "ws_start" => "read",
        "read"     => { next: "process" },
        "process"  => { next: "write" },
        "write"    => { next: :next }
      }
      new = {
        "ws_start" => "read",
        "read"     => { abort: :abort, next: "process" },
        "process"  => { abort: :abort, next: "write" },
        "write"    => { abort: :abort, next: :next }
      }

      expect(subject.abortable(old)).to eq(new)
    end

    it "keeps existing aborting edges" do
      old = {
        "ws_start" => "read",
        "process"  => { abort: :back, next: "write" },
        "write"    => { next: :next }
      }
      new = {
        "ws_start" => "read",
        "process"  => { abort: :back, next: "write" },
        "write"    => { abort: :abort, next: :next }
      }

      expect(subject.abortable(old)).to eq(new)
    end
  end

  describe "#from_methods" do
    class TestSequence < UI::Sequence
      def first
      end

      def second
      end
    end
    subject { TestSequence.new }

    it "defines the aliases from instance methods" do
      seq = {
        "ws_start" => "first",
        "first"    => { next: "second" },
        "second"   => { next: :next }
      }
      wanted = {
        "first"  => subject.method(:first),
        "second" => subject.method(:second)
      }

      expect(subject.from_methods(seq)).to eq(wanted)
    end
  end
end
