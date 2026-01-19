"""
Flask Health Check API
A simple API demonstrating Cloud Run deployment with health checks and metadata endpoints.
"""

from flask import Flask, jsonify
import os
from datetime import datetime

# Initialize Flask application
app = Flask(__name__)

# Configuration from environment variables
PORT = int(os.getenv('PORT', 8080))
VERSION = os.getenv('VERSION', '1.0.0')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')


@app.route('/')
def home():
    """
    Welcome endpoint with current timestamp.
    Returns a JSON response with a welcome message and the current time.
    """
    return jsonify({
        'message': 'Welcome to GCP DevOps Demo',
        'timestamp': datetime.utcnow().isoformat(),
        'version': VERSION
    })


@app.route('/health')
def health():
    """
    Health check endpoint for monitoring.
    Cloud Run and load balancers use this to verify the service is running.
    """
    return jsonify({
        'status': 'healthy',
        'version': VERSION
    }), 200


@app.route('/info')
def info():
    """
    Metadata endpoint providing application information.
    Useful for debugging and verifying deployment configuration.
    """
    return jsonify({
        'app': 'gcp-devops-demo',
        'version': VERSION,
        'environment': ENVIRONMENT,
        'region': 'asia-east1',
        'python_version': '3.11',
        'timestamp': datetime.utcnow().isoformat()
    })


# Error handlers for better user experience
@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors with a JSON response."""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint does not exist'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors with a JSON response."""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred'
    }), 500


if __name__ == '__main__':
    # This is used only for local development
    # In production, Gunicorn is used as the WSGI server
    print(f"Starting Flask app on port {PORT}")
    print(f"Version: {VERSION}, Environment: {ENVIRONMENT}")
    app.run(host='0.0.0.0', port=PORT, debug=(ENVIRONMENT == 'development'))
