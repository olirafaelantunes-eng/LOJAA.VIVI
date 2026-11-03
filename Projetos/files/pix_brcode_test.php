<?php
// Uso: php tests/pix_brcode_test.php
require __DIR__ . '/../lib/PixBrCode.php';
$falhas = 0;
function ok(bool $c, string $m): void { global $falhas; echo ($c ? "OK    " : "FALHA ") . $m . PHP_EOL; if (!$c) $falhas++; }
function lanca(callable $f): bool { try { $f(); } catch (InvalidArgumentException) { return true; } return false; }

ok(PixBrCode::crc16('123456789') === '29B1', 'CRC16-CCITT-FALSE vetor padrão 123456789 = 29B1');
$p = PixBrCode::build('11111111-2222-3333-4444-555555555555', 'Viviani Crepaldi', 'Ipatinga', 389.90, 'VC12345678');
ok(str_starts_with($p, '000201'), 'payload começa com 000201');
ok(str_contains($p, '010212'), 'iniciação 12 (uso único)');
ok(str_contains($p, 'br.gov.bcb.pix'), 'GUI br.gov.bcb.pix');
ok(str_contains($p, '5406389.90'), 'valor 389.90 no campo 54');
ok(str_contains($p, '5303986') && str_contains($p, '5802BR') && str_contains($p, '52040000'), 'moeda, país e MCC');
ok(str_contains($p, 'VIVIANI CREPALDI') && str_contains($p, 'IPATINGA'), 'nome e cidade sem acento, maiúsculos');
ok(str_contains($p, '0510VC12345678'), 'txid no 62/05');
ok(PixBrCode::verify($p), 'CRC fecha');
ok(!PixBrCode::verify(substr($p, 0, -1) . 'X'), 'CRC adulterado é rejeitado');
ok(lanca(fn() => PixBrCode::build('', 'A', 'B', 10, 'X1')), 'rejeita chave vazia');
ok(lanca(fn() => PixBrCode::build('k', str_repeat('A', 26), 'B', 10, 'X1')), 'rejeita nome longo');
ok(lanca(fn() => PixBrCode::build('k', 'A', str_repeat('B', 16), 10, 'X1')), 'rejeita cidade longa');
ok(lanca(fn() => PixBrCode::build('k', 'A', 'B', 0, 'X1')), 'rejeita valor zero');
ok(lanca(fn() => PixBrCode::build('k', 'A', 'B', -5, 'X1')), 'rejeita valor negativo');
ok(lanca(fn() => PixBrCode::build('k', 'A', 'B', 'abc', 'X1')), 'rejeita valor não numérico');
echo $falhas ? "\n$falhas falha(s)\n" : "\nTodos os testes passaram\n";
exit($falhas ? 1 : 0);
