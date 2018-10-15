import os
from flask import Flask, request, Response, render_template
import time

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World from Flask"

@app.route('/ca-api/v1/getcert/<domain>', methods=['GET'])
def generate_cert(domain):

    filename = domain + ".pem"

    #time.sleep(10)

    try:
        with open(filename, 'r') as myfile:
            data=myfile.read()
    except Exception:
        print("  Could not open " + filename)
        #print("Generating cert on the fly")
        #response = generate_cert()
        #return Response(response, mimetype='text/plain')
        return Response("Generating cert on the fly ...", status=418, mimetype='text/plain')

    response = data
    return Response(response, mimetype='text/plain')

if __name__ == "__main__":
    # Only for debugging while developing
    app.run(host='0.0.0.0', debug=True, port=80)

