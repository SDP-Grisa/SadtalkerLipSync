"""
Download and extract FFmpeg from gyan.dev
"""
import requests
import zipfile
import os
import shutil
import sys

def download_ffmpeg():
    url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
    zip_file = 'ffmpeg.zip'
    
    print("=" * 70)
    print("Downloading FFmpeg from gyan.dev...")
    print("=" * 70)
    
    try:
        # Download with progress
        print(f"Downloading from: {url}")
        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        if total_size == 0:
            print("Warning: Could not determine file size")
        else:
            print(f"File size: {total_size / 1024 / 1024:.1f} MB")
        
        print("Downloading...")
        
        downloaded = 0
        chunk_size = 8192
        
        with open(zip_file, 'wb') as f:
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        progress = (downloaded / total_size) * 100
                        print(f'\rProgress: {progress:.1f}% ({downloaded/1024/1024:.1f}MB / {total_size/1024/1024:.1f}MB)', end='')
        
        print('\n\nDownload complete!')
        
        # Verify zip file exists and has content
        if not os.path.exists(zip_file):
            print("ERROR: Downloaded file not found")
            return False
        
        file_size = os.path.getsize(zip_file)
        if file_size < 1000000:  # Less than 1MB is suspicious
            print(f"ERROR: Downloaded file seems too small ({file_size} bytes)")
            return False
        
        # Extract
        print("\nExtracting FFmpeg...")
        try:
            with zipfile.ZipFile(zip_file, 'r') as zf:
                zf.extractall('.')
        except zipfile.BadZipFile:
            print("ERROR: Downloaded file is not a valid zip file")
            return False
        
        # Find extracted folder (may be nested)
        extracted_folder = None
        for item in os.listdir('.'):
            if item.startswith('ffmpeg-') and os.path.isdir(item):
                extracted_folder = item
                break
        
        if not extracted_folder:
            print("ERROR: Could not find extracted folder")
            print("Contents of current directory:")
            for item in os.listdir('.'):
                print(f"  - {item}")
            return False
        
        print(f"Found extracted folder: {extracted_folder}")
        
        # Check for nested structure (common issue)
        bin_path = os.path.join(extracted_folder, 'bin')
        nested_bin_path = os.path.join(extracted_folder, extracted_folder, 'bin')
        
        actual_folder = extracted_folder
        
        # If bin is nested inside another folder with same name
        if not os.path.exists(bin_path) and os.path.exists(nested_bin_path):
            print(f"Detected nested folder structure, using inner folder")
            actual_folder = os.path.join(extracted_folder, extracted_folder)
        
        # Verify bin directory exists in the actual folder
        final_bin_path = os.path.join(actual_folder, 'bin')
        if not os.path.exists(final_bin_path):
            print(f"ERROR: bin directory not found in {actual_folder}")
            return False
        
        # Verify executables exist
        ffmpeg_in_extracted = os.path.join(final_bin_path, 'ffmpeg.exe')
        ffprobe_in_extracted = os.path.join(final_bin_path, 'ffprobe.exe')
        
        if not os.path.exists(ffmpeg_in_extracted):
            print(f"ERROR: ffmpeg.exe not found in {final_bin_path}")
            return False
        
        if not os.path.exists(ffprobe_in_extracted):
            print(f"ERROR: ffprobe.exe not found in {final_bin_path}")
            return False
        
        print(f"Found binaries in: {final_bin_path}")
        
        # Rename to 'ffmpeg'
        if os.path.exists('ffmpeg'):
            print("Removing old ffmpeg folder...")
            shutil.rmtree('ffmpeg')
        
        print(f"Moving {actual_folder} to ffmpeg...")
        shutil.move(actual_folder, 'ffmpeg')
        
        # Clean up outer folder if it was nested
        if actual_folder != extracted_folder and os.path.exists(extracted_folder):
            print(f"Cleaning up outer folder: {extracted_folder}")
            shutil.rmtree(extracted_folder)
        
        # Clean up zip file
        print("Cleaning up zip file...")
        os.remove(zip_file)
        
        print(f"\n✓ FFmpeg extracted to: {os.path.abspath('ffmpeg')}")
        print(f"✓ FFmpeg binary: {os.path.abspath('ffmpeg/bin/ffmpeg.exe')}")
        print(f"✓ FFprobe binary: {os.path.abspath('ffmpeg/bin/ffprobe.exe')}")
        
        # Final verify
        ffmpeg_exe = os.path.join('ffmpeg', 'bin', 'ffmpeg.exe')
        ffprobe_exe = os.path.join('ffmpeg', 'bin', 'ffprobe.exe')
        
        if os.path.exists(ffmpeg_exe) and os.path.exists(ffprobe_exe):
            print("\n✓✓✓ FFmpeg installation successful!")
            return True
        else:
            print("\n✗ FFmpeg binaries not found after extraction")
            print(f"  ffmpeg.exe exists: {os.path.exists(ffmpeg_exe)}")
            print(f"  ffprobe.exe exists: {os.path.exists(ffprobe_exe)}")
            return False
        
    except requests.exceptions.RequestException as e:
        print(f"\n✗ Network ERROR: {e}")
        print("Please check your internet connection")
        return False
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Current directory:", os.getcwd())
    success = download_ffmpeg()
    sys.exit(0 if success else 1)