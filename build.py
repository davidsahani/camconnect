import os
import sys
import json
import logging
import shutil
import subprocess
from typing import Any

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s"
)


def get_version_from_pubspec(file_path: str) -> str:
    with open(file_path) as file:
        for line in file:
            if line.strip().startswith("version:"):
                return line.split(":")[1].strip()

    raise ValueError(f"Version not found in {os.path.split(file_path)[1]}")


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


def build_camconnect_mobile(project_dir: str, output_dir: str) -> int:
    release_dir = os.path.join(project_dir, "build\\app\\outputs\\flutter-apk")

    if os.path.exists(output_dir):
        logging.info("Cleaning previous build directory...")
        clean_dir(output_dir)

    logging.info("Building camconnect mobile...")
    status = subprocess.call(
        ["flutter", "build", "apk", "--release", "--split-per-abi"],
        cwd=project_dir, shell=True
    )

    if status != 0:
        logging.error("camconnect mobile build failed.")
        return status

    logging.info("Copying camconnect mobile files...")
    shutil.copytree(release_dir, output_dir, dirs_exist_ok=True)

    logging.info("Renaming camconnect apk files prefixes...")
    # rename the files to replace the "app" prefix to "camconnect".
    rename_files_in_directory(output_dir, "app", "camconnect")

    return status  # success.


def build_camconnect_desktop(project_dir: str, output_dir: str) -> int:
    release_dir = os.path.join(project_dir, "build\\windows\\x64\\runner\\Release")

    if os.path.exists(output_dir):
        logging.info("Cleaning previous build directory...")
        clean_dir(output_dir)

    logging.info("Running flutter clean camconnect desktop...")
    status = run_flutter_clean(project_dir)
    if status != 0:
        return status # don't continue if flutter clean failed.

    logging.info("Building camconnect desktop...")
    status = subprocess.call(
        ["flutter", "build", "windows", "--release"],
        cwd=project_dir, shell=True
    )

    if status != 0:
        logging.error("camconnect desktop build failed.")
        return status

    logging.info("Copying camconnect desktop files...")
    shutil.copytree(release_dir, output_dir, dirs_exist_ok=True)

    return status  # success.


def create_setup_installer(script_file: str, app_version: str) -> int:
    program_path = "C:\\Program Files (x86)"
    inno_setup_dir = [pathname for pathname in os.listdir(
        program_path) if pathname.lower().startswith("inno setup")
    ]
    if not inno_setup_dir:
        logging.error(
            f"Couldn't locate Inno Setup in '{program_path}' " +
            "Either it's not installed or is in alternate path.",
        )
        return 1
    iscc = os.path.join(program_path, inno_setup_dir[0], "ISCC.exe")
    if not os.path.exists(iscc):
        logging.error(
            "Couldn't locate Inno Setup Complier (ISCC.exe) " +
            f"in '{os.path.dirname(iscc)}'"
        )
        return 1

    logging.info("Creating setup installer...")
    # create setup installer using inno setup compiler.
    return subprocess.call([iscc, script_file, f"/DAppVersion={app_version}"])


def main() -> int:
    script_dir = os.path.dirname(__file__)
    output_dir = os.path.join(script_dir, "build")

    mobile_project_dir = os.path.join(script_dir, "camconnect")
    desktop_project_dir = os.path.join(script_dir, "camconnect-desktop")

    mobile_output_dir = os.path.join(output_dir, "camconnect-apk")
    desktop_output_dir = os.path.join(output_dir, "camconnect")

    option = " ".join(sys.argv[1:]).lower() if len(sys.argv) > 1 else "all"

    if option in ("clean mobile", "clean", "clean all"):
        logging.info("Running flutter clean camconnect mobile...")
        status = run_flutter_clean(mobile_project_dir)
        if status != 0:
            return status

    if option in ("clean desktop", "clean", "clean all"):
        logging.info("Running flutter clean camconnect desktop...")
        status = run_flutter_clean(desktop_project_dir)
        if status != 0:
            return status

    if option == "mobile" or option == "all":
        status = build_camconnect_mobile(mobile_project_dir, mobile_output_dir)
        if status != 0:
            return status

    if option == "desktop" or option == "all":
        status = build_camconnect_desktop(desktop_project_dir, desktop_output_dir)
        if status != 0:
            return status

        repo_url = "https://github.com/schellingb/UnityCapture.git"
        repo_name = repo_url.rsplit("/", maxsplit=1)[1].rstrip(".git")
        repo_dir = os.path.join(output_dir, repo_name)

        if not os.path.exists(repo_dir):
            logging.info(f"Cloning {repo_name} repository...")
            status = subprocess.call(["git", "clone", repo_url, repo_dir], shell=True)

            if status != 0:
                logging.error(f"Failed to clone {repo_name} repository.")
                return status

        logging.info(f"Copying {repo_name} files...")
        shutil.copytree(
            os.path.join(repo_dir, "Install"),
            os.path.join(desktop_output_dir, "filters")
        )

        app_version = get_version_from_pubspec(
            os.path.join(desktop_project_dir, "pubspec.yaml")
        )
        return create_setup_installer(os.path.join(script_dir, "setup.iss"), app_version)

    return 0  # success.


if __name__ == '__main__':
    sys.exit(main())
