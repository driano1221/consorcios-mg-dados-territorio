const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..', 'visuais_v1.js'), 'utf8');
const chart = source.slice(source.indexOf('function lineChart('), source.indexOf('\n\ndocument.querySelectorAll'));
const ctx = {
  blue: '#2980B9',
  fmt: (n, d = 0) => Number(n).toLocaleString('pt-BR', { minimumFractionDigits: d, maximumFractionDigits: d }),
  cash: n => `R$ ${n}`,
  txt: (x, y, value, opts = '') => `<text x="${x}" ${opts}>${value}</text>`,
  svg: (w, h, body) => body,
};
vm.runInNewContext(chart, ctx);
const ticks = svg => [...svg.matchAll(/<text x="56" text-anchor="end" font-size="13">([^<]+)<\/text>/g)].map(m => m[1]);

const payments = ctx.lineChart([{ ano: 2014, valor: 13701 }, { ano: 2021, valor: 0 }], 'valor', 'CIS/UBA');
assert.deepEqual(ticks(payments), ['0', '4', '8', '12', '16']);
assert.match(payments, /R\$ mil nominais/);
assert.match(payments, /13,7/);

const payers = ctx.lineChart([{ ano: 2014, pagadores: 1 }, { ano: 2021, pagadores: 0 }], 'pagadores', 'CIS/UBA', { money: false });
assert.deepEqual(ticks(payers), ['0', '1']);
assert.match(payers, /<text x="74" text-anchor="start" font-size="13" font-weight="700">1<\/text>/);

const large = ctx.lineChart([{ ano: 2021, valor: 620000000 }], 'valor', 'Consórcio maior');
assert.match(large, /R\$ milhões nominais/);
console.log('OK: valores pequenos em milhares, grandes em milhões e contagens inteiras sem rótulos duplicados.');
