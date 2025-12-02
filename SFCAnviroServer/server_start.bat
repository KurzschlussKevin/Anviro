@echo off
:: Setzt die Fenstergroesse fest (Breite 110, Hoehe 40), damit das Logo passt!
mode con cols=110 lines=40

:: 1. Wechselt in das Verzeichnis, in dem die Batch-Datei liegt
cd /d "%~dp0"

echo.
:: Zeigt das Logo aus der Datei an (wenn sie existiert)
if exist banner.txt (
    type banner.txt
) else (
    echo ANVIRO SERVER (banner.txt fehlt)
)

echo.
:: 2. Prueft, ob die virtuelle Umgebung (venv) existiert und fuehrt das Setup durch
if not exist venv\Scripts\activate.bat (
    echo.
    echo.
    echo [SETUP] Virtuelle Umgebung 'venv' wird erstellt...
    
    python -m venv venv || goto :python_error
    
    echo [SETUP] Umgebung erfolgreich erstellt.
    
    echo [SETUP] Installiere benoetigte Pakete aus requirements.txt...
    venv\Scripts\python.exe -m pip install --upgrade pip
    venv\Scripts\python.exe -m pip install -r requirements.txt || goto :pip_error
    
    echo [SETUP] Installation abgeschlossen.
    echo.
) else (
    echo [INFO] Virtuelle Umgebung 'venv' existiert bereits.
)

:: 3. Prüfen ob FastAPI Einstiegspunkt existiert
if not exist app\main.py (
    echo.
    echo [FEHLER] FastAPI Startdatei 'app\main.py' wurde nicht gefunden!
    echo Bitte prüfen, ob sich deine FastAPI-App unter app/main.py befindet.
    goto :pause_and_exit
)

:: 4. Startet den FastAPI-Server
echo.
echo [INFO] Starte FastAPI Server über Uvicorn...
echo ---------------------------------------------
CMD /K venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

goto :eof


:python_error
echo.
echo [FATALER FEHLER] Python-Befehl fehlgeschlagen. Ist Python im PATH verfuegbar?
goto :pause_and_exit

:pip_error
echo.
echo [FATALER FEHLER] Installation der Pakete fehlgeschlagen. Prüfe requirements.txt.
goto :pause_and_exit

:pause_and_exit
pause
