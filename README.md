# rbxlExporter

This project combines a Roblox Studio plugin with a small http server written in Python. The plugin will dump your Roblox Studio project; the Python server will parse that data and reflect the Roblox Studio file structure on your pc.

- This project does not fully dump all information about every Instance. .instance files will only contain the ClassName of the Instance. Thus, this project is incapable of recompiling back into a Roblox Studio project file

- Roblox Folders are labeled as .f for clarity

- Scripts are fully dumped as .lua files

This project is intended to be an easy way to essentially "upload" a Roblox game to a version control system without having to go through the hassle of abstracting game scripting to an external IDE. The product of the application is inteded to be used as a read-only folder structure for documentation

# Dependencies

Python 3 - https://www.python.org/downloads/

Flask (Python module) - https://flask.palletsprojects.com/en/stable/

If you have python installed, you can install flask by running `pip install flask` in cmd

# How to Use

- Download the files
- Go to Roblox Studio -> Open a Game -> Plugins -> Plugins Folder
- Drag `ProjectExporter.rbxmx` into your plugins folder
- Put `server.py` into a folder of your choice
- Run `server.py`
- In Studio, under the Plugins tab, click "Export Project"

You should see "Export Success" in the Roblox Studio console. You should also see an src file created in the same directory as `server.py` which contains your new Roblox Studio file structure
