<?php
declare(strict_types=1);

/** Gerador de BR Code Pix (EMV do Banco Central). Sem dependências. */
final class PixBrCode
{
    public static function build(string $chave, string $nome, string $cidade, float|string $valor, string $txid): string
    {
        $chave = trim($chave);
        if ($chave === '' || strlen($chave) > 77) {
            throw new InvalidArgumentException('Chave Pix vazia ou longa demais.');
        }
        $nome = self::limpar($nome);
        $cidade = self::limpar($cidade);
        if ($nome === '' || strlen($nome) > 25) {
            throw new InvalidArgumentException('Nome do recebedor inválido (máx. 25).');
        }
        if ($cidade === '' || strlen($cidade) > 15) {
            throw new InvalidArgumentException('Cidade inválida (máx. 15).');
        }
        if (!is_numeric($valor) || (float)$valor <= 0 || (float)$valor > 999999.99) {
            throw new InvalidArgumentException('Valor inválido.');
        }
        $txid = preg_replace('/[^A-Za-z0-9]/', '', $txid) ?? '';
        if ($txid === '' || strlen($txid) > 25) {
            throw new InvalidArgumentException('txid inválido (A-Z0-9, máx. 25).');
        }

        $mai = self::f('00', 'br.gov.bcb.pix') . self::f('01', $chave);
        $p  = self::f('00', '01')
            . self::f('01', '12')              // uso único
            . self::f('26', $mai)
            . self::f('52', '0000')
            . self::f('53', '986')
            . self::f('54', number_format((float)$valor, 2, '.', ''))
            . self::f('58', 'BR')
            . self::f('59', $nome)
            . self::f('60', $cidade)
            . self::f('62', self::f('05', strtoupper($txid)))
            . '6304';
        return $p . self::crc16($p);
    }

    public static function crc16(string $s): string
    {
        $crc = 0xFFFF;
        for ($i = 0, $n = strlen($s); $i < $n; $i++) {
            $crc ^= ord($s[$i]) << 8;
            for ($j = 0; $j < 8; $j++) {
                $crc = ($crc & 0x8000) ? (($crc << 1) ^ 0x1021) : ($crc << 1);
                $crc &= 0xFFFF;
            }
        }
        return strtoupper(str_pad(dechex($crc), 4, '0', STR_PAD_LEFT));
    }

    public static function verify(string $payload): bool
    {
        return strlen($payload) > 8 && self::crc16(substr($payload, 0, -4)) === substr($payload, -4);
    }

    private static function f(string $id, string $v): string
    {
        return $id . str_pad((string)strlen($v), 2, '0', STR_PAD_LEFT) . $v;
    }

    private static function limpar(string $s): string
    {
        $t = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $s);
        $t = $t === false ? $s : $t;
        $t = preg_replace('/[^A-Za-z0-9 ]/', '', $t) ?? '';
        return strtoupper(trim($t));
    }
}
