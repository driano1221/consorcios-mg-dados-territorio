const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const ROOT = path.resolve(String(process.env.CNM_WORKDIR || PROJECT_ROOT));
const RAW_DIR = path.join(ROOT, "raw");
const DATA_DIR = path.join(ROOT, "data");
const BASE_URL = "https://consorcios.cnm.org.br";
const API_BASE = `${BASE_URL}/api`;

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, value] = arg.split("=");
    return [key.replace(/^--/, ""), value ?? true];
  }),
);

const SAMPLE = args.has("sample") ? Number(args.get("sample") || 10) : null;
const HEADLESS = args.get("headless") === "true";
const SLOW_MS = Number(args.get("slow") || 1000);
const RATE_LIMIT_WAIT_MS = Number(args.get("rate-limit-wait") || 90000);
const PROFILE_DIR = path.resolve(String(args.get("profile") || path.join(PROJECT_ROOT, ".playwright-profile")));

const browserCandidates = [
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
];

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function ensureDirs() {
  await fs.mkdir(RAW_DIR, { recursive: true });
  await fs.mkdir(DATA_DIR, { recursive: true });
}

function toQuery(params = {}) {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== null && value !== undefined && value !== "") {
      query.set(key, String(value));
    }
  }
  return query.toString();
}

async function writeJson(filePath, value) {
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function csvEscape(value) {
  if (value === null || value === undefined) return "";
  const text = String(value);
  return /[",\n\r;]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

async function writeCsv(filePath, rows, columns) {
  const lines = [columns.join(";")];
  for (const row of rows) {
    lines.push(columns.map((column) => csvEscape(row[column])).join(";"));
  }
  await fs.writeFile(filePath, `\ufeff${lines.join("\n")}\n`, "utf8");
}

function normalizeMunicipio(municipio) {
  if (!municipio) return null;
  return {
    id: municipio.id ?? null,
    ibge: municipio.ibge ?? municipio.codigo_ibge ?? null,
    nome: municipio.nome ?? municipio.name ?? null,
    uf: municipio.uf ?? municipio.sigla_uf ?? null,
    label: municipio.label ?? [municipio.nome, municipio.uf].filter(Boolean).join("/"),
  };
}

function flattenConsorcio(record) {
  const c = record.consorcio || record;
  const sede = normalizeMunicipio(c.municipio_consorciado || c.municipio_sede || c.sede);
  const respostas = Array.isArray(c.respostas) ? c.respostas : [];
  const areas = Array.isArray(c.areas) ? c.areas : [];

  const natureza = respostas.find((r) => [4, 5, 6].includes(Number(r.alternativa_id)));
  const regido = respostas.find((r) => [1, 2].includes(Number(r.alternativa_id)));
  const tipoSede = respostas.find((r) => [80, 81, 82].includes(Number(r.alternativa_id)));

  return {
    uuid: c.uuid ?? record.uuid ?? null,
    id: c.id ?? null,
    nome: c.nome ?? null,
    sigla: c.sigla ?? null,
    cnpj: c.cnpj ?? null,
    site: c.site ?? null,
    status: c.status ?? null,
    situacao_cnpj: c.situacao_cnpj ?? null,
    data_constituicao: c.data_constituicao ?? c.data_criacao ?? null,
    area_atuacao: c.area_atuacao ?? null,
    areas_atuacao: [...new Set(areas.map((area) => area.nome).filter(Boolean))].join(" | "),
    areas_atuacao_ids: [...new Set(areas.map((area) => area.id).filter((id) => id !== undefined && id !== null))].join("|"),
    municipio_sede_id: sede?.id ?? null,
    municipio_sede_ibge: sede?.ibge ?? null,
    municipio_sede_nome: sede?.nome ?? null,
    municipio_sede_uf: sede?.uf ?? null,
    natureza_juridica_inferida:
      Number(natureza?.alternativa_id) === 4
        ? "Publico"
        : Number(natureza?.alternativa_id) === 5
          ? "Privado"
          : Number(natureza?.alternativa_id) === 6
            ? "Administrativo"
            : null,
    regido_lei_11107_2005_inferido:
      Number(regido?.alternativa_id) === 1
        ? "Sim"
        : Number(regido?.alternativa_id) === 2
          ? "Nao"
          : null,
    tipo_sede_inferido:
      Number(tipoSede?.alternativa_id) === 80
        ? "Propria"
        : Number(tipoSede?.alternativa_id) === 81
          ? "Alugada"
          : Number(tipoSede?.alternativa_id) === 82
            ? "Cedida"
            : null,
    quantidade_municipios: Array.isArray(c.municipios) ? c.municipios.length : 0,
    quantidade_areas: new Set(areas.map((area) => area.id ?? area.nome)).size,
    populacao_atendida: c.populacao_atendida ?? null,
    abrangencia_territorial: c.abrangencia_territorial ?? null,
  };
}

async function launchContext() {
  const executablePath = (await Promise.all(browserCandidates.map(async (p) => ((await exists(p)) ? p : null)))).find(Boolean);
  const context = await chromium.launchPersistentContext(PROFILE_DIR, {
    headless: HEADLESS,
    executablePath,
    viewport: { width: 1440, height: 900 },
    slowMo: HEADLESS ? 0 : 20,
    args: ["--disable-blink-features=AutomationControlled"],
  });
  return context;
}

async function waitForApp(page) {
  await page.goto(`${BASE_URL}/#`, { waitUntil: "domcontentloaded", timeout: 120000 });
  let lastError = null;
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const probe = await fetchJson(page, "v1/mapas/estados", {}, { retries: 0 });
      if (probe) return;
    } catch (error) {
      lastError = error;
    }
    await page.waitForTimeout(2000);
  }

  await page.screenshot({ path: path.join(RAW_DIR, "falha_sessao.png"), fullPage: true });
  await fs.writeFile(
    path.join(RAW_DIR, "falha_sessao.html"),
    await page.content(),
    "utf8",
  );
  throw new Error(`A API publica da CNM nao ficou disponivel: ${lastError?.message || "sem resposta"}`);
}

async function fetchJson(page, endpoint, params = {}, options = {}) {
  const query = toQuery(params);
  const url = `${API_BASE}/${endpoint.replace(/^\/+/, "")}${query ? `?${query}` : ""}`;
  const retries = options.retries ?? 5;

  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      return await page.evaluate(async (targetUrl) => {
        const response = await fetch(targetUrl, {
          credentials: "include",
          headers: {
            Accept: "application/json, text/plain, */*",
            "X-Requested-With": "XMLHttpRequest",
          },
        });
        const text = await response.text();
        if (!response.ok) {
          const error = new Error(`HTTP ${response.status} for ${targetUrl}: ${text.slice(0, 300)}`);
          error.status = response.status;
          throw error;
        }
        try {
          return JSON.parse(text);
        } catch (error) {
          throw new Error(`Invalid JSON for ${targetUrl}: ${text.slice(0, 300)}`);
        }
      }, url);
    } catch (error) {
      const isRateLimit = String(error.message || "").includes("HTTP 429");
      if (!isRateLimit || attempt === retries) throw error;
      console.log(`\nRate limit recebido. Aguardando ${Math.round(RATE_LIMIT_WAIT_MS / 1000)}s antes de tentar de novo...`);
      await page.waitForTimeout(RATE_LIMIT_WAIT_MS);
    }
  }
}

function uniqueConsorciosFromModalItems(items) {
  const seen = new Map();
  for (const item of items) {
    if (!item || !item.uuid) continue;
    if (!seen.has(item.uuid)) seen.set(item.uuid, item);
  }
  return [...seen.values()];
}

async function main() {
  await ensureDirs();
  const context = await launchContext();
  const page = await context.newPage();

  try {
    console.log("Abrindo site e preparando sessão...");
    await waitForApp(page);

    console.log("Baixando dados agregados do mapa...");
    const [mapaSedes, mapaConsorciados, estados, areas, anosCriacao] = await Promise.all([
      fetchJson(page, "v1/mapas", { tipo: "municipiosSede" }),
      fetchJson(page, "v1/mapas", { tipo: "municipiosConsorciados" }),
      fetchJson(page, "v1/mapas/estados"),
      fetchJson(page, "v1/mapas/areas"),
      fetchJson(page, "v1/mapas/anosCriacao"),
    ]);

    await writeJson(path.join(RAW_DIR, "mapas_municipiosSede.json"), mapaSedes);
    await writeJson(path.join(RAW_DIR, "mapas_municipiosConsorciados.json"), mapaConsorciados);
    await writeJson(path.join(RAW_DIR, "estados.json"), estados);
    await writeJson(path.join(RAW_DIR, "areas.json"), areas);
    await writeJson(path.join(RAW_DIR, "anos_criacao.json"), anosCriacao);

    const sedeMunicipios = mapaSedes?.dados?.dadosMapa || [];
    const consorciosSemSede = mapaSedes?.dados?.["nao-informados"] || [];
    console.log(`Municípios-sede no mapa: ${sedeMunicipios.length}`);

    const modalDir = path.join(RAW_DIR, "consorcios_por_sede");
    await fs.mkdir(modalDir, { recursive: true });
    const modalConsorcios = [];
    for (let index = 0; index < sedeMunicipios.length; index += 1) {
      const municipio = sedeMunicipios[index];
      process.stdout.write(`\rConsultando consórcios por sede ${index + 1}/${sedeMunicipios.length}`);
      const modalFile = path.join(modalDir, `${municipio.id}.json`);
      let items;
      if (await exists(modalFile)) {
        items = JSON.parse(await fs.readFile(modalFile, "utf8"));
      } else {
        items = await fetchJson(page, "v1/mapas/consorcios-municipio-sede", { municipio: municipio.id });
        await writeJson(modalFile, items);
      }
      for (const item of items || []) modalConsorcios.push(item);
      if (SAMPLE && uniqueConsorciosFromModalItems([...modalConsorcios, ...consorciosSemSede]).length >= SAMPLE) break;
      if (SLOW_MS) await page.waitForTimeout(SLOW_MS);
    }
    process.stdout.write("\n");

    const discovered = uniqueConsorciosFromModalItems([...modalConsorcios, ...consorciosSemSede]);
    const selected = SAMPLE ? discovered.slice(0, SAMPLE) : discovered;
    await writeJson(path.join(RAW_DIR, "consorcios_descobertos.json"), discovered);
    console.log(`Consórcios descobertos: ${discovered.length}. Coletando fichas: ${selected.length}`);

    const detailDir = path.join(RAW_DIR, "consorcios");
    await fs.mkdir(detailDir, { recursive: true });
    const details = [];

    for (let index = 0; index < selected.length; index += 1) {
      const item = selected[index];
      const file = path.join(detailDir, `${item.uuid}.json`);
      process.stdout.write(`\rFicha técnica ${index + 1}/${selected.length}: ${item.sigla || item.uuid}`);

      let detail;
      if (await exists(file)) {
        detail = JSON.parse(await fs.readFile(file, "utf8"));
      } else {
        detail = await fetchJson(page, `v1/consorcios-dados-publico/${item.uuid}`);
        await writeJson(file, detail);
        if (SLOW_MS) await page.waitForTimeout(SLOW_MS);
      }
      details.push({ uuid: item.uuid, resumo_mapa: item, ...detail });
    }
    process.stdout.write("\n");

    const municipiosByKey = new Map();
    const relations = [];
    const consorciosFlat = [];

    for (const detail of details) {
      const consorcio = detail.consorcio || {};
      consorciosFlat.push(flattenConsorcio(detail));

      for (const municipio of consorcio.municipios || []) {
        const normalized = normalizeMunicipio(municipio);
        if (!normalized) continue;
        const key = normalized.ibge || normalized.id || normalized.label;
        if (!municipiosByKey.has(key)) municipiosByKey.set(key, normalized);
        relations.push({
          consorcio_uuid: consorcio.uuid ?? detail.uuid,
          consorcio_id: consorcio.id ?? null,
          consorcio_nome: consorcio.nome ?? null,
          consorcio_sigla: consorcio.sigla ?? null,
          municipio_id: normalized.id,
          municipio_ibge: normalized.ibge,
          municipio_nome: normalized.nome,
          municipio_uf: normalized.uf,
        });
      }
    }

    const municipios = [...municipiosByKey.values()].sort((a, b) => String(a.label).localeCompare(String(b.label), "pt-BR"));

    await writeJson(path.join(DATA_DIR, "consorcios_completos.json"), details);
    await writeJson(path.join(DATA_DIR, "consorcios_flat.json"), consorciosFlat);
    await writeJson(path.join(DATA_DIR, "municipios.json"), municipios);
    await writeJson(path.join(DATA_DIR, "municipio_consorcio.json"), relations);

    await writeCsv(path.join(DATA_DIR, "consorcios.csv"), consorciosFlat, Object.keys(consorciosFlat[0] || {}));
    await writeCsv(path.join(DATA_DIR, "municipios.csv"), municipios, ["id", "ibge", "nome", "uf", "label"]);
    await writeCsv(path.join(DATA_DIR, "municipio_consorcio.csv"), relations, [
      "consorcio_uuid",
      "consorcio_id",
      "consorcio_nome",
      "consorcio_sigla",
      "municipio_id",
      "municipio_ibge",
      "municipio_nome",
      "municipio_uf",
    ]);

    console.log("Resumo:");
    console.log(`- Consórcios exportados: ${consorciosFlat.length}`);
    console.log(`- Municípios únicos exportados: ${municipios.length}`);
    console.log(`- Vínculos município-consórcio: ${relations.length}`);
  } finally {
    await context.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
