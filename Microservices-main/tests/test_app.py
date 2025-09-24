import pytest

from app import create_app


@pytest.fixture()
def app():
    application = create_app()
    application.config.update({
        "TESTING": True,
    })
    return application


@pytest.fixture()
def client(app):
    return app.test_client()


def test_get_users(client):
    response = client.get("/users")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    assert {"id", "name"}.issubset(set(data[0].keys()))


def test_get_user_found(client):
    response = client.get("/users/1")
    assert response.status_code == 200
    assert response.get_json()["id"] == 1


def test_get_user_not_found(client):
    response = client.get("/users/9999")
    assert response.status_code == 404
    assert response.get_json()["message"] == "User not found"


def test_get_products(client):
    response = client.get("/products")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)


def test_get_product_not_found(client):
    response = client.get("/products/9999")
    assert response.status_code == 404
    assert response.get_json()["message"] == "Product not found"


