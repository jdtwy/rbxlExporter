# rbxlExporter

This project combines a Roblox Studio plugin with a small http server written in Python. The plugin will dump your Roblox Studio project; the Python server will parse that data and reflect the Roblox Studio file structure on your pc

- As of version 1.1.0, all Roblox Instances/Objects will have their properties saved

- Roblox Folders are labeled as .f for clarity

- Scripts are fully dumped as .lua files

This project is intended to be an easy way to essentially "upload" a Roblox game to a version control system without having to go through the hassle of abstracting game scripting to an external IDE. The product of the application is inteded to be used as a read-only folder structure for documentation

# Dependencies

Python 3 - https://www.python.org/downloads/

Flask (Python module) - https://flask.palletsprojects.com/en/stable/

If you have python installed, you can install flask by running `pip install flask` in cmd

# How to Use

- Download the files (`rbxlExporter.rbxmx` and `server.py`) in the release tab
- Go to Roblox Studio -> Open a Game -> Plugins -> Plugins Folder
- Drag `rbxlExporter.rbxmx` into your plugins folder (You may have to refresh Roblox Studio or reload your game for it to appear)
- Put `server.py` into a folder of your choice
- Run `server.py`
- In Studio, under the Plugins tab, click "Export Project"

You should see "Export Success" in the Roblox Studio console. You should also see an src file created in the same directory as `server.py` which contains your new Roblox Studio file structure. Bigger projects take longer to serialise. No project should take longer than a minute to start creating files
