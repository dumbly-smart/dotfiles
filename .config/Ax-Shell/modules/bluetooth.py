from fabric.bluetooth import BluetoothClient, BluetoothDevice
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from gi.repository import Gio, GLib

import modules.icons as icons


def _run_audio_command(arguments, callback=None):
    """Run a PulseAudio/PipeWire command without invoking a shell."""
    try:
        process = Gio.Subprocess.new(
            arguments,
            Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
        )
        process.communicate_utf8_async(
            None,
            None,
            lambda proc, result: callback(proc, result) if callback else None,
        )
    except GLib.Error:
        if callback:
            callback(None, None)


def route_bluetooth_audio(address, callback=None, attempt=0):
    """Select a newly-created BlueZ sink and move current playback to it."""
    address_token = address.replace(":", "_").lower()

    def sinks_finished(process, result):
        output = ""
        if process and result:
            try:
                _ok, output, _error = process.communicate_utf8_finish(result)
            except GLib.Error:
                pass

        sink_name = None
        for line in output.splitlines():
            columns = line.split("\t")
            if len(columns) > 1 and "bluez_output" in columns[1] and address_token in columns[1].lower():
                sink_name = columns[1]
                break

        if not sink_name:
            if attempt < 6:
                GLib.timeout_add(
                    750,
                    lambda: (route_bluetooth_audio(address, callback, attempt + 1), False)[1],
                )
            elif callback:
                callback(False)
            return

        _run_audio_command(["pactl", "set-default-sink", sink_name])

        def inputs_finished(inputs_process, inputs_result):
            inputs_output = ""
            try:
                _ok, inputs_output, _error = inputs_process.communicate_utf8_finish(
                    inputs_result
                )
            except (GLib.Error, AttributeError):
                pass
            for line in inputs_output.splitlines():
                input_id = line.split("\t", 1)[0]
                if input_id.isdigit():
                    _run_audio_command(
                        ["pactl", "move-sink-input", input_id, sink_name]
                    )
            if callback:
                callback(True)

        _run_audio_command(["pactl", "list", "short", "sink-inputs"], inputs_finished)

    _run_audio_command(["pactl", "list", "short", "sinks"], sinks_finished)


class BluetoothDeviceSlot(Box):
    """A device row that keeps its UI in sync with the BlueZ operation."""

    def __init__(self, device: BluetoothDevice, on_changed=None, **kwargs):
        super().__init__(
            name="bluetooth-device",
            orientation="vertical",
            spacing=3,
            **kwargs,
        )
        self.device = device
        self.on_device_changed = on_changed
        self.last_paired = device.paired
        self.last_connected = device.connected
        self.busy = False

        icon_name = device.icon_name or "bluetooth"
        self.device_icon = Image(icon_name=f"{icon_name}-symbolic", size=24)
        self.name_label = Label(
            name="bluetooth-device-name",
            label=self.display_name,
            h_expand=True,
            h_align="start",
            ellipsization="end",
        )
        self.detail_label = Label(
            name="bluetooth-device-detail",
            label=self.device_detail,
            h_expand=True,
            h_align="start",
            ellipsization="end",
        )
        self.connection_label = Label(
            name="bluetooth-connection", markup=icons.bluetooth_disconnected
        )
        self.connect_button = Button(
            name="bluetooth-connect",
            label="Connect",
            tooltip_text=f"Connect to {self.display_name}",
            on_clicked=self.toggle_connection,
        )

        text = Box(
            orientation="vertical",
            spacing=1,
            h_expand=True,
            children=[self.name_label, self.detail_label],
        )
        row = CenterBox(
            start_children=Box(
                name="bluetooth-device-info",
                spacing=10,
                h_expand=True,
                children=[self.device_icon, text],
            ),
            end_children=Box(
                spacing=8, children=[self.connection_label, self.connect_button]
            ),
        )
        self.status_label = Label(
            name="bluetooth-device-status", h_align="start", ellipsization="end"
        )
        self.add(row)
        self.add(self.status_label)

        self.device.connect("changed", self.refresh)
        self.device.connect(
            "notify::closed", lambda *_: self.device.closed and self.destroy()
        )
        self.refresh()
        # BlueZ may reconnect saved headsets before Ax-Shell starts. Route those
        # too; previously routing only happened after this applet's Connect button.
        if self.device.connected:
            GLib.idle_add(self.route_connected_audio)

    @property
    def display_name(self):
        return self.device.alias or self.device.name or "Unknown device"

    @property
    def device_detail(self):
        kind = self.device.type or "Bluetooth device"
        saved = "Saved" if self.device.paired or self.device.trusted else "New device"
        return f"{kind}  •  {saved}"

    def toggle_connection(self, *_):
        if self.busy or self.device.connecting:
            return

        connect = not self.device.connected
        self.status_label.set_label(
            "Pairing and connecting…" if connect and not self.device.paired
            else "Connecting…" if connect
            else "Disconnecting…"
        )
        self.status_label.remove_style_class("error")
        self.connect_button.set_sensitive(False)
        # Use the callback so failures never leave a row looking successful or stuck.
        self.busy = True
        self.device.connect_device(connect, self.connection_finished, connect)

    def connection_finished(self, succeeded, wanted_connected):
        self.busy = False
        self.connect_button.set_sensitive(True)
        if succeeded:
            self.status_label.set_label(
                "Connected" if wanted_connected else "Disconnected"
            )
            self.status_label.remove_style_class("error")
            if wanted_connected:
                self.status_label.set_label("Connected · selecting audio output…")
                route_bluetooth_audio(
                    self.device.address, self.audio_route_finished
                )
        else:
            self.status_label.set_label(
                "Could not connect. Keep the device nearby and in pairing mode."
                if wanted_connected
                else "Could not disconnect. Try again."
            )
            self.status_label.add_style_class("error")
        self.refresh()

    def audio_route_finished(self, routed):
        if not self.device.connected:
            return
        self.status_label.set_label(
            "Connected · audio output selected"
            if routed
            else "Connected · no audio output was exposed by PipeWire"
        )
        if routed:
            self.status_label.remove_style_class("error")
        else:
            self.status_label.add_style_class("error")

    def route_connected_audio(self):
        if self.device.connected:
            self.status_label.set_label("Connected · selecting audio output…")
            route_bluetooth_audio(self.device.address, self.audio_route_finished)
        return False

    def refresh(self, *_):
        became_connected = self.device.connected and not self.last_connected
        self.last_connected = self.device.connected
        self.name_label.set_label(self.display_name)
        self.detail_label.set_label(self.device_detail)
        self.connection_label.set_markup(
            icons.bluetooth_connected
            if self.device.connected
            else icons.bluetooth_disconnected
        )

        if self.busy or self.device.connecting:
            self.connect_button.set_label("Please wait…")
            self.connect_button.set_sensitive(False)
        else:
            self.connect_button.set_sensitive(True)
            self.connect_button.set_label(
                "Disconnect" if self.device.connected else "Connect"
            )

        if self.device.connected:
            self.add_style_class("connected")
            self.connect_button.add_style_class("connected")
            if not self.busy and not self.status_label.get_text().startswith(
                "Connected ·"
            ):
                self.status_label.set_label("Connected")
        else:
            self.remove_style_class("connected")
            self.connect_button.remove_style_class("connected")
            if not self.busy:
                self.status_label.set_label("Disconnected")

        if self.last_paired != self.device.paired:
            self.last_paired = self.device.paired
            if self.on_device_changed:
                self.on_device_changed(self)

        if became_connected and not self.busy:
            GLib.idle_add(self.route_connected_audio)


class BluetoothConnections(Box):
    def __init__(self, **kwargs):
        super().__init__(name="bluetooth", spacing=8, orientation="vertical", **kwargs)

        self.widgets = kwargs["widgets"]
        self.buttons = self.widgets.buttons.bluetooth_button
        self.bt_status_text = self.buttons.bluetooth_status_text
        self.bt_status_button = self.buttons.bluetooth_status_button
        self.bt_icon = self.buttons.bluetooth_icon
        self.bt_label = self.buttons.bluetooth_label
        self.bt_menu_button = self.buttons.bluetooth_menu_button
        self.bt_menu_label = self.buttons.bluetooth_menu_label
        self.device_slots = {}
        self.scan_when_powered = False
        self.power_busy = False

        # Do not attach the callback in the constructor: BluetoothClient loads known
        # devices immediately, before this applet's containers are ready.
        self.client = BluetoothClient()
        self.client.connect("device-added", self.on_device_added)
        self.client.connect("device-removed", self.on_device_removed)
        self.client.connect("notify::enabled", lambda *_: self.status_label())
        self.client.connect("notify::scanning", lambda *_: self.update_scan_label())

        self.scan_label = Label(name="bluetooth-scan-label", markup=icons.radar)
        self.scan_button = Button(
            name="bluetooth-scan",
            child=Box(
                spacing=6,
                children=[self.scan_label, Label(name="bluetooth-scan-text", label="Scan")],
            ),
            tooltip_text="Scan for Bluetooth devices",
            on_clicked=self.toggle_scan,
        )
        self.back_button = Button(
            name="bluetooth-back",
            child=Label(name="bluetooth-back-label", markup=icons.chevron_left),
            on_clicked=lambda *_: self.widgets.show_notif(),
        )

        self.paired_box = Box(spacing=6, orientation="vertical")
        self.available_box = Box(spacing=6, orientation="vertical")
        self.paired_empty = Label(
            name="bluetooth-empty", label="No saved devices", h_align="start"
        )
        self.available_empty = Label(
            name="bluetooth-empty",
            label="Press Scan, then put your device in pairing mode.",
            h_align="start",
            line_wrap="word",
        )

        content_box = Box(spacing=8, orientation="vertical")
        content_box.add(Label(name="bluetooth-section", label="Saved devices", h_align="start"))
        content_box.add(self.paired_box)
        content_box.add(Label(name="bluetooth-section", label="Nearby devices", h_align="start"))
        content_box.add(self.available_box)

        self.children = [
            CenterBox(
                name="bluetooth-header",
                start_children=self.back_button,
                center_children=Label(name="bluetooth-text", label="Bluetooth"),
                end_children=self.scan_button,
            ),
            ScrolledWindow(
                name="bluetooth-devices",
                min_content_size=(-1, -1),
                child=content_box,
                v_expand=True,
                propagate_width=False,
                propagate_height=False,
            ),
        ]

        # BluetoothClient creates known devices before our boxes exist, so populate them here.
        for device in self.client.devices:
            self.add_device(device)
        self.update_empty_states()
        self.client.notify("scanning")
        self.client.notify("enabled")

    def status_label(self):
        controls = [
            self.bt_status_button, self.bt_status_text, self.bt_icon,
            self.bt_label, self.bt_menu_button, self.bt_menu_label,
        ]
        if self.client.enabled:
            self.bt_status_text.set_label("Enabled")
            for item in controls:
                item.remove_style_class("disabled")
            self.bt_icon.set_markup(icons.bluetooth)
            self.scan_button.set_sensitive(True)
            if self.scan_when_powered:
                self.scan_when_powered = False
                self.client.scanning = True
        else:
            self.bt_status_text.set_label("Disabled")
            for item in controls:
                item.add_style_class("disabled")
            self.bt_icon.set_markup(icons.bluetooth_off)
            self.scan_button.set_sensitive(True)  # Scan will power the adapter on.
            if self.client.scanning:
                self.client.scanning = False

    def toggle_power(self, *_):
        """Toggle the adapter, clearing a soft rfkill block before power-on."""
        if self.power_busy:
            return

        if self.client.powered:
            self.client.powered = False
            return

        self.power_busy = True
        self.bt_status_button.set_sensitive(False)
        self.bt_status_text.set_label("Turning on…")

        try:
            process = Gio.Subprocess.new(
                ["rfkill", "unblock", "bluetooth"],
                Gio.SubprocessFlags.STDERR_PIPE,
            )
            process.communicate_utf8_async(
                None,
                None,
                self.on_rfkill_unblocked,
            )
        except GLib.Error as error:
            self.finish_power_on(False, str(error))

    def on_rfkill_unblocked(self, process, result):
        error_message = ""
        try:
            _ok, _stdout, error_message = process.communicate_utf8_finish(result)
            succeeded = process.get_successful()
        except GLib.Error as error:
            succeeded = False
            error_message = str(error)
        self.finish_power_on(succeeded, error_message)

    def finish_power_on(self, rfkill_succeeded, error_message=""):
        self.power_busy = False
        self.bt_status_button.set_sensitive(True)
        if not rfkill_succeeded:
            self.bt_status_text.set_label("Could not unblock Bluetooth")
            self.bt_status_button.set_tooltip_text(
                error_message.strip() or "rfkill could not unblock the Bluetooth radio"
            )
            return

        self.bt_status_button.set_tooltip_text(None)
        # Do this only after rfkill exits; BlueZ rejects Powered=True while the
        # kernel radio is still soft-blocked.
        self.client.powered = True

    def toggle_scan(self, *_):
        if not self.client.enabled:
            # Adapter power-on is asynchronous; start discovery once BlueZ says it is on.
            self.scan_when_powered = True
            self.toggle_power()
        else:
            self.client.toggle_scan()

    def on_device_added(self, client: BluetoothClient, address: str):
        device = client.get_device(address)
        if device:
            self.add_device(device)

    def add_device(self, device):
        if device.address in self.device_slots:
            return
        slot = BluetoothDeviceSlot(device, on_changed=self.move_device)
        self.device_slots[device.address] = slot
        (self.paired_box if device.paired or device.trusted else self.available_box).add(slot)
        slot.show_all()
        self.update_empty_states()

    def on_device_removed(self, _client, address):
        slot = self.device_slots.pop(address, None)
        if slot:
            slot.destroy()
        self.update_empty_states()

    def move_device(self, slot):
        parent = slot.get_parent()
        destination = (
            self.paired_box
            if slot.device.paired or slot.device.trusted
            else self.available_box
        )
        if parent != destination:
            parent.remove(slot)
            destination.add(slot)
            slot.show_all()
        self.update_empty_states()

    def update_empty_states(self):
        for box, empty in (
            (self.paired_box, self.paired_empty),
            (self.available_box, self.available_empty),
        ):
            rows = [child for child in box.get_children() if child is not empty]
            if rows and empty.get_parent() == box:
                box.remove(empty)
            elif not rows and empty.get_parent() is None:
                box.add(empty)
                empty.show()

    def update_scan_label(self):
        scanning = self.client.scanning
        self.scan_button.set_tooltip_text(
            "Stop scanning for Bluetooth devices" if scanning
            else "Scan for Bluetooth devices"
        )
        scan_text = self.scan_button.get_child().get_children()[1]
        scan_text.set_label("Scanning…" if scanning else "Scan")
        for item in (self.scan_label, self.scan_button):
            if scanning:
                item.add_style_class("scanning")
            else:
                item.remove_style_class("scanning")
