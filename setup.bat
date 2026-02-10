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
call sadtalker_env\Scripts\activate

echo Updating pip...
python -m pip install --upgrade pip >nul

REM ---------------------------------
REM 3. Install exact locked libraries
REM ---------------------------------
if exist requirements_lock.txt (
    echo Installing exact library versions...
    pip install -r requirements_lock.txt
) else (
    echo ERROR: requirements_lock.txt not found!
    pause
    exit /b
)

REM ---------------------------------
REM 4. Clone SadTalker if missing
REM ---------------------------------
if not exist sadtalker (
    echo Cloning SadTalker repository...
    git clone https://github.com/OpenTalker/SadTalker.git sadtalker
)

REM ---------------------------------
REM 5. Download & extract models once
REM ---------------------------------
if not exist "sadtalker\checkpoints" (

    echo Installing gdown...
    python -c "import gdown" 2>nul || pip install gdown >nul

    echo Downloading SadTalker model ZIP...

    python -c "import gdown, os; os.makedirs('models', exist_ok=True); gdown.download('https://drive.google.com/uc?id=1gwWh45pF7aelNP_P78uDJL8Sycep-K7j', 'models/sadtalker_models.zip', quiet=False)"

    echo Extracting models...

    python -c "import zipfile, os; os.makedirs('sadtalker/checkpoints', exist_ok=True); zipfile.ZipFile('models/sadtalker_models.zip').extractall('sadtalker/checkpoints')"

    echo Model setup complete!
) else (
    echo Models already exist. Skipping download.
)

REM ---------------------------------
REM 6. Generate audio from text
REM ---------------------------------
cd code
python make_audio.py
cd ..

REM ---------------------------------
REM 7. Run SadTalker inference
REM ---------------------------------
cd sadtalker

python inference.py ^
 --driven_audio "..\code\output_audio.mp3" ^
 --source_image "..\code\person13.jpg" ^
 --result_dir "results" ^
 --still ^
 --preprocess full ^
 --enhancer gfpgan

cd ..

echo.
echo =====================================
echo   DONE! Check: sadtalker\results
echo =====================================
pause
