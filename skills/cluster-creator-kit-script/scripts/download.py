#!/usr/bin/env python3
"""Cluster Script APIの型定義ファイル(index.d.ts)をダウンロードして保存する"""

import argparse
import os
import sys
import urllib.error
import urllib.request

URL = "https://docs.cluster.mu/script/index.d.ts"
FILENAME = "cluster-script-index.d.ts"


def resolve_data_path(output_dir=""):
    """保存先パスを算出する (--output-dir 未指定時は $PWD 直下)"""
    return os.path.join(output_dir or os.getcwd(), FILENAME)


def download(dest_path):
    """index.d.tsをダウンロードして保存する"""
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            content = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Connection Error: {e.reason}", file=sys.stderr)
        sys.exit(1)

    with open(dest_path, "w", encoding="utf-8") as f:
        f.write(content)

    line_count = content.count("\n")
    print(f"Downloaded to {dest_path} ({line_count} lines)", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Download Cluster Script API type definitions (index.d.ts)"
    )
    parser.add_argument(
        "--output-dir", default="", help="output directory (default: $PWD)"
    )
    args = parser.parse_args()

    download(resolve_data_path(args.output_dir))


if __name__ == "__main__":
    main()
