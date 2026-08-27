const fs = require("fs");
const path = require("path");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const ROOT = path.resolve(process.env.CNM_WORKDIR || PROJECT_ROOT);
const DATA_DIR = path.join(ROOT, "data");

const UF_REGIAO = {
  AC: "Norte",
  AL: "Nordeste",
  AM: "Norte",
  AP: "Norte",
  BA: "Nordeste",
  CE: "Nordeste",
  DF: "Centro-Oeste",
  ES: "Sudeste",
  GO: "Centro-Oeste",
  MA: "Nordeste",
  MG: "Sudeste",
  MS: "Centro-Oeste",
  MT: "Centro-Oeste",
  PA: "Norte",
  PB: "Nordeste",
  PE: "Nordeste",
  PI: "Nordeste",
  PR: "Sul",
  RJ: "Sudeste",
  RN: "Nordeste",
  RO: "Norte",
  RR: "Norte",
  RS: "Sul",
  SC: "Sul",
  SE: "Nordeste",
  SP: "Sudeste",
  TO: "Norte",
};

function readJson(file) {
  return JSON.parse(fs.readFileSync(path.join(DATA_DIR, file), "utf8"));
}

function csvEscape(value) {
  if (value === null || value === undefined) return "";
  const text = String(value);
  return /[",\n\r;]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function writeCsv(file, rows, columns) {
  const lines = [columns.join(";")];
  for (const row of rows) {
    lines.push(columns.map((column) => csvEscape(row[column])).join(";"));
  }
  fs.writeFileSync(path.join(DATA_DIR, file), `\ufeff${lines.join("\n")}\n`, "utf8");
}

function writeJson(file, rows) {
  fs.writeFileSync(path.join(DATA_DIR, file), `${JSON.stringify(rows, null, 2)}\n`, "utf8");
}

function normalizeText(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function areaColumn(area) {
  return `area_${String(area.id).padStart(2, "0")}_${normalizeText(area.nome).slice(0, 70)}`;
}

function inferFromRespostas(respostas) {
  const ids = new Set((respostas || []).map((r) => Number(r.alternativa_id)));
  return {
    natureza_juridica_inferida: ids.has(4)
      ? "Publico"
      : ids.has(5)
        ? "Privado"
        : ids.has(6)
          ? "Administrativo"
          : null,
    regido_lei_11107_2005_inferido: ids.has(1) ? "Sim" : ids.has(2) ? "Nao" : null,
    tipo_sede_inferido: ids.has(80) ? "Propria" : ids.has(81) ? "Alugada" : ids.has(82) ? "Cedida" : null,
  };
}

function municipioLabel(municipio) {
  if (!municipio) return null;
  return municipio.label || [municipio.nome, municipio.uf].filter(Boolean).join("/");
}

function baseConsorcio(detail, areaColumns) {
  const c = detail.consorcio || {};
  const sede = c.municipio_consorciado || {};
  const areas = Array.isArray(c.areas) ? c.areas : [];
  const municipios = Array.isArray(c.municipios) ? c.municipios : [];
  const areaIds = new Set(areas.map((a) => a.id));
  const municipioUfs = [...new Set(municipios.map((m) => m.uf).filter(Boolean))].sort();

  const row = {
    consorcio_uuid: c.uuid || detail.uuid || null,
    consorcio_id: c.id || null,
    consorcio_nome: c.nome || null,
    consorcio_sigla: c.sigla || null,
    consorcio_cnpj: c.cnpj || null,
    consorcio_site: c.site || null,
    consorcio_status: c.status || null,
    consorcio_situacao_cnpj: c.situacao_cnpj || null,
    consorcio_data_constituicao: c.data_constituicao || null,
    consorcio_area_atuacao: c.area_atuacao || null,
    consorcio_natureza_juridica: inferFromRespostas(c.respostas).natureza_juridica_inferida,
    consorcio_regido_lei_11107_2005: inferFromRespostas(c.respostas).regido_lei_11107_2005_inferido,
    consorcio_tipo_sede: inferFromRespostas(c.respostas).tipo_sede_inferido,
    sede_municipio_id: sede.id || null,
    sede_municipio_ibge: sede.ibge || null,
    sede_municipio_nome: sede.nome || null,
    sede_municipio_uf: sede.uf || null,
    sede_regiao: UF_REGIAO[sede.uf] || null,
    quantidade_municipios: municipios.length,
    quantidade_areas: new Set(areas.map((a) => a.id || a.nome)).size,
    populacao_atendida: c.populacao_atendida || null,
    abrangencia_territorial: c.abrangencia_territorial || null,
    municipios_ufs: municipioUfs.join("|"),
    municipios_labels: municipios.map(municipioLabel).filter(Boolean).join(" | "),
    municipios_ibge: municipios.map((m) => m.ibge).filter(Boolean).join("|"),
    areas_atuacao: [...new Set(areas.map((a) => a.nome).filter(Boolean))].join(" | "),
    areas_atuacao_ids: [...new Set(areas.map((a) => a.id).filter(Boolean))].join("|"),
    estatuto_url: c.estatuto || null,
    protocolo_intencoes_url: c.protocolo_intencoes || null,
    observacoes: c.observacoes || null,
  };

  for (const area of areaColumns) {
    row[area.column] = areaIds.has(area.id) ? 1 : 0;
  }

  return row;
}

function main() {
  const completos = readJson("consorcios_completos.json");
  const vinculos = readJson("municipio_consorcio.json");

  const areasById = new Map();
  for (const detail of completos) {
    for (const area of detail.consorcio?.areas || []) {
      if (area.id && area.nome) areasById.set(area.id, { id: area.id, nome: area.nome });
    }
  }

  const areaColumns = [...areasById.values()]
    .sort((a, b) => a.id - b.id)
    .map((area) => ({ ...area, column: areaColumn(area) }));

  const consorcioRows = completos.map((detail) => baseConsorcio(detail, areaColumns));
  const byUuid = new Map(consorcioRows.map((row) => [row.consorcio_uuid, row]));

  const consorcioColumns = [
    "consorcio_uuid",
    "consorcio_id",
    "consorcio_nome",
    "consorcio_sigla",
    "consorcio_cnpj",
    "consorcio_site",
    "consorcio_status",
    "consorcio_situacao_cnpj",
    "consorcio_data_constituicao",
    "consorcio_area_atuacao",
    "consorcio_natureza_juridica",
    "consorcio_regido_lei_11107_2005",
    "consorcio_tipo_sede",
    "sede_municipio_id",
    "sede_municipio_ibge",
    "sede_municipio_nome",
    "sede_municipio_uf",
    "sede_regiao",
    "quantidade_municipios",
    "quantidade_areas",
    "populacao_atendida",
    "abrangencia_territorial",
    "municipios_ufs",
    "municipios_labels",
    "municipios_ibge",
    "areas_atuacao",
    "areas_atuacao_ids",
    "estatuto_url",
    "protocolo_intencoes_url",
    "observacoes",
    ...areaColumns.map((a) => a.column),
  ];

  const unifiedRows = vinculos.map((vinculo) => {
    const base = byUuid.get(vinculo.consorcio_uuid) || {};
    const row = {};
    for (const column of consorcioColumns) {
      if (!["municipios_labels", "municipios_ibge"].includes(column)) row[column] = base[column] ?? null;
    }
    row.municipio_id = vinculo.municipio_id;
    row.municipio_ibge = vinculo.municipio_ibge;
    row.municipio_nome = vinculo.municipio_nome;
    row.municipio_uf = vinculo.municipio_uf;
    row.municipio_regiao = UF_REGIAO[vinculo.municipio_uf] || null;
    return row;
  });

  const unifiedColumns = consorcioColumns
    .filter((column) => !["municipios_labels", "municipios_ibge"].includes(column))
    .concat(["municipio_id", "municipio_ibge", "municipio_nome", "municipio_uf", "municipio_regiao"]);

  writeCsv("base_unificada_consorcios.csv", consorcioRows, consorcioColumns);
  writeJson("base_unificada_consorcios.json", consorcioRows);
  writeCsv("base_unificada_municipio_consorcio.csv", unifiedRows, unifiedColumns);
  writeJson("base_unificada_municipio_consorcio.json", unifiedRows);
  writeCsv("dicionario_areas_pivot.csv", areaColumns, ["id", "nome", "column"]);
  writeJson("dicionario_areas_pivot.json", areaColumns);

  console.log(
    JSON.stringify(
      {
        consorcios: consorcioRows.length,
        vinculos_unificados: unifiedRows.length,
        areas_pivotadas: areaColumns.length,
        arquivos: [
          "data/base_unificada_consorcios.csv",
          "data/base_unificada_municipio_consorcio.csv",
          "data/dicionario_areas_pivot.csv",
        ],
      },
      null,
      2,
    ),
  );
}

main();
