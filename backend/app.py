from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    return "API DermaOne aktif"

@app.route("/predict", methods=["POST"])
def predict():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    return jsonify({
        "results": [
            {"label": "Acne", "confidence": 0.95}
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)