import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectDir = process.cwd();
const classDir = path.join(projectDir, "analises", "classificacao_politicas");
const outputDir = path.join(classDir, "outputs", "caderno_decisao_v0_3");
const outputPath = path.join(outputDir, "caderno_decisao_classificacao_v0_3.xlsx");
const preparedJson = path.join(outputDir, "casos_para_caderno.json");

if (!(await fs.stat(preparedJson).catch(() => null))) {
  throw new Error("Execute 05_preparar_caderno_decisao_classificacao.R antes deste builder.");
}
const cases = JSON.parse(await fs.readFile(preparedJson, "utf8"));

const groups = [
  "Provisoria coerente",
  "Provisoria cadastro IPEA",
  "Provisoria por nome",
  "Multifinalitario",
  "Sem area suficiente",
  "Filiais sem classificacao tematica",
];

const groupDescriptions = {
  "Provisoria coerente": "Area apoiada por MUNIC coerente, ou por coincidencia entre nome juridico e MUNIC. Ainda nao houve comprovacao documental individual.",
  "Provisoria cadastro IPEA": "Area herdada do cadastro IPEA com origem em arquivo. E uma hipotese de trabalho, nao uma confirmacao documental.",
  "Provisoria por nome": "Area inferida somente pelo nome ou razao social. Deve ser tratada como indicio.",
  Multifinalitario: "O nome ou cadastro informa perfil multifinalitario, mas nao permite atribuir automaticamente todas as areas de atuacao.",
  "Sem area suficiente": "As fontes disponiveis nao permitem classificar com seguranca. Exige estatuto, protocolo de intencoes ou fonte institucional.",
  "Filiais sem classificacao tematica": "Esta aba nao e a lista completa de matriz/filial. Reune apenas as duas filiais cuja area ainda nao pode ser atribuida antes da regra formal de raiz de CNPJ.",
};

const compactColumns = [
  ["cnpj_consorcio", "CNPJ"],
  ["sigla", "Sigla"],
  ["razao_social", "Razao social"],
  ["area_politica_final_v0_3", "Area atual"],
  ["fonte_principal_v0_3", "Fonte principal"],
  ["status_validacao_v0_3", "Status"],
  ["perfil_institucional_v0_3", "Perfil"],
  ["setores_cadastro_original", "Setor cadastro IPEA"],
  ["setores_munic_original", "Setores MUNIC brutos"],
  ["setores_munic_por_suporte", "Suporte MUNIC"],
  ["regra_recomendada_munic", "Regra MUNIC"],
  ["justificativa_v0_3", "Justificativa atual"],
];

const allColumns = [
  ["grupo_decisao", "Grupo de decisao"],
  ...compactColumns,
  ["areas_munic_auditadas", "Areas MUNIC padronizadas"],
  ["macroareas_munic_auditadas", "Macroareas MUNIC"],
  ["apoio_cadastro_ipea", "Apoio cadastro x MUNIC"],
  ["prioridade_revisao_munic", "Prioridade MUNIC"],
  ["decisao_documental", "Decisao documental anterior"],
  ["revisao_documental_justificativa", "Justificativa documental anterior"],
  ["fontes_v0_3", "Fontes v0.3"],
];

const workbook = Workbook.create();
const navy = "#163F59";
const blue = "#2C6687";
const lightBlue = "#EAF2F6";
const pale = "#F6F8FA";
const border = "#D3DEE5";
const green = "#E7F3E8";
const amber = "#FFF2CC";
const rose = "#FCE8E6";
const text = "#1F2933";

function colLetter(index) {
  let value = index;
  let result = "";
  while (value > 0) {
    const remainder = (value - 1) % 26;
    result = String.fromCharCode(65 + remainder) + result;
    value = Math.floor((value - 1) / 26);
  }
  return result;
}

function textValue(row, key) {
  const value = row[key];
  return value === null || value === undefined ? "" : String(value);
}

function setColumnWidth(sheet, colIndex, width) {
  const letter = colLetter(colIndex + 1);
  sheet.getRange(`${letter}1:${letter}${Math.max(20, cases.length + 5)}`).format.columnWidth = width;
}

function addTitle(sheet, title, subtitle, lastColumn) {
  const lastLetter = colLetter(lastColumn);
  sheet.getRange(`A1:${lastLetter}1`).merge();
  sheet.getRange("A1").values = [[title]];
  sheet.getRange("A1").format = {
    fill: navy,
    font: { bold: true, color: "#FFFFFF", size: 16 },
    verticalAlignment: "center",
  };
  sheet.getRange("A1").format.rowHeight = 28;
  sheet.getRange(`A2:${lastLetter}2`).merge();
  sheet.getRange("A2").values = [[subtitle]];
  sheet.getRange("A2").format = {
    fill: lightBlue,
    font: { color: text, italic: true, size: 10 },
    wrapText: true,
    verticalAlignment: "center",
  };
  sheet.getRange("A2").format.rowHeight = 34;
}

function addDecisionColumns(columns) {
  return [
    ...columns,
    ["parecer_usuario", "Parecer"],
    ["observacao_usuario", "Observacao"],
  ];
}

function buildCaseSheet(sheetName, title, subtitle, rows, columns, tableName) {
  const sheet = workbook.worksheets.add(sheetName);
  sheet.showGridLines = false;
  const renderedColumns = addDecisionColumns(columns);
  addTitle(sheet, title, subtitle, renderedColumns.length);

  const headerRow = 4;
  const firstDataRow = 5;
  const lastRow = firstDataRow + Math.max(rows.length - 1, 0);
  const headers = renderedColumns.map(([, label]) => label);
  sheet.getRange(`A${headerRow}:${colLetter(renderedColumns.length)}${headerRow}`).values = [headers];
  sheet.getRange(`A${headerRow}:${colLetter(renderedColumns.length)}${headerRow}`).format = {
    fill: blue,
    font: { bold: true, color: "#FFFFFF", size: 10 },
    wrapText: true,
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: navy },
  };
  sheet.getRange(`A${headerRow}:${colLetter(renderedColumns.length)}${headerRow}`).format.rowHeight = 32;

  const matrix = rows.map((row) => [
    ...columns.map(([key]) => textValue(row, key)),
    "",
    "",
  ]);
  if (matrix.length > 0) {
    sheet.getRange(`A${firstDataRow}:${colLetter(renderedColumns.length)}${lastRow}`).values = matrix;
    sheet.getRange(`A${firstDataRow}:${colLetter(renderedColumns.length)}${lastRow}`).format = {
      verticalAlignment: "top",
      wrapText: true,
      font: { color: text, size: 9 },
      borders: { preset: "insideHorizontal", style: "thin", color: border },
    };
    sheet.getRange(`A${firstDataRow}:${colLetter(renderedColumns.length)}${lastRow}`).format.rowHeight = 34;
    sheet.tables.add(`A${headerRow}:${colLetter(renderedColumns.length)}${lastRow}`, true, tableName);
    const decisionColumn = colLetter(renderedColumns.length - 1);
    sheet.getRange(`${decisionColumn}${firstDataRow}:${decisionColumn}${lastRow}`).dataValidation = {
      rule: {
        type: "list",
        values: ["Manter", "Priorizar pesquisa", "Reclassificar", "Excluir", "Nao revisar agora"],
      },
    };
    sheet.getRange(`${decisionColumn}${firstDataRow}:${decisionColumn}${lastRow}`).conditionalFormats.add("containsText", {
      text: "Priorizar pesquisa",
      format: { fill: amber, font: { color: text } },
    });
    sheet.getRange(`${decisionColumn}${firstDataRow}:${decisionColumn}${lastRow}`).conditionalFormats.add("containsText", {
      text: "Reclassificar",
      format: { fill: rose, font: { color: text } },
    });
    sheet.getRange(`${decisionColumn}${firstDataRow}:${decisionColumn}${lastRow}`).conditionalFormats.add("containsText", {
      text: "Manter",
      format: { fill: green, font: { color: text } },
    });
  }

  sheet.freezePanes.freezeRows(headerRow);
  setColumnWidth(sheet, 0, 16);
  setColumnWidth(sheet, 1, 18);
  setColumnWidth(sheet, 2, 42);
  for (let col = 3; col < renderedColumns.length; col += 1) setColumnWidth(sheet, col, 22);
  setColumnWidth(sheet, renderedColumns.length - 3, 42);
  setColumnWidth(sheet, renderedColumns.length - 2, 20);
  setColumnWidth(sheet, renderedColumns.length - 1, 38);
  return sheet;
}

const allSheet = buildCaseSheet(
  "Todos os casos",
  "Caderno de decisao: classificacao de politicas publicas",
  "Casos sem confirmacao documental plena. Leia sempre area atual + fonte principal + status; use Parecer apenas para registrar sua decisao.",
  cases,
  allColumns,
  "TodosOsCasos"
);

for (let index = 0; index < groups.length; index += 1) {
  const group = groups[index];
  const rows = cases.filter((row) => row.grupo_decisao === group);
  buildCaseSheet(
    `${index + 1}. ${group}`.slice(0, 31),
    group,
    groupDescriptions[group],
    rows,
    compactColumns,
    `Grupo${index + 1}`
  );
}

const guide = workbook.worksheets.add("Leia primeiro");
guide.showGridLines = false;
addTitle(
  guide,
  "Como usar este caderno",
  "Este arquivo nao altera a base. Ele organiza as decisoes que ainda dependem de evidencia adicional ou escolha metodologica.",
  5
);
guide.getRange("A4:E4").values = [["Grupo", "Quantidade", "O que significa", "O que decidir", "Prioridade sugerida"]];
guide.getRange("A4:E4").format = {
  fill: blue,
  font: { bold: true, color: "#FFFFFF" },
  wrapText: true,
};
const summaryRows = [
  ["Provisoria coerente", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"provisoria_coerente\")", groupDescriptions["Provisoria coerente"], "Manter por enquanto ou priorizar documento.", "Media"],
  ["Provisoria cadastro IPEA", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"provisoria_cadastro\")", groupDescriptions["Provisoria cadastro IPEA"], "Confirmar se o cadastro e suficiente para o uso analitico.", "Media"],
  ["Provisoria por nome", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"provisoria_nome\")", groupDescriptions["Provisoria por nome"], "Manter como indicio ou buscar documento quando o caso for relevante.", "Media"],
  ["Multifinalitario", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"provisoria_multifinalitario\")", groupDescriptions.Multifinalitario, "Decidir se ficam como perfil ou se entram em pesquisa documental por lotes.", "Alta"],
  ["Sem area suficiente", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"pendente_documento\")", groupDescriptions["Sem area suficiente"], "Buscar estatuto, protocolo de intencoes ou portal institucional.", "Alta"],
  ["Filiais sem classificacao tematica", "=COUNTIF('Todos os casos'!$H$5:$H$192,\"aguardar_matriz_filial\")", groupDescriptions["Filiais sem classificacao tematica"], "Definir regra de agregacao antes de classificar e somar valores.", "Alta"],
];
guide.getRange("A5:E10").values = summaryRows.map(([a, , c, d, e]) => [a, "", c, d, e]);
guide.getRange("B5:B10").formulas = summaryRows.map(([, formula]) => [formula]);
guide.getRange("A5:E10").format = {
  wrapText: true,
  verticalAlignment: "top",
  font: { color: text, size: 10 },
  borders: { preset: "insideHorizontal", style: "thin", color: border },
};
guide.getRange("A5:E10").format.rowHeight = 45;
guide.getRange("A12:E12").merge();
guide.getRange("A12").values = [["Leitura de uma linha: area atual = hipotese de classificacao; fonte principal = de onde veio; status = nivel de confianca. Setores MUNIC sao evidencia de vinculos municipio-consorcio, nao uma lista automatica de todas as areas do CNPJ."]];
guide.getRange("A12").format = { fill: lightBlue, wrapText: true, font: { color: text, italic: true } };
guide.getRange("A12").format.rowHeight = 42;
guide.getRange("A14:E14").merge();
guide.getRange("A14").values = [["Campos editaveis: em cada aba, selecione um Parecer e registre o motivo em Observacao. Isso cria uma trilha de decisao sem alterar as evidencias originais."]];
guide.getRange("A14").format = { fill: pale, wrapText: true, font: { color: text } };
guide.getRange("A14").format.rowHeight = 32;
guide.getRange("A4:E10").format.borders = { preset: "outside", style: "thin", color: border };
guide.freezePanes.freezeRows(4);
setColumnWidth(guide, 0, 27);
setColumnWidth(guide, 1, 14);
setColumnWidth(guide, 2, 55);
setColumnWidth(guide, 3, 55);
setColumnWidth(guide, 4, 18);

await fs.mkdir(outputDir, { recursive: true });
const preview = await workbook.render({ sheetName: "Leia primeiro", range: "A1:E14", scale: 1.5, format: "png" });
await fs.writeFile(path.join(outputDir, "preview_leia_primeiro.png"), new Uint8Array(await preview.arrayBuffer()));
const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(outputPath);

console.log(JSON.stringify({ outputPath, totalCases: cases.length, groups: Object.fromEntries(groups.map((group) => [group, cases.filter((row) => row.grupo_decisao === group).length])) }));
