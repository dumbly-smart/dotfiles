import gi

gi.require_version("Gtk", "3.0")
gi.require_version("NM", "1.0")

from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from gi.repository import GLib, Gtk

import modules.icons as icons
from services.network import NetworkClient


class WifiAccessPointSlot(Box):
    def __init__(self, ap_data: dict, network_service: NetworkClient, **kwargs):
        super().__init__(
            name="wifi-ap-slot", orientation="vertical", spacing=5, **kwargs
        )
        self.ap_data = ap_data
        self.network_service = network_service
        self.is_active = self._is_active()
        self.busy = False

        ssid = ap_data.get("ssid", "Unknown network")
        icon_name = ap_data.get(
            "icon-name", "network-wireless-signal-none-symbolic"
        )
        secured = ap_data.get("secured", False)
        saved = network_service.has_saved_wifi(ssid)

        self.ap_icon = Image(icon_name=icon_name, size=24)
        self.name_label = Label(
            name="wifi-network-name",
            label=ssid,
            h_expand=True,
            h_align="start",
            ellipsization="end",
        )
        details = [f"{ap_data.get('strength', 0)}%"]
        security_type = ap_data.get("security-type", "open")
        details.append(
            "Enterprise"
            if security_type == "enterprise"
            else "Enhanced open"
            if security_type == "owe"
            else "Secured"
            if secured
            else "Open"
        )
        if saved:
            details.append("Saved")
        self.detail_label = Label(
            name="wifi-network-detail",
            label="  •  ".join(details),
            h_expand=True,
            h_align="start",
        )
        text = Box(
            orientation="vertical",
            spacing=1,
            h_expand=True,
            children=[self.name_label, self.detail_label],
        )

        self.connect_button = Button(
            name="wifi-connect-button",
            label="Connected" if self.is_active else "Connect",
            sensitive=not self.is_active,
            on_clicked=self._on_connect_clicked,
            style_classes=["connected"] if self.is_active else None,
        )
        row = CenterBox(
            start_children=Box(
                spacing=10, h_expand=True, children=[self.ap_icon, text]
            ),
            end_children=self.connect_button,
        )

        self.password_entry = Gtk.Entry(
            name="wifi-password-entry",
            placeholder_text="Wi-Fi password",
            visibility=False,
            activates_default=False,
        )
        self.password_entry.set_icon_from_icon_name(
            Gtk.EntryIconPosition.SECONDARY, "view-reveal-symbolic"
        )
        self.password_entry.set_icon_tooltip_text(
            Gtk.EntryIconPosition.SECONDARY, "Show or hide password"
        )
        self.password_entry.connect("icon-press", self._toggle_password_visibility)
        self.password_entry.connect("activate", self._submit_password)
        self.password_entry.set_no_show_all(True)
        self.password_entry.hide()

        self.feedback_label = Label(
            name="wifi-network-feedback",
            h_align="start",
            ellipsization="end",
            line_wrap="word",
        )
        self.feedback_label.set_no_show_all(True)
        self.feedback_label.hide()

        self.add(row)
        self.add(self.password_entry)
        self.add(self.feedback_label)
        if self.is_active:
            self.add_style_class("connected")

    def _is_active(self):
        return bool(self.ap_data.get("active", False))

    def _toggle_password_visibility(self, entry, *_):
        entry.set_visibility(not entry.get_visibility())

    def _submit_password(self, *_):
        self._connect()

    def _on_connect_clicked(self, _button):
        if self.is_active or self.busy:
            return
        saved = self.network_service.has_saved_wifi(
            self.ap_data.get("ssid", "")
        )
        accepts_password = (
            self.ap_data.get("secured", False)
            and self.ap_data.get("security-type") not in ("owe", "enterprise")
        )
        if accepts_password and not self.password_entry.get_visible():
            self.password_entry.set_placeholder_text(
                "Wi-Fi password (leave blank to use saved)"
                if saved
                else "Wi-Fi password"
            )
            self.password_entry.show()
            self.password_entry.grab_focus()
            self.connect_button.set_label("Join")
            return
        self._connect()

    def _connect(self):
        self.busy = True
        self.connect_button.set_label("Connecting…")
        self.connect_button.set_sensitive(False)
        self.feedback_label.set_label("Connecting to this network…")
        self.feedback_label.remove_style_class("error")
        self.feedback_label.show()
        self.network_service.connect_wifi(
            self.ap_data,
            self.password_entry.get_text(),
            self._connection_finished,
        )

    def _connection_finished(self, succeeded, error):
        self.busy = False
        if succeeded:
            self.is_active = True
            self.connect_button.set_label("Connected")
            self.connect_button.set_sensitive(False)
            self.connect_button.add_style_class("connected")
            self.add_style_class("connected")
            self.feedback_label.set_label("Connected")
            self.password_entry.set_text("")
            self.password_entry.hide()
        else:
            self.connect_button.set_label("Try again")
            self.connect_button.set_sensitive(True)
            message = error or "Connection failed. Check the password and try again."
            if "Secrets were required" in message or "password" in message.lower():
                message = "Incorrect or missing password. Please try again."
                self.password_entry.show()
                self.password_entry.grab_focus()
            self.feedback_label.set_label(message)
            self.feedback_label.add_style_class("error")


class NetworkConnections(Box):
    def __init__(self, **kwargs):
        super().__init__(
            name="network-connections",
            orientation="vertical",
            spacing=8,
            **kwargs,
        )
        self.widgets = kwargs.get("widgets")
        self.network_client = NetworkClient()
        self.loading = True
        self._wifi_target = None

        self.status_label = Label(
            name="wifi-status",
            label="Finding your Wi-Fi adapter…",
            h_expand=True,
            h_align="center",
            line_wrap="word",
        )
        self.back_button = Button(
            name="network-back",
            child=Label(name="network-back-label", markup=icons.chevron_left),
            on_clicked=lambda *_: self.widgets.show_notif(),
        )
        self.wifi_toggle_button_icon = Label(markup=icons.wifi_3)
        self.wifi_toggle_button_text = Label(label="Turn off")
        self.wifi_toggle_button = Button(
            name="wifi-toggle-button",
            child=Box(
                spacing=6,
                children=[
                    self.wifi_toggle_button_icon,
                    self.wifi_toggle_button_text,
                ],
            ),
            tooltip_text="Turn Wi-Fi on or off",
            on_clicked=self._toggle_wifi,
        )
        self.refresh_button_icon = Label(
            name="network-refresh-label", markup=icons.reload
        )
        self.refresh_button = Button(
            name="network-refresh",
            child=Box(
                spacing=6,
                children=[
                    self.refresh_button_icon,
                    Label(name="network-refresh-text", label="Scan"),
                ],
            ),
            tooltip_text="Scan for Wi-Fi networks",
            on_clicked=self._refresh_access_points,
        )

        header_box = CenterBox(
            name="network-header",
            start_children=self.back_button,
            center_children=Label(name="network-title", label="Wi-Fi"),
            end_children=Box(
                orientation="horizontal",
                spacing=5,
                children=[self.wifi_toggle_button, self.refresh_button],
            ),
        )
        self.ap_list_box = Box(orientation="vertical", spacing=6)
        self.add(header_box)
        self.add(self.status_label)
        self.add(
            ScrolledWindow(
                name="network-ap-scrolled-window",
                child=self.ap_list_box,
                h_expand=True,
                v_expand=True,
                propagate_width=False,
                propagate_height=False,
            )
        )

        self.network_client.connect("device-ready", self._on_device_ready)
        self.wifi_toggle_button.set_sensitive(False)
        self.refresh_button.set_sensitive(False)

    def _on_device_ready(self, _client):
        self.loading = False
        wifi = self.network_client.wifi_device
        if not wifi:
            self.status_label.set_label(
                "No Wi-Fi adapter was found. Check that NetworkManager manages it."
            )
            self.status_label.set_visible(True)
            return

        wifi.connect("changed", self._load_access_points)
        wifi.connect("notify::enabled", self._update_wifi_status_ui)
        self._update_wifi_status_ui()
        if wifi.enabled:
            self._load_access_points()
            GLib.idle_add(self._refresh_access_points)

    def _update_wifi_status_ui(self, *_):
        wifi = self.network_client.wifi_device
        if not wifi:
            return
        enabled = wifi.enabled
        self.wifi_toggle_button.set_sensitive(True)
        # The scan button doubles as a convenient power-on action.
        self.refresh_button.set_sensitive(True)
        self.wifi_toggle_button_icon.set_markup(
            icons.wifi_3 if enabled else icons.wifi_off
        )
        if self._wifi_target is None:
            self.wifi_toggle_button_text.set_label("Turn off" if enabled else "Turn on")
        elif not self._wifi_target:
            # NetworkManager may emit the old enabled value while powering down.
            # Never schedule an automatic scan during that transition.
            self.status_label.set_label("Turning Wi-Fi off…")
            self.status_label.set_visible(True)
            return
        if not enabled:
            self.status_label.set_label("Wi-Fi is off. Press Scan to turn it on.")
            self.status_label.set_visible(True)
            self._clear_ap_list()
        elif not self.ap_list_box.get_children():
            GLib.idle_add(self._refresh_access_points)

    def _toggle_wifi(self, _button):
        wifi = self.network_client.wifi_device
        if wifi:
            current_target = wifi.enabled if self._wifi_target is None else self._wifi_target
            target = not current_target
            self._wifi_target = target
            self.wifi_toggle_button_text.set_label(
                "Turn off" if target else "Turn on"
            )
            self.status_label.set_label(
                "Turning Wi-Fi on…" if target else "Turning Wi-Fi off…"
            )
            self.status_label.set_visible(True)
            wifi.set_enabled(target)
            GLib.timeout_add(900, self._confirm_wifi_power, target, 0)

    def _confirm_wifi_power(self, target, retry):
        wifi = self.network_client.wifi_device
        if not wifi:
            return False
        if self._wifi_target != target:
            return False
        if wifi.enabled != target and retry == 0:
            wifi.set_enabled(target)
            GLib.timeout_add(900, self._confirm_wifi_power, target, 1)
            return False
        self._wifi_target = None
        self._update_wifi_status_ui()
        if wifi.enabled != target:
            self.status_label.set_label(
                "NetworkManager could not change the Wi-Fi radio state."
            )
            self.status_label.set_visible(True)
        return False

    def _refresh_access_points(self, _button=None):
        wifi = self.network_client.wifi_device
        if not wifi:
            return False
        if not wifi.enabled:
            # Background/idle scans must never override an explicit power-off.
            # A real button argument means the user deliberately pressed Scan.
            if _button is not None:
                self._wifi_target = True
                self.wifi_toggle_button_text.set_label("Turn off")
                self.status_label.set_label("Turning Wi-Fi on…")
                self.status_label.set_visible(True)
                wifi.set_enabled(True)
                GLib.timeout_add(900, self._confirm_wifi_power, True, 0)
            return False
        self.status_label.set_label("Scanning for nearby networks…")
        self.status_label.set_visible(True)
        self.refresh_button.add_style_class("scanning")
        wifi.scan()
        return False

    def _clear_ap_list(self):
        for child in self.ap_list_box.get_children():
            child.destroy()

    def _load_access_points(self, *_):
        wifi = self.network_client.wifi_device
        if not wifi or not wifi.enabled:
            self._clear_ap_list()
            return

        # NetworkManager emits "changed" for scans, signal-strength updates, and
        # device-state changes. Rebuilding the rows while a password is being
        # entered destroys the focused Gtk.Entry; the next key then reaches the
        # notch's type-to-launch handler and opens the app selector.
        for child in self.ap_list_box.get_children():
            if (
                isinstance(child, WifiAccessPointSlot)
                and child.password_entry.get_visible()
                and (child.password_entry.has_focus() or child.busy)
            ):
                self.refresh_button.remove_style_class("scanning")
                return

        # NetworkManager reports one AP per radio/BSSID. Show the strongest row per SSID.
        strongest = {}
        for ap in wifi.access_points:
            ssid = ap.get("ssid")
            if not ssid or ssid == "Unknown":
                continue
            current = strongest.get(ssid)
            if (
                current is None
                or ap.get("active", False)
                or (
                    not current.get("active", False)
                    and ap.get("strength", 0) > current.get("strength", 0)
                )
            ):
                strongest[ssid] = ap

        self._clear_ap_list()
        access_points = sorted(
            strongest.values(),
            key=lambda ap: (
                not ap.get("active", False),
                -ap.get("strength", 0),
                ap.get("ssid", "").lower(),
            ),
        )
        self.refresh_button.remove_style_class("scanning")
        if not access_points:
            self.status_label.set_label(
                "No networks found. Move closer to the router and scan again."
            )
            self.status_label.set_visible(True)
        else:
            if wifi.state == "activated" and wifi.ssid != "Disconnected":
                self.status_label.set_label(f"Connected to {wifi.ssid}")
            elif wifi.state in ("prepare", "config", "need_auth", "ip_config", "ip_check"):
                self.status_label.set_label("Connecting…")
            elif wifi.state == "failed":
                self.status_label.set_label("Connection failed. Choose a network to try again.")
            else:
                self.status_label.set_label("Not connected")
            self.status_label.set_visible(True)
            for ap_data in access_points:
                self.ap_list_box.add(
                    WifiAccessPointSlot(ap_data, self.network_client)
                )
        self.ap_list_box.show_all()
