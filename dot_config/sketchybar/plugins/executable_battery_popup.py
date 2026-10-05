#!/usr/bin/env python3

import plistlib
import re
import shutil
import subprocess
import sys


SKETCHYBAR = shutil.which("sketchybar") or "/opt/homebrew/bin/sketchybar"
PARENT = "battery"


def first_number(*values):
    for value in values:
        if isinstance(value, bool):
            continue

        if isinstance(value, (int, float)):
            return value

    return None


def first_capacity(*values):
    """
    Return the first value that plausibly represents battery capacity
    in mAh.

    Apple Silicon exposes some top-level fields such as MaxCapacity
    as percentages (0-100), so values <= 100 must not be treated as mAh.
    """
    for value in values:
        if isinstance(value, bool):
            continue

        if isinstance(value, (int, float)) and value > 100:
            return float(value)

    return None


def signed_current(value):
    """
    Convert an unsigned two's-complement current value back into
    a signed integer when necessary.
    """
    if value is None:
        return None

    value = int(value)

    if value >= 2**63:
        value -= 2**64
    elif 2**31 <= value <= 0xFFFFFFFF:
        value -= 2**32

    return value


def format_minutes(minutes, approximate=False):
    if minutes is None:
        return "--"

    if minutes < 0:
        return "--"

    # Avoid displaying 0m for a real, non-zero estimate.
    if 0 < minutes < 1:
        minutes = 1
    else:
        minutes = int(round(minutes))

    hours, mins = divmod(int(minutes), 60)

    if hours:
        text = f"{hours}h {mins:02d}m"
    else:
        text = f"{mins}m"

    if approximate:
        return f"≈ {text}"

    return text


def get_battery_data():
    raw = subprocess.check_output(
        [
            "/usr/sbin/ioreg",
            "-r",
            "-n",
            "AppleSmartBattery",
            "-a",
        ]
    )

    objects = plistlib.loads(raw)

    if not objects:
        raise RuntimeError("AppleSmartBattery was not found")

    battery = objects[0]
    data = battery.get("BatteryData") or {}

    return battery, data


def get_pmset():
    try:
        output = subprocess.check_output(
            [
                "/usr/bin/pmset",
                "-g",
                "batt",
            ],
            text=True,
        )
    except subprocess.SubprocessError:
        return None, None

    percent = None
    eta_minutes = None

    match = re.search(r"(\d+)%", output)

    if match:
        percent = int(match.group(1))

    match = re.search(
        r"(\d+):(\d+)\s+remaining",
        output,
    )

    if match:
        eta_minutes = int(match.group(1)) * 60 + int(match.group(2))

    return percent, eta_minutes


def set_rows(rows):
    command = [SKETCHYBAR]

    for name, value in rows.items():
        command.extend(
            [
                "--set",
                f"{PARENT}.{name}",
                f"label={value}",
            ]
        )

    subprocess.run(
        command,
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main():
    try:
        battery, data = get_battery_data()

    except Exception as exc:
        print(
            f"battery_popup.py: unable to read battery data: {exc}",
            file=sys.stderr,
        )

        set_rows(
            {
                "power": "--",
                "energy": "--",
                "charge": "--",
                "to80": "--",
                "to100": "--",
                "current": "--",
                "health": "--",
                "cycles": "--",
                "source": "--",
            }
        )

        return 1

    #
    # State
    #

    charging = bool(battery.get("IsCharging", False))

    external = bool(battery.get("ExternalConnected", False))

    fully_charged = bool(battery.get("FullyCharged", False))

    pmset_percent, pmset_eta = get_pmset()

    percent = pmset_percent

    if percent is None:
        percent = first_number(
            battery.get("CurrentCapacity"),
            data.get("StateOfCharge"),
        )

    #
    # Electrical measurements
    #

    voltage_mv = first_number(
        battery.get("Voltage"),
        data.get("Voltage"),
    )

    #
    # Amperage is usually the best live value on Apple Silicon.
    #
    # Positive  = battery charging
    # Negative  = battery discharging
    #

    current_ma = first_number(
        battery.get("Amperage"),
        battery.get("InstantAmperage"),
        data.get("Current"),
        data.get("InstantAmperage"),
    )

    current_ma = signed_current(current_ma)

    #
    # Real battery capacities
    #
    # IMPORTANT:
    #
    # Do NOT use:
    #
    #     battery["MaxCapacity"]
    #     battery["CurrentCapacity"]
    #
    # as mAh values on Apple Silicon. They may simply contain
    # percentage values such as 100 and 46.
    #

    design_mah = first_capacity(
        data.get("DesignCapacity"),
        battery.get("DesignCapacity"),
    )

    #
    # FccComp1 is a compensated full-charge capacity reported by
    # newer Apple battery gauges. Prefer it when available.
    #

    full_mah = first_capacity(
        data.get("FccComp1"),
        data.get("NominalChargeCapacity"),
        data.get("FullChargeCapacity"),
        battery.get("NominalChargeCapacity"),
        battery.get("AppleRawMaxCapacity"),
    )

    remaining_mah = first_capacity(
        data.get("RemainingCapacity"),
        battery.get("AppleRawCurrentCapacity"),
    )

    #
    # If macOS doesn't expose RemainingCapacity, derive it from SOC.
    #

    if remaining_mah is None and full_mah is not None and percent is not None:
        remaining_mah = full_mah * percent / 100.0

    #
    # Cycle count
    #

    cycles = first_number(
        battery.get("CycleCount"),
        data.get("CycleCount"),
    )

    #
    # Battery power
    #
    # mV × mA / 1,000,000 = W
    #

    power_w = None

    if voltage_mv is not None and current_ma is not None:
        power_w = voltage_mv * current_ma / 1_000_000.0

    if power_w is None:
        power_text = "--"

    elif power_w > 0.2:
        power_text = f"{power_w:.1f} W into battery"

    elif power_w < -0.2:
        power_text = f"{abs(power_w):.1f} W from battery"

    else:
        power_text = "0.0 W"

    #
    # Battery energy
    #
    # mAh × mV / 1,000,000 = Wh
    #

    design_voltage_mv = first_number(
        data.get("DesignVoltage"),
        battery.get("DesignVoltage"),
    )

    energy_voltage_mv = first_number(
        design_voltage_mv,
        voltage_mv,
    )

    current_wh = None
    full_wh = None

    if energy_voltage_mv is not None:
        if remaining_mah is not None:
            current_wh = remaining_mah * energy_voltage_mv / 1_000_000.0

        if full_mah is not None:
            full_wh = full_mah * energy_voltage_mv / 1_000_000.0

    if current_wh is not None and full_wh is not None:
        energy_text = f"≈ {current_wh:.1f} / {full_wh:.1f} Wh"

    elif current_wh is not None:
        energy_text = f"≈ {current_wh:.1f} Wh"

    else:
        energy_text = "--"

    #
    # Current / voltage
    #

    if current_ma is not None and voltage_mv is not None:
        current_text = f"{current_ma / 1000.0:+.2f} A @ {voltage_mv / 1000.0:.2f} V"

    elif current_ma is not None:
        current_text = f"{current_ma / 1000.0:+.2f} A"

    else:
        current_text = "--"

    #
    # Battery health
    #
    # Full-charge capacity / original design capacity.
    #

    health = None

    if full_mah is not None and design_mah is not None and design_mah > 0:
        health = full_mah / design_mah * 100.0

        #
        # A brand-new battery can occasionally report slightly
        # above design capacity.
        #
        health = min(health, 100.0)

    if health is not None:
        health_text = f"{health:.1f}%"
    else:
        health_text = "--"

    #
    # Apple's own smoothed estimate to full.
    #
    # AvgTimeToFull is normally minutes.
    # 65535 means "still estimating" / invalid.
    #

    avg_time_to_full = first_number(
        battery.get("AvgTimeToFull"),
        data.get("AvgTimeToFull"),
    )

    if avg_time_to_full is not None:
        if avg_time_to_full <= 0 or avg_time_to_full >= 65535:
            avg_time_to_full = None

    #
    # Capacity/current based charging estimate.
    #

    def estimate_to_percent(target_percent):
        if not charging:
            return None

        if percent is not None and percent >= target_percent:
            return 0

        if (
            full_mah is not None
            and remaining_mah is not None
            and current_ma is not None
            and current_ma > 0
        ):
            target_mah = full_mah * target_percent / 100.0

            needed_mah = target_mah - remaining_mah

            if needed_mah <= 0:
                return 0

            return needed_mah / current_ma * 60.0

        #
        # Fallback: scale Apple's time-to-full estimate according
        # to SOC. This isn't as accurate because charging slows
        # near full, but it's much better than returning zero.
        #

        if avg_time_to_full is not None and percent is not None and percent < 100:
            fraction = (target_percent - percent) / (100 - percent)

            if fraction > 0:
                return avg_time_to_full * fraction

        return None

    #
    # Time to 80%
    #

    if percent is not None and percent >= 80:
        to80_text = "Reached"

    elif charging:
        to80 = estimate_to_percent(80)

        to80_text = format_minutes(
            to80,
            approximate=True,
        )

    elif external:
        to80_text = "Not charging"

    else:
        to80_text = "On battery"

    #
    # Time to 100%
    #
    # Prefer Apple's own smoothed gauge estimate.
    #

    if fully_charged or (percent is not None and percent >= 100):
        to100_text = "Full"

    elif charging:
        if avg_time_to_full is not None:
            to100_text = format_minutes(avg_time_to_full)

        elif pmset_eta is not None:
            to100_text = format_minutes(pmset_eta)

        else:
            to100_text = format_minutes(
                estimate_to_percent(100),
                approximate=True,
            )

    elif external:
        to100_text = "Not charging"

    else:
        to100_text = "On battery"

    #
    # Charge percentage
    #

    if percent is not None:
        charge_text = f"{int(round(percent))}%"
    else:
        charge_text = "--"

    #
    # Cycle count
    #

    if cycles is not None:
        cycles_text = str(int(cycles))
    else:
        cycles_text = "--"

    #
    # Power source
    #

    if fully_charged and external:
        source_text = "AC — full"

    elif external and charging:
        source_text = "AC — charging"

    elif external:
        source_text = "AC — not charging"

    else:
        source_text = "Battery"

    #
    # Update SketchyBar
    #

    set_rows(
        {
            "power": power_text,
            "energy": energy_text,
            "charge": charge_text,
            "to80": to80_text,
            "to100": to100_text,
            "current": current_text,
            "health": health_text,
            "cycles": cycles_text,
            "source": source_text,
        }
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
