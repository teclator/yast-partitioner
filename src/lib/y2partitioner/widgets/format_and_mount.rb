require "yast"
require "cwm"
require "y2storage"
require "y2partitioner/dialogs/encrypt_password"

module Y2Partitioner
  module Widgets
    # Format options for {BlkDevice}
    class FormatOptions < CWM::CustomWidget
      def initialize(blk_device)
        textdomain "storage"

        @blk_device = blk_device
        @filesystem_widget = BlkDeviceFilesystem.new(@blk_device.filesystem_type.to_s)

        self.handle_all_events = true
      end

      def init
        select_no_format
        Yast::UI.ChangeWidget(Id(:no_format_device), :Value, true)
      end

      def store
        @blk_device.remove_descendants if encrypt? || format?

        if encrypt?
          @blk_device = @blk_device.create_encryption(dm_name_for(@blk_device))
          Dialogs::EncryptPassword.new(@blk_device).run
        end

        @blk_device.create_filesystem(@filesystem_widget.selected_filesystem) if format?
      end

      def handle(event)
        case event["ID"]
        when :format_device
          select_format
        when :no_format_device
          select_no_format
        end

        nil
      end

      def dm_name_for(device)
        name = device.name.split("/").last
        "cr_#{name}"
      end

      def contents
        Frame(
          _("Format Options"),
          MarginBox(
            1.45,
            0.5,
            VBox(
              RadioButtonGroup(
                Id(:format),
                VBox(
                  Left(RadioButton(Id(:format_device), Opt(:notify), _("Format device"))),
                  HBox(
                    HSpacing(4),
                    Left(@filesystem_widget)
                  ),
                  Left(RadioButton(Id(:no_format_device), Opt(:notify), _("Do not format device")))
                )
              ),
              Left(CheckBox(Id(:encrypt_device), _("Encrypt Device")))
            )
          )
        )
      end

      def select_format
        @filesystem_widget.enable
      end

      def select_no_format
        @filesystem_widget.disable
      end

      def format?
        Yast::UI::QueryWidget(Id(:format_device), :Value)
      end

      def encrypt?
        Yast::UI::QueryWidget(Id(:encrypt_device), :Value)
      end

      def encrypter
        @encrypter ||= Y2Storage::Proposal::Encrypter.new
      end
    end

    # Mount options for {BlkDevice}
    class MountOptions < CWM::CustomWidget
      def initialize(blk_device)
        textdomain "storage"

        @blk_device = blk_device
        @mount_point_widget = MountPoint.new(@blk_device.filesystem_mountpoint)
        @fstab_options_widget = if @blk_device.filesystem
          @blk_device.filesystem.fstab_options
        else
          []
        end

        self.handle_all_events = true
      end

      def init
        if @blk_device.filesystem_mountpoint
          Yast::UI.ChangeWidget(Id(:mount_device), :Value, true)
        else
          @mount_point_widget.disable
          Yast::UI.ChangeWidget(Id(:no_mount_device), :Value, true)
        end
      end

      def contents
        Frame(
          _("Mount Options"),
          MarginBox(
            1.45,
            0.5,
            VBox(
              RadioButtonGroup(
                Id(:mount),
                VBox(
                  Left(RadioButton(Id(:mount_device), Opt(:notify), _("Mount device"))),
                  HBox(
                    HSpacing(4),
                    VBox(
                      Left(@mount_point_widget),
                      Left(PushButton(Id(:fstab_options), _("Fstab options")))
                    )
                  ),
                  Left(RadioButton(Id(:no_mount_device), Opt(:notify), _("Do not mount device")))
                )
              )
            )
          )
        )
      end

      def handle(event)
        case event["ID"]
        when :mount_device
          @mount_point_widget.enable
        when :no_mount_device
          @mount_point_widget.disable
        end

        nil
      end

      def store
        @blk_device.filesystem.mountpoint = @mount_point_widget.value if mount?

        nil
      end

      def mount?
        Yast::UI.QueryWidget(Id(:mount_device), :Value)
      end
    end

    # BlkDevice Filesystem selector
    class BlkDeviceFilesystem < CWM::ComboBox
      def initialize(filesystem)
        textdomain "storage"

        @filesystem = filesystem
      end

      def init
        self.value = @filesystem
      end

      def label
        _("Filesystem")
      end

      def items
        Y2Storage::Filesystems::Type.all.map do |fs|
          [fs.to_s, fs.to_human_string]
        end
      end

      def selected_filesystem
        Y2Storage::Filesystems::Type.all.detect do |fs|
          fs.to_s == value
        end
      end
    end

    # MountPoint selector
    class MountPoint < CWM::ComboBox
      def initialize(mount_point)
        @mount_point = mount_point
      end

      def init
        self.value = @mount_point
      end

      def label
        _("Mount Point")
      end

      def opt
        [:editable, :hstretch, :notify]
      end

      def store
        @mount_point = value
      end

      def items
        %w(/root /home /opt /var).map { |mp| [mp, mp] }
      end
    end
  end
end