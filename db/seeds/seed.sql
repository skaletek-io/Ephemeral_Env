-- Runs automatically on first Postgres start.
-- Includes schema creation so first-run seeding works before backend starts.
-- Safe to re-run.

CREATE TABLE IF NOT EXISTS users (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  email      VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(255)   NOT NULL,
  price      NUMERIC(10, 2) NOT NULL DEFAULT 0,
  stock      INTEGER        NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

INSERT INTO users (name, email)
SELECT v.name, v.email
FROM (VALUES
  ('Alice Martin',   'alice@test.com'),
  ('Bob Dupont',     'bob@test.com'),
  ('Carol Nguyen',   'carol@test.com'),
  ('David Leblanc',  'david@test.com'),
  ('Eva Tremblay',   'eva@test.com')
) AS v(name, email)
WHERE NOT EXISTS (
  SELECT 1 FROM users u WHERE u.email = v.email
);

INSERT INTO products (name, price, stock)
SELECT v.name, v.price, v.stock
FROM (VALUES
  ('Widget Pro',   29.99::numeric, 100),
  ('Widget Basic',  9.99::numeric, 500),
  ('Gadget X',     49.99::numeric,  50),
  ('Starter Kit',  19.99::numeric, 200),
  ('Premium Pack', 99.99::numeric,  20)
) AS v(name, price, stock)
WHERE NOT EXISTS (
  SELECT 1 FROM products p WHERE p.name = v.name
);
