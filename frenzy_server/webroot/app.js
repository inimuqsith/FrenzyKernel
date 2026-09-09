// ==============================================================================
// FrenzyServer WebUI Controller
// Native KernelSU WebView JavaScript Bridge
// ==============================================================================

let callbackCounter = 0;
function getUniqueCallbackName(prefix) {
  return `${prefix}_callback_${Date.now()}_${callbackCounter++}`;
}

// KernelSU root execution wrapper
function exec(command, options = {}) {
  return new Promise((resolve, reject) => {
    const callbackFuncName = getUniqueCallbackName("exec");
    window[callbackFuncName] = (errno, stdout, stderr) => {
      resolve({ errno, stdout, stderr });
      delete window[callbackFuncName];
    };
    try {
      if (typeof ksu !== "undefined" && ksu.exec) {
        ksu.exec(command, JSON.stringify(options), callbackFuncName);
      } else {
        // Fallback for local browser testing
        console.warn("KSU bridge not available (desktop testing mode)");
        resolve({
          errno: 0,
          stdout: JSON.stringify({
            ram: { total_mb: 7700, used_mb: 2240, free_mb: 4920, avail_mb: 5460, cached_mb: 960 },
            battery: { temp: 31 },
            touch: { blocked: true, pid: "10516" },
            camera: { stopped: true },
            fingerprint: { killed: true },
            debloat: { active: true, disabled_count: 29, total_targets: 29 },
            droidspaces: { running: true, nginx: true, pm2: true }
          }),
          stderr: ""
        });
      }
    } catch (e) {
      delete window[callbackFuncName];
      reject(e);
    }
  });
}

function toast(msg) {
  if (typeof ksu !== "undefined" && ksu.toast) {
    ksu.toast(msg);
  } else {
    console.log("Toast:", msg);
  }
}

// UI Elements
const elRamAvail = document.getElementById("ram-avail");
const elRamUsed = document.getElementById("ram-used");
const elRamFree = document.getElementById("ram-free");
const elRamTotal = document.getElementById("ram-total");
const elRamBar = document.getElementById("ram-bar");
const elBattTemp = document.getElementById("batt-temp");
const elTempDot = document.getElementById("temp-dot");
const elTempDesc = document.getElementById("temp-desc");
const elToggleDebloat = document.getElementById("toggle-debloat");
const elDebloatDesc = document.getElementById("debloat-desc");
const elToggleTouch = document.getElementById("toggle-touch");
const elTouchDesc = document.getElementById("touch-desc");
const elFpStatus = document.getElementById("fp-status");
const elCamStatus = document.getElementById("cam-status");
const elDsStatus = document.getElementById("ds-status");
const elConsole = document.getElementById("console-output");
const elBtnRefresh = document.getElementById("btn-refresh");
const elBtnTrim = document.getElementById("btn-trim");
const elBtnCleanTb = document.getElementById("btn-clean-tb");
const elBtnClearLog = document.getElementById("btn-clear-log");

function appendLog(msg) {
  const time = new Date().toLocaleTimeString();
  elConsole.textContent += `\n[${time}] ${msg}`;
  elConsole.scrollTop = elConsole.scrollHeight;
}

// Fetch & render system metrics
async function refreshMetrics() {
  try {
    const res = await exec("frenzy-server json");
    if (res.errno !== 0 && !res.stdout) {
      appendLog(`Error reading metrics: ${res.stderr}`);
      return;
    }

    const data = JSON.parse(res.stdout);

    // RAM
    if (data.ram) {
      const avail = data.ram.avail_mb || 0;
      const total = data.ram.total_mb || 7700;
      const used = data.ram.used_mb || 0;
      const free = data.ram.free_mb || 0;
      
      elRamAvail.textContent = `${avail} MB`;
      elRamUsed.textContent = `${used} MB`;
      elRamFree.textContent = `${free} MB`;
      elRamTotal.textContent = `${(total / 1024).toFixed(1)} GB`;

      const pct = Math.min(100, Math.round((avail / total) * 100));
      elRamBar.style.width = `${pct}%`;
    }

    // Battery & Thermal
    if (data.battery) {
      const temp = data.battery.temp || 0;
      elBattTemp.textContent = `${temp}°C`;
      if (temp >= 47) {
        elTempDot.className = "dot dot-danger";
        elTempDesc.textContent = "Overheat! Thermal guard throttled CPU";
      } else if (temp >= 42) {
        elTempDot.className = "dot dot-warning";
        elTempDesc.textContent = "Warm • Monitoring battery temperature";
      } else {
        elTempDot.className = "dot dot-success";
        elTempDesc.textContent = "Safe • Below 47°C throttle limit";
      }
    }

    // Debloat status
    if (data.debloat) {
      elToggleDebloat.checked = data.debloat.active;
      if (data.debloat.active) {
        elDebloatDesc.textContent = `Active • ${data.debloat.disabled_count}/${data.debloat.total_targets} bloat apps frozen`;
      } else {
        elDebloatDesc.textContent = "Disabled • Normal consumer phone mode";
      }
    }

    // Touch Blocker status
    if (data.touch) {
      elToggleTouch.checked = data.touch.blocked;
      if (data.touch.blocked) {
        elTouchDesc.textContent = `Shield Active • Touch blocked (PID: ${data.touch.pid})`;
      } else {
        elTouchDesc.textContent = "Normal touch active • Shield OFF";
      }
    }

    // Hardware Shields
    if (data.fingerprint) {
      elFpStatus.textContent = data.fingerprint.killed ? "KILLED & SHIELDED" : "ACTIVE";
      elFpStatus.className = data.fingerprint.killed ? "badge badge-success" : "badge badge-danger";
    }

    if (data.camera) {
      elCamStatus.textContent = data.camera.stopped ? "HALTED" : "RUNNING";
      elCamStatus.className = data.camera.stopped ? "badge badge-success" : "badge badge-primary";
    }

    if (data.droidspaces) {
      elDsStatus.textContent = data.droidspaces.running ? "RUNNING (LXC)" : "STOPPED";
      elDsStatus.className = data.droidspaces.running ? "badge badge-success" : "badge badge-danger";
    }

  } catch (err) {
    appendLog(`Metrics refresh failed: ${err.message}`);
  }
}

// Event Listeners
elBtnRefresh.addEventListener("click", async () => {
  elBtnRefresh.style.transform = "rotate(360deg)";
  appendLog("Refreshing system metrics...");
  await refreshMetrics();
  setTimeout(() => { elBtnRefresh.style.transform = "none"; }, 500);
});

elBtnTrim.addEventListener("click", async () => {
  appendLog("Executing RAM Quick Trim & cache compact...");
  toast("Compacting RAM & caches...");
  const res = await exec("frenzy-server trim");
  appendLog(res.stdout || "Trim executed.");
  await refreshMetrics();
  toast("RAM trimmed successfully!");
});

elToggleDebloat.addEventListener("change", async (e) => {
  const enable = e.target.checked;
  if (enable) {
    appendLog("Activating Tier 1 Headless Debloat...");
    toast("Enabling Tier 1 Debloat...");
    const res = await exec("frenzy-server enable");
    appendLog(res.stdout);
    toast("Tier 1 Debloat Enabled!");
  } else {
    appendLog("Restoring normal consumer mode...");
    toast("Restoring normal mode...");
    const res = await exec("frenzy-server disable");
    appendLog(res.stdout);
    toast("Restored to Normal Mode!");
  }
  await refreshMetrics();
});

elToggleTouch.addEventListener("change", async (e) => {
  const block = e.target.checked;
  if (block) {
    appendLog("Blocking touchscreen inputs (anti-ghost touch)...");
    toast("Blocking touchscreen...");
    const res = await exec("frenzy-server touch block");
    appendLog(res.stdout);
    toast("Touchscreen Blocked!");
  } else {
    appendLog("Unblocking touchscreen inputs...");
    toast("Unblocking touchscreen...");
    const res = await exec("frenzy-server touch unblock");
    appendLog(res.stdout);
    toast("Touchscreen Unblocked!");
  }
  await refreshMetrics();
});

elBtnCleanTb.addEventListener("click", async () => {
  appendLog("Cleaning fingerprint crash tombstones...");
  const res = await exec("rm -f /data/tombstones/*fingerprint* 2>/dev/null; echo 'Tombstones flushed.'");
  appendLog(res.stdout);
  toast("Crash tombstones cleaned!");
  await refreshMetrics();
});

elBtnClearLog.addEventListener("click", () => {
  elConsole.textContent = "> Console cleared.";
});

// Initial load & background poll
window.addEventListener("DOMContentLoaded", () => {
  appendLog("FrenzyServer WebUI connected.");
  refreshMetrics();
  setInterval(refreshMetrics, 4000);
});
