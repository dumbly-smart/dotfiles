from typing import Any, List, Literal

import gi
from fabric.core.service import Property, Service, Signal
from fabric.utils import bulk_connect
from gi.repository import Gio, GLib
from loguru import logger

try:
    gi.require_version("NM", "1.0")
    from gi.repository import NM
    AP_FLAGS = getattr(NM, "80211ApFlags")
    AP_SECURITY_FLAGS = getattr(NM, "80211ApSecurityFlags")
except ValueError:
    logger.error("Failed to start network manager")


class Wifi(Service):
    """A service to manage the wifi connection."""

    @Signal
    def changed(self) -> None: ...

    @Signal
    def enabled(self) -> bool: ...

    def __init__(self, client: NM.Client, device: NM.DeviceWifi, **kwargs):
        self._client: NM.Client = client
        self._device: NM.DeviceWifi = device
        self._ap: NM.AccessPoint | None = None
        self._ap_signal: int | None = None
        super().__init__(**kwargs)

        self._client.connect(
            "notify::wireless-enabled",
            lambda *args: self.notifier("enabled", args),
        )
        if self._device:
            bulk_connect(
                self._device,
                {
                    "notify::active-access-point": lambda *args: self._activate_ap(),
                    # request_scan_finish() only means NetworkManager accepted the
                    # request. last-scan changes when fresh results are available,
                    # including when every AP was already present in the cache.
                    "notify::last-scan": lambda *args: self.ap_update(),
                    "access-point-added": lambda *args: self.emit("changed"),
                    "access-point-removed": lambda *args: self.emit("changed"),
                    "state-changed": lambda *args: self.ap_update(),
                },
            )
            self._activate_ap()

    def ap_update(self):
        self.emit("changed")
        for sn in [
            "enabled",
            "internet",
            "strength",
            "frequency",
            "access-points",
            "ssid",
            "state",
            "icon-name",
        ]:
            self.notify(sn)

    def _activate_ap(self):
        if self._ap and self._ap_signal is not None:
            self._ap.disconnect(self._ap_signal)
        self._ap = self._device.get_active_access_point()
        self._ap_signal = None
        if not self._ap:
            return

        self._ap_signal = self._ap.connect(
            "notify::strength", lambda *args: self.ap_update()
        )  # type: ignore

    def toggle_wifi(self):
        self.set_enabled(not self._client.wireless_get_enabled())

    def set_enabled(self, enabled: bool):
        self._client.wireless_set_enabled(bool(enabled))

    # def set_active_ap(self, ap):
    #     self._device.access

    def scan(self):
        def scan_finished(device, result):
            try:
                device.request_scan_finish(result)
            except GLib.Error as error:
                logger.warning(f"Wi-Fi scan failed: {error.message}")
                self.emit("changed")

        self._device.request_scan_async(
            None,
            scan_finished,
        )

    def notifier(self, name: str, *args):
        self.notify(name)
        self.emit("changed")
        return

    @Property(bool, "read-write", default_value=False)
    def enabled(self) -> bool:  # type: ignore
        return bool(self._client.wireless_get_enabled())

    @enabled.setter
    def enabled(self, value: bool):
        self._client.wireless_set_enabled(value)

    @Property(int, "readable")
    def strength(self):
        return self._ap.get_strength() if self._ap else -1

    @Property(str, "readable")
    def icon_name(self):
        if not self._ap:
            return "network-wireless-disabled-symbolic"

        if self.internet == "activated":
            return {
                80: "network-wireless-signal-excellent-symbolic",
                60: "network-wireless-signal-good-symbolic",
                40: "network-wireless-signal-ok-symbolic",
                20: "network-wireless-signal-weak-symbolic",
                00: "network-wireless-signal-none-symbolic",
            }.get(
                min(80, 20 * round(self._ap.get_strength() / 20)),
                "network-wireless-no-route-symbolic",
            )
        if self.internet == "activating":
            return "network-wireless-acquiring-symbolic"

        return "network-wireless-offline-symbolic"

    @Property(int, "readable")
    def frequency(self):
        return self._ap.get_frequency() if self._ap else -1

    @Property(int, "readable")
    def internet(self):
        active_connection = self._device.get_active_connection()
        if not active_connection:
            return "deactivated"
        return {
            NM.ActiveConnectionState.ACTIVATED: "activated",
            NM.ActiveConnectionState.ACTIVATING: "activating",
            NM.ActiveConnectionState.DEACTIVATING: "deactivating",
            NM.ActiveConnectionState.DEACTIVATED: "deactivated",
        }.get(
            active_connection.get_state(),
            "unknown",
        )

    @Property(object, "readable")
    def access_points(self) -> List[object]:
        points: list[NM.AccessPoint] = self._device.get_access_points()

        def make_ap_dict(ap: NM.AccessPoint):
            flags = ap.get_flags()
            wpa_flags = ap.get_wpa_flags()
            rsn_flags = ap.get_rsn_flags()
            secured = bool(
                flags & AP_FLAGS.PRIVACY
                or wpa_flags != AP_SECURITY_FLAGS.NONE
                or rsn_flags != AP_SECURITY_FLAGS.NONE
            )
            security_flags = wpa_flags | rsn_flags
            security_type = (
                "enterprise"
                if security_flags
                & (AP_SECURITY_FLAGS.KEY_MGMT_802_1X | AP_SECURITY_FLAGS.KEY_MGMT_EAP_SUITE_B_192)
                else "owe"
                if security_flags & (AP_SECURITY_FLAGS.KEY_MGMT_OWE | AP_SECURITY_FLAGS.KEY_MGMT_OWE_TM)
                else "sae"
                if security_flags & AP_SECURITY_FLAGS.KEY_MGMT_SAE
                else "wpa-psk"
                if security_flags & AP_SECURITY_FLAGS.KEY_MGMT_PSK
                else "wep"
                if secured
                else "open"
            )
            is_active = bool(
                self._device.get_state() == NM.DeviceState.ACTIVATED
                and self._ap
                and self._ap.get_bssid() == ap.get_bssid()
            )
            return {
                "bssid": ap.get_bssid(),
                # "address": ap.get_
                "last_seen": ap.get_last_seen(),
                "ssid": NM.utils_ssid_to_utf8(ap.get_ssid().get_data())
                if ap.get_ssid()
                else "Unknown",
                "active-ap": self._ap,
                "strength": ap.get_strength(),
                "frequency": ap.get_frequency(),
                "secured": secured,
                "security-type": security_type,
                "active": is_active,
                "ap": ap,
                "icon-name": {
                    80: "network-wireless-signal-excellent-symbolic",
                    60: "network-wireless-signal-good-symbolic",
                    40: "network-wireless-signal-ok-symbolic",
                    20: "network-wireless-signal-weak-symbolic",
                    00: "network-wireless-signal-none-symbolic",
                }.get(
                    min(80, 20 * round(ap.get_strength() / 20)),
                    "network-wireless-no-route-symbolic",
                ),
            }

        return list(map(make_ap_dict, points))

    @Property(str, "readable")
    def ssid(self):
        if not self._ap:
            return "Disconnected"
        ssid = self._ap.get_ssid().get_data()
        return NM.utils_ssid_to_utf8(ssid) if ssid else "Unknown"

    @Property(int, "readable")
    def state(self):
        return {
            NM.DeviceState.UNMANAGED: "unmanaged",
            NM.DeviceState.UNAVAILABLE: "unavailable",
            NM.DeviceState.DISCONNECTED: "disconnected",
            NM.DeviceState.PREPARE: "prepare",
            NM.DeviceState.CONFIG: "config",
            NM.DeviceState.NEED_AUTH: "need_auth",
            NM.DeviceState.IP_CONFIG: "ip_config",
            NM.DeviceState.IP_CHECK: "ip_check",
            NM.DeviceState.SECONDARIES: "secondaries",
            NM.DeviceState.ACTIVATED: "activated",
            NM.DeviceState.DEACTIVATING: "deactivating",
            NM.DeviceState.FAILED: "failed",
        }.get(self._device.get_state(), "unknown")


class Ethernet(Service):
    """A service to manage the ethernet connection."""

    @Signal
    def changed(self) -> None: ...

    @Signal
    def enabled(self) -> bool: ...

    @Property(int, "readable")
    def speed(self) -> int:
        return self._device.get_speed()

    @Property(str, "readable")
    def internet(self) -> str:
        active_connection = self._device.get_active_connection()
        if not active_connection:
            return "disconnected"
        return {
            NM.ActiveConnectionState.ACTIVATED: "activated",
            NM.ActiveConnectionState.ACTIVATING: "activating",
            NM.ActiveConnectionState.DEACTIVATING: "deactivating",
            NM.ActiveConnectionState.DEACTIVATED: "deactivated",
        }.get(
            active_connection.get_state(),
            "disconnected",
        )

    @Property(str, "readable")
    def icon_name(self) -> str:
        network = self.internet
        if network == "activated":
            return "network-wired-symbolic"

        elif network == "activating":
            return "network-wired-acquiring-symbolic"

        elif self._device.get_connectivity != NM.ConnectivityState.FULL:
            return "network-wired-no-route-symbolic"

        return "network-wired-disconnected-symbolic"

    def __init__(self, client: NM.Client, device: NM.DeviceEthernet, **kwargs) -> None:
        super().__init__(**kwargs)
        self._client: NM.Client = client
        self._device: NM.DeviceEthernet = device

        for pn in (
            "active-connection",
            "icon-name",
            "internet",
            "speed",
            "state",
        ):
            self._device.connect(f"notify::{pn}", lambda *_: self.notifier(pn))

        self._device.connect("notify::speed", lambda *_: print(_))

    def notifier(self, pn):
        self.notify(pn)
        self.emit("changed")


class NetworkClient(Service):
    """A service to manage the network connections."""

    @Signal
    def device_ready(self) -> None: ...

    def __init__(self, **kwargs):
        self._client: NM.Client | None = None
        self.wifi_device: Wifi | None = None
        self.ethernet_device: Ethernet | None = None
        super().__init__(**kwargs)
        NM.Client.new_async(
            cancellable=None,
            callback=self._init_network_client,
            **kwargs,
        )

    def _init_network_client(self, client: NM.Client, task: Gio.Task, **kwargs):
        try:
            self._client = NM.Client.new_finish(task)
        except GLib.Error as error:
            logger.error(f"Failed to initialize NetworkManager: {error.message}")
            self.emit("device-ready")
            return
        wifi_device: NM.DeviceWifi | None = self._get_device(NM.DeviceType.WIFI)  # type: ignore
        ethernet_device: NM.DeviceEthernet | None = self._get_device(
            NM.DeviceType.ETHERNET
        )

        if wifi_device:
            self.wifi_device = Wifi(self._client, wifi_device)

        if ethernet_device:
            self.ethernet_device = Ethernet(client=self._client, device=ethernet_device)

        self.emit("device-ready")
        self.notify("primary-device")

    def _get_device(self, device_type) -> Any:
        devices: List[NM.Device] = self._client.get_devices()  # type: ignore
        return next(
            (
                x
                for x in devices
                if x.get_device_type() == device_type
            ),
            None,
        )

    def _get_primary_device(self) -> Literal["wifi", "wired"] | None:
        if not self._client:
            return None
        primary = self._client.get_primary_connection()
        if not primary:
            return None
        return (
            "wifi"
            if "wireless" in str(primary.get_connection_type())
            else "wired"
            if "ethernet" in str(primary.get_connection_type())
            else None
        )

    def _saved_connection_for(self, ssid: str):
        if not self._client:
            return None
        for connection in self._client.get_connections():
            wireless = connection.get_setting_wireless()
            if not wireless or not wireless.get_ssid():
                continue
            saved_ssid = NM.utils_ssid_to_utf8(wireless.get_ssid().get_data())
            if saved_ssid == ssid:
                return connection
        return None

    def has_saved_wifi(self, ssid: str) -> bool:
        return self._saved_connection_for(ssid) is not None

    def connect_wifi(self, ap_data: dict, password: str, callback):
        """Activate Wi-Fi and report success only after the device is connected."""
        if not self._client or not self.wifi_device:
            callback(False, "Wi-Fi adapter is not ready.")
            return

        ap = ap_data.get("ap")
        ssid = ap_data.get("ssid", "")
        if not ap or not ssid:
            callback(False, "This network is no longer available. Scan again.")
            return

        saved = self._saved_connection_for(ssid)

        def finish_activation(active_connection):
            """Wait past request acceptance for auth, addressing, or failure."""
            device = self.wifi_device._device
            completed = False
            signal_ids = []
            timeout_id = None
            last_reason = NM.DeviceStateReason.NONE

            password_reasons = {
                NM.DeviceStateReason.NO_SECRETS,
                NM.DeviceStateReason.SUPPLICANT_CONFIG_FAILED,
                NM.DeviceStateReason.SUPPLICANT_DISCONNECT,
                NM.DeviceStateReason.SUPPLICANT_FAILED,
                NM.DeviceStateReason.SUPPLICANT_TIMEOUT,
            }

            def finish(succeeded, message=""):
                nonlocal completed
                if completed:
                    return
                completed = True
                for obj, signal_id in signal_ids:
                    if signal_id:
                        # NM.ActiveConnection.disconnect() means "disconnect the
                        # network", so use GObject's explicit signal API here.
                        obj.handler_disconnect(signal_id)
                if timeout_id:
                    GLib.source_remove(timeout_id)
                callback(succeeded, message)
                self.wifi_device.ap_update()

            def failure_message(reason):
                if reason in password_reasons:
                    return "Incorrect or missing password. Please enter it and try again."
                if reason == NM.DeviceStateReason.SSID_NOT_FOUND:
                    return "The network is no longer in range. Scan and try again."
                if reason in (
                    NM.DeviceStateReason.DHCP_FAILED,
                    NM.DeviceStateReason.DHCP_START_FAILED,
                    NM.DeviceStateReason.IP_CONFIG_UNAVAILABLE,
                ):
                    return "Connected to Wi-Fi, but could not obtain an IP address."
                return "NetworkManager could not connect to this Wi-Fi network."

            def target_is_active():
                active_ap = device.get_active_access_point()
                if device.get_state() != NM.DeviceState.ACTIVATED or not active_ap:
                    return False
                active_ssid = active_ap.get_ssid()
                return bool(
                    active_ssid
                    and NM.utils_ssid_to_utf8(active_ssid.get_data()) == ssid
                )

            def check_state():
                if completed:
                    return False
                if target_is_active():
                    finish(True)
                elif device.get_state() == NM.DeviceState.FAILED:
                    finish(False, failure_message(last_reason))
                elif (
                    active_connection.get_state()
                    == NM.ActiveConnectionState.DEACTIVATED
                ):
                    finish(False, failure_message(last_reason))
                return False

            def device_state_changed(_device, _new, _old, reason):
                nonlocal last_reason
                last_reason = reason
                check_state()

            def timed_out():
                nonlocal timeout_id
                timeout_id = None
                finish(False, "The connection attempt timed out. Check the password and try again.")
                return False

            signal_ids.append(
                (device, device.connect("state-changed", device_state_changed))
            )
            signal_ids.append(
                (
                    active_connection,
                    active_connection.connect("notify::state", lambda *_: check_state()),
                )
            )
            timeout_id = GLib.timeout_add_seconds(45, timed_out)
            GLib.idle_add(check_state)

        def activate(connection):
            def activate_finished(client, result):
                try:
                    active_connection = client.activate_connection_finish(result)
                    finish_activation(active_connection)
                except GLib.Error as error:
                    callback(False, error.message)

            self._client.activate_connection_async(
                connection,
                self.wifi_device._device,
                ap.get_path(),
                None,
                activate_finished,
            )

        if saved:
            if password:
                security = saved.get_setting_wireless_security()
                if not security:
                    security = NM.SettingWirelessSecurity.new()
                    saved.add_setting(security)
                security_type = ap_data.get("security-type", "wpa-psk")
                if security_type == "wep":
                    security.set_property("key-mgmt", "none")
                    security.set_property("wep-key0", password)
                else:
                    security.set_property(
                        "key-mgmt", "sae" if security_type == "sae" else "wpa-psk"
                    )
                    security.set_property("psk", password)

                def commit_finished(connection, result):
                    try:
                        connection.commit_changes_finish(result)
                        activate(connection)
                    except GLib.Error as error:
                        callback(False, error.message)

                saved.commit_changes_async(True, None, commit_finished)
            else:
                activate(saved)
            return

        def add_finished(client, result):
            try:
                active_connection = client.add_and_activate_connection_finish(result)
                finish_activation(active_connection)
            except GLib.Error as error:
                callback(False, error.message)

        security_type = ap_data.get("security-type", "open")
        if security_type == "enterprise":
            callback(
                False,
                "Enterprise Wi-Fi needs an identity/certificate profile. Add it in system network settings once; it will then connect here.",
            )
            return

        connection = NM.SimpleConnection.new()
        connection_setting = NM.SettingConnection.new()
        connection_setting.set_property("id", ssid)
        connection_setting.set_property("uuid", NM.utils_uuid_generate())
        connection_setting.set_property("type", "802-11-wireless")
        connection_setting.set_property("autoconnect", True)
        connection.add_setting(connection_setting)

        wireless_setting = NM.SettingWireless.new()
        wireless_setting.set_property("ssid", GLib.Bytes.new(ssid.encode()))
        connection.add_setting(wireless_setting)

        if security_type not in ("open", "owe"):
            if not password:
                callback(False, "Enter the Wi-Fi password.")
                return
            security = NM.SettingWirelessSecurity.new()
            if security_type == "wep":
                security.set_property("key-mgmt", "none")
                security.set_property("wep-key0", password)
            else:
                security.set_property(
                    "key-mgmt", "sae" if security_type == "sae" else "wpa-psk"
                )
                security.set_property("psk", password)
            connection.add_setting(security)
        elif security_type == "owe":
            security = NM.SettingWirelessSecurity.new()
            security.set_property("key-mgmt", "owe")
            connection.add_setting(security)

        self._client.add_and_activate_connection_async(
            connection,
            self.wifi_device._device,
            ap.get_path(),
            None,
            add_finished,
        )

    @Property(str, "readable")
    def primary_device(self) -> Literal["wifi", "wired"] | None:
        return self._get_primary_device()
