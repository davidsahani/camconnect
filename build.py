import os
import sys
import json
import shutil
import subprocess
from typing import Any

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

CAMCONNECT_MOBILE_DIR = os.path.join(SCRIPT_DIR, "camconnect")
CAMCONNECT_DESKTOP_DIR = os.path.join(SCRIPT_DIR, "camconnect-desktop")

CAMCONNECT_MOBILE_BUILD_DIR = os.path.join(CAMCONNECT_MOBILE_DIR, "build\\app\\outputs\\flutter-apk")
CAMCONNECT_DESKTOP_BUILD_DIR = os.path.join(CAMCONNECT_DESKTOP_DIR, "build\\windows\\x64\\runner\\Release")

PROJECT_OUTPUT_DIR = os.path.join(SCRIPT_DIR, "build")  # where build files will be copied to.
CAMCONNECT_DESKTOP_OUTPUT_DIR = os.path.join(PROJECT_OUTPUT_DIR, "camconnect")


def copy_files(source_dir: str, destination_dir: str) -> None:
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    for dir_path in os.listdir(source_dir):
        curr_path = os.path.join(source_dir, dir_path)

        if os.path.isfile(curr_path):
            shutil.copy(curr_path, destination_dir)
            continue  # copy the file and continue.

        # walk through the directory and copy the files.
        for dirpath, _dirnames, filenames in os.walk(curr_path):
            for filename in filenames:
                source_path = os.path.join(dirpath, filename)
                relative_path = os.path.relpath(source_path, source_dir)
                destination_path = os.path.join(destination_dir, relative_path)
                os.makedirs(os.path.dirname(destination_path), exist_ok=True)
                shutil.copy(source_path, destination_path)


def rename_files_in_directory(directory: str, old_prefix: str, new_prefix: str) -> None:
    for filename in os.listdir(directory):
        if filename.startswith(old_prefix):
            old_path = os.path.join(directory, filename)
            new_filename = filename.replace(old_prefix, new_prefix, 1)
            new_path = os.path.join(directory, new_filename)
            os.rename(old_path, new_path)


def open_config(file_path: str) -> dict[str, Any]:
    with open(file_path) as file:
        config = json.load(file)
    return config


def clean_dir(directory: str) -> None:
    try:
        shutil.rmtree(directory)
    except OSError:  # may fail once.
        shutil.rmtree(directory)


def run_flutter_clean(cwd: str) -> int:
    return subprocess.call(["flutter", "clean"], cwd=cwd, shell=True)


def build_camconnect_mobile(version_name: str, version_code: int) -> int:
    return subprocess.call(["flutter", "build", "apk", "--release", "--split-per-abi",
            f"--build-name={version_name}", f"--build-number={version_code}"
        ], cwd=CAMCONNECT_MOBILE_DIR, shell=True
    )


def build_camconnect_desktop(version_name: str, version_code: int) -> int:
    return subprocess.call(["flutter", "build", "windows", "--release",
            f"--build-name={version_name}", f"--build-number={version_code}"
        ], cwd=CAMCONNECT_DESKTOP_DIR, shell=True
    )


def main() -> None:
    config = open_config(os.path.join(SCRIPT_DIR, "versions.json"))

    mobile_app_version: str = config["mobile"]["version"]
    mobile_app_version_code: int = config["mobile"]["version_code"]

    desktop_app_version: str = config["desktop"]["version"]
    desktop_app_version_code: int = config["desktop"]["version_code"]

    if os.path.exists(PROJECT_OUTPUT_DIR):
        print("Cleaning previous build directory...")
        clean_dir(PROJECT_OUTPUT_DIR)

    print("Running flutter clean...")
    status = run_flutter_clean(CAMCONNECT_MOBILE_DIR)
    if status != 0:
        return  # don't continue if flutter clean failed.

    status = run_flutter_clean(CAMCONNECT_DESKTOP_DIR)
    if status != 0:
        return  # don't continue if flutter clean failed.

    print("Building camconnect mobile...")
    status = build_camconnect_mobile(mobile_app_version, mobile_app_version_code)

    if status != 0:  # don't continue if mobile build failed.
        return print("camconnect mobile build failed.", file=sys.stderr)

    print("Copying camconnect mobile files...")
    copy_files(CAMCONNECT_MOBILE_BUILD_DIR, PROJECT_OUTPUT_DIR)
    # rename the files to replace the "app" prefix to "camconnect".
    rename_files_in_directory(PROJECT_OUTPUT_DIR, "app", "camconnect")

    print("Building camconnect desktop...")
    status = build_camconnect_desktop(desktop_app_version, desktop_app_version_code)

    if status != 0:  # don't continue if desktop build failed.
        return print("camconnect desktop build failed.", file=sys.stderr)

    print("Copying camconnect desktop files...")
    copy_files(CAMCONNECT_DESKTOP_BUILD_DIR, CAMCONNECT_DESKTOP_OUTPUT_DIR)

    print("Done building projects.")


if __name__ == '__main__':
    main()
