#!/usr/bin/env node
import { spawn, execSync } from "child_process";
import fs from "fs";
import path from "path";
import http from "http";

// ================== KONFIG ==================
const PATHS = {
  dockerComposeDir: ".",                       // docker-compose.yml im Repo-Root
  backendDir: "./backend/indooro_server",      // Ordner mit pom.xml
  ndjsonFile: "./demoproducts.ndjson",         // NDJSON im Repo-Root
  programB: "./scripts/programB.js"
};

const CONTAINERS = {
  opensearch: "indooro-opensearch-1",
  dashboards: "indooro-dashboards-1"
};

const OPENSEARCH = {
  host: "localhost",
  port: 9200,
  index: "my-index"
};

const DASHBOARDS = {
  host: "localhost",
  port: 5601,
  dataView: "my-index*"
};
// ============================================

const isWindows = process.platform === "win32";
const BACKEND_CMD = isWindows ? "mvn.cmd" : "mvn";
const BACKEND_ARGS = ["quarkus:dev"];
const PID_FILE = ".backend.pid";

// ---------- Helpers ----------
const abs = p => path.resolve(process.cwd(), p);

function run(cmd, cwd = process.cwd()) {
  console.log(">", cmd);
  execSync(cmd, { stdio: "inherit", cwd });
}

function sleep(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

// ---------- Docker ----------
function containerExists(name) {
  try {
    execSync(`docker inspect ${name}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function isPaused(name) {
  return execSync(
    `docker inspect -f "{{.State.Paused}}" ${name}`
  ).toString().trim() === "true";
}

// ---------- OpenSearch ----------
function httpRequest(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: OPENSEARCH.host,
        port: OPENSEARCH.port,
        path,
        method,
        headers
      },
      res => {
        let data = "";
        res.on("data", chunk => (data += chunk));
        res.on("end", () => resolve({ status: res.statusCode, data }));
      }
    );
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

async function waitForOpenSearch() {
  console.log("⏳ Warte auf OpenSearch...");
  while (true) {
    try {
      await httpRequest(
        "GET",
        "/_cluster/health?wait_for_status=yellow"
      );
      console.log("✅ OpenSearch ist bereit");
      break;
    } catch {
      sleep(2000);
    }
  }
}

async function importNDJSON() {
  console.log("🧹 Lösche Index (falls vorhanden)...");
  await httpRequest("DELETE", `/${OPENSEARCH.index}`);

  console.log("📥 Importiere NDJSON...");
  const data = fs.readFileSync(abs(PATHS.ndjsonFile));

  await httpRequest(
    "POST",
    "/_bulk",
    data,
    { "Content-Type": "application/x-ndjson" }
  );
}

// ---------- OpenSearch Dashboards ----------
function dashboardsRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: DASHBOARDS.host,
        port: DASHBOARDS.port,
        path,
        method,
        headers: {
          "Content-Type": "application/json",
          "kbn-xsrf": "true"
        }
      },
      res => {
        let data = "";
        res.on("data", d => (data += d));
        res.on("end", () => resolve({ status: res.statusCode, data }));
      }
    );
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function ensureDataView() {
  console.log("🔍 Prüfe Dashboards Data View...");

  const check = await dashboardsRequest(
    "GET",
    "/api/saved_objects/_find?type=index-pattern"
  );

  if (check.data.includes(DASHBOARDS.dataView)) {
    console.log("✅ Data View existiert bereits");
    return;
  }

  console.log("➕ Erstelle Data View...");
  await dashboardsRequest(
    "POST",
    "/api/saved_objects/index-pattern",
    {
      attributes: {
        title: DASHBOARDS.dataView,
        timeFieldName: null
      }
    }
  );

  console.log("✅ Data View angelegt");
}

// ---------- Backend (Quarkus) ----------
function startBackend() {
  console.log("🚀 Starte Quarkus Backend (quarkus:dev)...");

  const proc = spawn(
    `${BACKEND_CMD} ${BACKEND_ARGS.join(" ")}`,
    {
      cwd: abs(PATHS.backendDir),
      stdio: "inherit",
      shell: true,
      env: process.env
    }
  );

  if (!proc.pid) {
    throw new Error("Backend konnte nicht gestartet werden");
  }

  fs.writeFileSync(PID_FILE, proc.pid.toString());
}

function stopBackend() {
  if (!fs.existsSync(PID_FILE)) return;

  const pid = fs.readFileSync(PID_FILE, "utf8");
  console.log("🛑 Stoppe Quarkus Backend...");
  process.kill(pid, "SIGTERM");
  fs.unlinkSync(PID_FILE);
}

// ---------- MODI ----------
async function startA() {
  console.log("▶️ START A");

  if (!containerExists(CONTAINERS.opensearch)) {
    run("docker compose up -d", abs(PATHS.dockerComposeDir));
  } else {
    if (isPaused(CONTAINERS.opensearch)) {
      run(`docker unpause ${CONTAINERS.opensearch} ${CONTAINERS.dashboards}`);
    } else {
      run(`docker start ${CONTAINERS.opensearch} ${CONTAINERS.dashboards}`);
    }
  }

  await waitForOpenSearch();
  await importNDJSON();
  await ensureDataView();
  startBackend();
}

async function startB() {
  console.log("▶️ START B");

  stopBackend();
  run(`docker pause ${CONTAINERS.opensearch} ${CONTAINERS.dashboards}`);
  run(`node ${abs(PATHS.programB)}`);
}

// ---------- CLI ----------
const mode = process.argv[2];

if (mode === "start-a") await startA();
else if (mode === "start-b") await startB();
else {
  console.log(`
Usage:
  node scripts/orchestrator.js start-a
  node scripts/orchestrator.js start-b
`);
}