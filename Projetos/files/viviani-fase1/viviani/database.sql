-- Viviani Crepaldi - esquema inicial (importar no phpMyAdmin). Não apaga dados.
CREATE DATABASE IF NOT EXISTS viviani_crepaldi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE viviani_crepaldi;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  whatsapp VARCHAR(20) NOT NULL DEFAULT '',
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','cliente') NOT NULL DEFAULT 'cliente',
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  must_change_password TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS password_resets (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL UNIQUE,
  sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  name VARCHAR(190) NOT NULL UNIQUE,
  description TEXT NULL,
  color_hex CHAR(7) NOT NULL DEFAULT '#E8E1D3',
  price DECIMAL(10,2) NOT NULL,
  promo_price DECIMAL(10,2) NULL,
  promo_label VARCHAR(40) NULL,
  promo_starts_at DATETIME NULL,
  promo_ends_at DATETIME NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS product_images (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  filename VARCHAR(120) NOT NULL,
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS settings (
  `key` VARCHAR(60) PRIMARY KEY,
  `value` TEXT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  customer_name VARCHAR(120) NOT NULL,
  customer_whatsapp VARCHAR(20) NOT NULL,
  payment_method ENUM('pix','parcelamento') NOT NULL,
  status ENUM('aguardando_pagamento','parcelamento_solicitado','pago','em_separacao','enviado','concluido','cancelado') NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  txid VARCHAR(25) NULL UNIQUE,
  pix_payload TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NULL,
  product_name VARCHAR(190) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS login_attempts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  ip VARCHAR(45) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (email, created_at), INDEX (ip, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity VARCHAR(40) NULL,
  entity_id INT UNSIGNED NULL,
  details TEXT NULL,
  ip VARCHAR(45) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed -------------------------------------------------------------
INSERT IGNORE INTO categories (name, sort_order) VALUES ('Vestidos',1),('Conjuntos',2),('Macacões',3);

INSERT IGNORE INTO products (category_id, name, color_hex, price) VALUES
((SELECT id FROM categories WHERE name='Vestidos'),  'Vestido Longo Alfaiataria Verde Oliva',     '#7C8B5D', 389.90),
((SELECT id FROM categories WHERE name='Conjuntos'), 'Conjunto Cropped + Saia Rendada Off-White', '#E8E1D3', 459.90),
((SELECT id FROM categories WHERE name='Macacões'),  'Macacão Alfaiataria Vinho',                 '#6E2A2A', 349.90),
((SELECT id FROM categories WHERE name='Vestidos'),  'Vestido Longo Bordado Vermelho',            '#B4472E', 429.90),
((SELECT id FROM categories WHERE name='Conjuntos'), 'Conjunto Linho Terracota',                  '#B5734A', 379.90),
((SELECT id FROM categories WHERE name='Vestidos'),  'Vestido Tricoline Floral Marfim',           '#D8CBAE', 399.90);

INSERT IGNORE INTO settings (`key`,`value`) VALUES
('store_name','Viviani Crepaldi'),('pix_receiver_name',''),('pix_city',''),('pix_key',''),
('whatsapp',''),('instagram',''),('facebook',''),('tiktok',''),('youtube',''),
('hero_eyebrow','Coleção Florescer'),
('hero_title','Vestir mulheres com autoempoderamento feminino.'),
('hero_text','Peças autorais feitas para você. Pague à vista no Pix ou peça o parcelamento pelo WhatsApp.');

-- Administrador: criado SEM senha utilizável. Rode `php tools/criar_admin.php`
-- para gerar a senha aleatória (bcrypt cost 12) e gravá-la em INSTALACAO.txt.
INSERT IGNORE INTO users (name,email,whatsapp,password_hash,role,status,must_change_password)
VALUES ('Administradora','admin@vivianicrepaldi.local','','!sem-senha-rode-tools-criar_admin','admin','active',1);
