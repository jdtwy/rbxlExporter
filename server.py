# rbxlExporter created by Typhoon
# Requires corresponding Roblox plugin to receive and parse json data

from flask import Flask, request, jsonify
import os, shutil

app = Flask(__name__)

@app.route('/save', methods=['POST'])

def save():
    data = request.get_json()

    files = data.get("files", [])
    if os.path.isdir("src"):
        shutil.rmtree("src")

    for file in files:
        path = os.path.join("src", *file["path"])

        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(file["content"])
        
        print(f"Saved {path}")

    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(port=3000)