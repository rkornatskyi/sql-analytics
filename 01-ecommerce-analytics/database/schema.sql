
CREATE TABLE countries (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(100) NOT NULL
);


CREATE TABLE customers (
    id                  INTEGER AUTO_INCREMENT PRIMARY KEY,
    registration_date   DATETIME NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    country_id          INTEGER NOT NULL,
    CONSTRAINT FOREIGN KEY (country_id) REFERENCES countries(id)
);

CREATE TABLE categories (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    category_id     INTEGER NOT NULL,
    price           DECIMAL(10, 2) NOT NULL (CHECK price > 0),
    CONSTRAINT FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE orders (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    customer_id     INTEGER NOT NULL,
    order_date      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE order_items (
    id              INTEGER AUTO_INCREMENT PRIMARY KEY,
    order_id        INTEGER NOT NULL,
    product_id      INTEGER NOT NULL,
    quantity        INTEGER DEFAULT 1 (CHECK quantity > 0),
    CONSTRAINT FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT FOREIGN KEY (product_id) REFERENCES products(id)
);