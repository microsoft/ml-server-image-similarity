PowerShell -Command "Set-ExecutionPolicy Unrestricted" >> "%tmp%\load_data.txt" 2>&1 
PowerShell C:\Solutions\ImageSimilarity\resources\ActionScripts\LoadImageData.ps1 >> "%tmp%\load_data.txt"  2>&1