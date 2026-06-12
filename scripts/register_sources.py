#!/usr/bin/env python3
"""Registers the CityFit source tree in project.pbxproj (Xcode 14 format),
removes the deleted ContentView.swift, sets the deployment target to 16.0,
and adds the required Info.plist usage-description keys."""

import hashlib
import os
import re

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBXPROJ = os.path.join(PROJECT_DIR, "CityFitMapTest.xcodeproj", "project.pbxproj")
APP_DIR = os.path.join(PROJECT_DIR, "CityFitMapTest")
APP_GROUP_ID = "CB44AA9E2FD8044100D3D7D7"

TOP_FOLDERS = ["Models", "ViewModels", "Views", "Services", "Utils"]


def uid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def main() -> None:
    with open(PBXPROJ) as f:
        text = f.read()

    # --- Drop ContentView.swift references ---
    text = "\n".join(line for line in text.split("\n") if "ContentView.swift" not in line)

    # --- Collect source files and build group tree ---
    build_files, file_refs, group_defs = [], [], []
    sources_entries, top_group_ids = [], []

    def process_dir(rel_dir: str) -> str:
        """Creates a PBXGroup for rel_dir (relative to APP_DIR), returns its UUID."""
        abs_dir = os.path.join(APP_DIR, rel_dir)
        group_id = uid("group:" + rel_dir)
        children = []
        for entry in sorted(os.listdir(abs_dir)):
            abs_entry = os.path.join(abs_dir, entry)
            rel_entry = os.path.join(rel_dir, entry)
            if os.path.isdir(abs_entry):
                child_id = process_dir(rel_entry)
                children.append(f"\t\t\t\t{child_id} /* {entry} */,")
            elif entry.endswith(".swift"):
                ref_id = uid("ref:" + rel_entry)
                build_id = uid("build:" + rel_entry)
                file_refs.append(
                    f"\t\t{ref_id} /* {entry} */ = {{isa = PBXFileReference; "
                    f"lastKnownFileType = sourcecode.swift; path = {entry}; "
                    f'sourceTree = "<group>"; }};'
                )
                build_files.append(
                    f"\t\t{build_id} /* {entry} in Sources */ = {{isa = PBXBuildFile; "
                    f"fileRef = {ref_id} /* {entry} */; }};"
                )
                sources_entries.append(f"\t\t\t\t{build_id} /* {entry} in Sources */,")
                children.append(f"\t\t\t\t{ref_id} /* {entry} */,")
        name = os.path.basename(rel_dir)
        group_defs.append(
            f"\t\t{group_id} /* {name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n" + "\n".join(children) + "\n"
            f"\t\t\t);\n"
            f"\t\t\tpath = {name};\n"
            f'\t\t\tsourceTree = "<group>";\n'
            f"\t\t}};"
        )
        return group_id

    for folder in TOP_FOLDERS:
        top_group_ids.append((folder, process_dir(folder)))

    # --- Insert sections ---
    text = text.replace(
        "/* End PBXBuildFile section */",
        "\n".join(build_files) + "\n/* End PBXBuildFile section */",
    )
    text = text.replace(
        "/* End PBXFileReference section */",
        "\n".join(file_refs) + "\n/* End PBXFileReference section */",
    )
    text = text.replace(
        "/* End PBXGroup section */",
        "\n".join(group_defs) + "\n/* End PBXGroup section */",
    )

    # New top-level folders inside the app group, after CityFitMapTestApp.swift
    anchor = "CB44AA9F2FD8044100D3D7D7 /* CityFitMapTestApp.swift */,"
    folder_lines = "".join(
        f"\n\t\t\t\t{gid} /* {name} */," for name, gid in top_group_ids
    )
    text = text.replace(anchor, anchor + folder_lines)

    # Sources build phase
    anchor = "CB44AAA02FD8044100D3D7D7 /* CityFitMapTestApp.swift in Sources */,"
    text = text.replace(anchor, anchor + "\n" + "\n".join(sources_entries))

    # --- Deployment target & Info.plist keys ---
    text = text.replace(
        "IPHONEOS_DEPLOYMENT_TARGET = 16.4;", "IPHONEOS_DEPLOYMENT_TARGET = 16.0;"
    )
    plist_keys = (
        'INFOPLIST_KEY_NSCameraUsageDescription = "CityFit uses the camera to detect objects for photo missions.";\n'
        '\t\t\t\tINFOPLIST_KEY_NSHealthShareUsageDescription = "CityFit reads your step data from Apple Health.";\n'
        '\t\t\t\tINFOPLIST_KEY_NSHealthUpdateUsageDescription = "CityFit saves workout data to Apple Health after missions.";\n'
        '\t\t\t\tINFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "CityFit tracks your location during active missions.";\n'
        '\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "CityFit needs your location to show the map and nearby missions.";\n'
        '\t\t\t\tINFOPLIST_KEY_NSMotionUsageDescription = "CityFit uses motion sensors to detect your activity and count steps.";'
    )
    text = re.sub(
        r'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "[^"]*";',
        plist_keys,
        text,
    )

    with open(PBXPROJ, "w") as f:
        f.write(text)

    print(f"Registered {len(sources_entries)} source files, "
          f"{len(group_defs)} groups. Deployment target -> 16.0.")


if __name__ == "__main__":
    main()
