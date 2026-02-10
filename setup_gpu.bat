@echo off
echo =====================================
echo     SadTalker One-Click Setup
echo =====================================

cd /d %~dp0

REM ---------------------------------
REM 0. Clone main repo if missing
REM ---------------------------------
if not exist SadtalkerLipSync (
    echo Cloning project repository...
    git clone https://github.com/SDP-Grisa/SadtalkerLipSync.git
)

cd SadtalkerLipSync

REM ---------------------------------
REM 1. Create Python 3.10 virtual env
REM ---------------------------------
if not exist sadtalker_env (
    echo Creating virtual environment...
    py -3.10 -m venv sadtalker_env
)

REM ---------------------------------
REM 2. Activate environment
REM ---------------------------------
call sadtalker_env\Scripts\activate.bat

REM Verify activation
echo.
echo Verifying virtual environment...
where python
python --version

echo.
echo Updating pip...
python.exe -m pip install --upgrade pip

REM ---------------------------------
REM 3. Detect GPU BEFORE installing
REM ---------------------------------
echo.
echo ===================================
echo Checking for NVIDIA GPU...
echo ===================================

python.exe -c "import subprocess; subprocess.run(['nvidia-smi'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)" 2>nul
if %errorlevel% equ 0 (
    echo [OK] NVIDIA GPU detected!
    set USE_GPU=1
    set DEVICE=cuda
) else (
    echo [INFO] No NVIDIA GPU detected. Will use CPU.
    set USE_GPU=0
    set DEVICE=cpu
)

REM ---------------------------------
REM 4. Install dependencies based on GPU
REM ---------------------------------
echo.
if %USE_GPU%==1 (
    echo Installing CUDA-enabled packages...
    if exist requirements_gpu.txt (
        python.exe -m pip install -r requirements_gpu.txt
    ) else (
        echo ERROR: requirements_gpu.txt not found!
        pause
        exit /b
    )
) else (
    echo Installing CPU-only packages...
    if exist requirements_lock.txt (
        REM Create CPU version by removing CUDA components
        python.exe -m pip install -r requirements_lock.txt
    ) else (
        echo ERROR: requirements_lock.txt not found!
        pause
        exit /b
    )
)

REM ---------------------------------
REM 5. Verify installation
REM ---------------------------------
echo.
echo ===================================
echo Verifying installation...
echo ===================================
python.exe -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"CPU-only\"}'); print(f'Device count: {torch.cuda.device_count() if torch.cuda.is_available() else 0}')"
python.exe -c "import cv2; print(f'OpenCV: {cv2.__version__}')"
python.exe -c "import gradio; print(f'Gradio: {gradio.__version__}')"
echo.

REM ---------------------------------
REM 6. Clone SadTalker if missing
REM ---------------------------------
if not exist sadtalker (
    echo Cloning SadTalker repository...
    git clone https://github.com/OpenTalker/SadTalker.git sadtalker
)

REM ---------------------------------
REM 7. Download & extract models once
REM ---------------------------------
if not exist "sadtalker\checkpoints" (
    echo.
    echo Installing gdown...
    python.exe -m pip install gdown

    echo Downloading SadTalker model ZIP...
    python.exe -c "import gdown, os; os.makedirs('models', exist_ok=True); gdown.download('https://drive.google.com/uc?id=1gwWh45pF7aelNP_P78uDJL8Sycep-K7j', 'models/sadtalker_models.zip', quiet=False)"

    echo Extracting models...
    python.exe -c "import zipfile, os; os.makedirs('sadtalker/checkpoints', exist_ok=True); zipfile.ZipFile('models/sadtalker_models.zip').extractall('sadtalker/checkpoints')"

    echo Model setup complete!
) else (
    echo Models already exist. Skipping download.
)

REM ---------------------------------
REM 8. Generate audio from text
REM ---------------------------------
echo.
echo ===================================
echo Generating audio from text...
echo ===================================
cd code
python.exe make_audio.py
cd ..

REM ---------------------------------
REM 9. Run SadTalker inference
REM ---------------------------------
echo.
echo ===================================
echo Running SadTalker inference...
echo ===================================
if %USE_GPU%==1 (
    echo Using GPU acceleration (CUDA)
) else (
    echo Using CPU (this may be slow)
)

cd sadtalker
python.exe inference.py ^
    --driven_audio "..\code\output_audio.mp3" ^
    --source_image "..\code\person10.jpg" ^
    --result_dir "results" ^
    --still ^
    --preprocess full ^
    --enhancer gfpgan ^
    --device %DEVICE%
cd ..

echo.
echo ===================================
echo   DONE! Check: sadtalker\results
echo ===================================
echo.
if %USE_GPU%==1 (
    echo [INFO] Processing completed using GPU
) else (
    echo [INFO] Processing completed using CPU
)
pause