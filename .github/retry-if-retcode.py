#!/usr/bin/env python3

import argparse
import subprocess
import sys
import time


def run_command(
    max_attempts: int, retcode: int, sleep_seconds: int, command: str
) -> int:
    attempts = 0
    while True:
        ps = subprocess.run(command, check=False)
        attempts += 1

        # either suceeded or returned an unexpected exit-code, returning.
        if ps.returncode == 0 or ps.returncode != retcode:
            return ps.returncode

        if attempts >= max_attempts:
            print(f"Reached {max_attempts=}", flush=True)
            return ps.returncode

        print(
            f"Received retcode={ps.returncode} on attempt #{attempts}. "
            f"Retrying in {sleep_seconds}s.",
            flush=True,
        )
        if sleep_seconds:
            time.sleep(sleep_seconds)


def main():
    parser = argparse.ArgumentParser(
        prog="retry-if-retcode", epilog=r"/!\ Append your command after those args!"
    )

    parser.add_argument(
        "--retcode",
        required=True,
        help="Return code to retry when received",
        type=int,
    )

    parser.add_argument(
        "--attempts",
        required=False,
        help="Max number of attempts",
        type=int,
        default=10,
    )

    parser.add_argument(
        "--sleep",
        required=False,
        help="Nb. of seconds to sleep in-between retries",
        type=int,
        default=1,
    )

    args, command = parser.parse_known_args()
    if not command:
        print("You must supply a command to run")
        return 1

    return run_command(
        max_attempts=args.attempts,
        retcode=args.retcode,
        sleep_seconds=args.sleep,
        command=command,
    )


if __name__ == "__main__":
    sys.exit(main())
