
import os
from flask import Flask
from app.routes.user_routes import user_blueprint
from app.routes.product_routes import product_blueprint
from app.routes.health_check import health_check_blueprint

def create_app():
    app = Flask(__name__)

    # Configure from environment
    app.config["ENV"] = os.getenv("FLASK_ENV", "production")
    app.config["LOG_LEVEL"] = os.getenv("LOG_LEVEL", "INFO")

    # Register blueprints
    app.register_blueprint(user_blueprint)
    app.register_blueprint(product_blueprint)
    app.register_blueprint(health_check_blueprint)
    
    return app
