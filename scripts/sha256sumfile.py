#!/usr/bin/env python3

import os
import sys
import hashlib
import argparse
from concurrent import futures
from tqdm import tqdm

DEFAULT_NUM_THREADS = 4

def verify_sha256_checksum(file_path, expected_checksum):
    with open(file_path, 'rb') as file:
        content = file.read()
        calculated_checksum = hashlib.sha256(content).hexdigest()
        return calculated_checksum == expected_checksum

def verify_file(sha256sums_file, expected_checksum, file_name):
    base_dir = os.path.dirname(sha256sums_file)
    file_path = os.path.join(base_dir, file_name)
    if verify_sha256_checksum(file_path, expected_checksum):
        return f"Checksum verified: {file_name}"
    else:
        return f"Checksum verification failed: {file_name}"

def verify_sha256sums_file(sha256sums_file, num_threads=DEFAULT_NUM_THREADS):
    results = []
    with open(sha256sums_file, 'r') as file:
        with futures.ThreadPoolExecutor(max_workers=num_threads) as executor:
            for line in file:
                expected_checksum, file_name = line.strip().split(' ', 1)
                future = executor.submit(verify_file, sha256sums_file, expected_checksum, file_name)
                results.append(future)

            with tqdm(total=len(results)) as pbar:
                for future in futures.as_completed(results):
                    result = future.result()
                    print(result)
                    pbar.update(1)

def main():
    parser = argparse.ArgumentParser(description='Verify SHA256 checksums from a file.')
    parser.add_argument('sha256sums_file', help='Path to the SHA256 file')
    parser.add_argument('--threads', type=int, default=DEFAULT_NUM_THREADS,
                        help='Number of threads for parallel verification (default: 4)')

    args = parser.parse_args()

    sha256sums_file = args.sha256sums_file
    num_threads = args.threads

    if not os.path.isfile(sha256sums_file):
        print(f"Error: The provided SHA256 file '{sha256sums_file}' does not exist.")
        sys.exit(1)

    verify_sha256sums_file(sha256sums_file, num_threads)

if __name__ == '__main__':
    main()

