<?php
// Uso (CLI): php tools/criar_admin.php   -> define senha aleatória do admin e grava INSTALACAO.txt
declare(strict_types=1);
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
$env = parse_ini_file(__DIR__ . '/../.env') ?: [];
$pdo = new PDO(sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $env['DB_HOST'] ?? 'localhost', $env['DB_NAME'] ?? 'viviani_crepaldi'),
    $env['DB_USER'] ?? '', $env['DB_PASS'] ?? '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_EMULATE_PREPARES => false]);
$senha = rtrim(strtr(base64_encode(random_bytes(12)), '+/', 'Ax'), '=');
$hash = password_hash($senha, PASSWORD_BCRYPT, ['cost' => 12]);
$st = $pdo->prepare("UPDATE users SET password_hash=?, must_change_password=1 WHERE email='admin@vivianicrepaldi.local' AND role='admin'");
$st->execute([$hash]);
file_put_contents(__DIR__ . '/../INSTALACAO.txt', "Admin: admin@vivianicrepaldi.local\nSenha temporária: $senha\nTroca obrigatória no primeiro login. Apague este arquivo depois.\n");
chmod(__DIR__ . '/../INSTALACAO.txt', 0600);
echo "Senha gravada em INSTALACAO.txt\n";
