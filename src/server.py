# rbxlExporter created by Typhoon
# Requires corresponding Roblox plugin to receive and parse json data

from flask import Flask, request, jsonify
import os, shutil

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = Flask(__name__)

@app.route('/save', methods=['POST'])

def save():
    data = request.get_json()

    files = data.get("files", [])
    firstPass = data.get("first", False)

    if firstPass:
        srcPath = os.path.join(BASE_DIR, "src")
        if os.path.isdir(srcPath):
            shutil.rmtree(srcPath)
            print("Flushed old src directory")

    for file in files:
        path = os.path.join(BASE_DIR, "src", *file["path"])

        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(file["content"])
        
        print(f"Saved {path}")

    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(port=3000)