import argparse
import os
import pathlib
import subprocess
import sys
import urllib.parse


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="scp-upload",
        description="Upload files to Kiwix server",
    )

    parser.add_argument(
        "--src", required=True, help="filepath to be uploaded", dest="src_path"
    )

    parser.add_argument(
        "--dest",
        required=True,
        help="destination as user@host[:port]/folder/",
        dest="dest",
    )

    parser.add_argument(
        "--ssh-key",
        required=False,
        help="filepath to the private key to use for upload",
        default=os.getenv("KIWIX_FILE_UPLOAD_SSH_KEY_PATH", ""),
        dest="ssh_key",
    )

    args = parser.parse_args()

    ssh_path = (
        pathlib.Path(args.ssh_key or os.getenv("SSH_KEY", "")).expanduser().resolve()
    )
    src_path = pathlib.Path(args.src_path).expanduser().resolve()
    dest = urllib.parse.urlparse(f"ssh://{args.dest}")
    dest_path = pathlib.Path(dest.path)

    if not src_path.exists() or not ssh_path.is_file():
        print(f"Source file “{src_path}” missing")
        return 1

    if not ssh_path.exists() or not ssh_path.is_file():
        print(f"SSH Key “{ssh_path}” missing")
        return 1

    if not dest_path or dest_path == pathlib.Path("") or dest_path == pathlib.Path("/"):
        print(f"Must upload in a subfoler, not “{dest_path}”")
        return 1

    return upload(
        src_path=src_path, host=dest.netloc, dest_path=dest_path, ssh_path=ssh_path
    )


def upload(
    src_path: pathlib.Path, host: str, dest_path: pathlib.Path, ssh_path: pathlib.Path
) -> int:
    if ":" in host:
        host, port = host.split(":", 1)
    else:
        port = "22"

    # sending SFTP mkdir command to the sftp interactive mode and not batch (-b) mode
    # as the latter would exit on any mkdir error while it is most likely
    # the first parts of the destination is already present and thus can't be created
    sftp_commands = "\n".join(
        [
            f"mkdir {part}"
            for part in list(reversed(dest_path.parents)) + [str(dest_path)]
        ]
    )
    command = [
        "sftp",
        "-i",
        str(ssh_path),
        "-P",
        port,
        "-o",
        "StrictHostKeyChecking=no",
        host,
    ]
    print(f"Creating dest path: {dest_path}")
    subprocess.run(command, input=sftp_commands, text=True, check=True)

    command = [
        "scp",
        "-c",
        "aes128-ctr",
        "-rp",
        "-P",
        port,
        "-i",
        str(ssh_path),
        "-o",
        "StrictHostKeyChecking=no",
        str(src_path),
        f"{host}:{dest_path}/",
    ]
    print(f"Sending archive with command {' '.join(command)}")
    subprocess.run(command, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
