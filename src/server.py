# rbxlExporter v1.1.1 created by Typhoon
# Requires corresponding Roblox plugin to receive and parse json data

from flask import Flask, request, jsonify
import json
import os, shutil

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CURRENT_VERSION = "1.1.1"

app = Flask(__name__)

def writefile(path, file):
    content = file["content"]

    if isinstance(content, dict):
        content = json.dumps(content, indent=2)

    os.makedirs(os.path.dirname(path), exist_ok=True)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
        print(f"Saved {path}")

@app.route('/save', methods=['POST'])
def save():
    data = request.get_json()

    files = data.get("files", [])
    firstPass = data.get("first", False)
    version = data.get("version", str)

    if firstPass:
        if CURRENT_VERSION == version:
            print("rbxlExporter version verified: " + CURRENT_VERSION)
        else:
            print("rbxlExporter Plugin and Server versions are desynced")
            print("Server Version: " + CURRENT_VERSION)
            print("Plugin Version: " + version)
            return jsonify({"status": "versionerror"}), 200

        srcPath = os.path.join(BASE_DIR, "src")
        if os.path.isdir(srcPath):
            shutil.rmtree(srcPath)
            print("Flushed old src directory")
        
        return jsonify({"status": "ok"}), 200

    for file in files:
        path = os.path.join(BASE_DIR, "src", *file["path"])
        writefile(path, file)

    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(port=3000)